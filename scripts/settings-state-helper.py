#!/usr/bin/python3
"""Descriptor-bound persistence for Sportray's one settings file.

The QML process only asks this fixed helper to read or publish the fixed state
path below HOME.  Every pathname component is opened with a held directory
descriptor, so validation and use name the same objects.
"""

import argparse
import errno
import os
import secrets
import stat
import sys


MAX_BYTES = 64 * 1024
STATE_PARTS = (".local", "state", "omarchy", "settings")
STATE_NAME = "sportray.json"


class RejectedState(Exception):
    pass


def reject(message):
    raise RejectedState(message)


def check_directory(fd):
    info = os.fstat(fd)
    if not stat.S_ISDIR(info.st_mode):
        reject("parent is not a directory")
    if info.st_uid != os.getuid():
        reject("parent has wrong owner")
    if info.st_mode & 0o022:
        reject("parent is writable by another user")


def open_state_directory():
    home = os.environ.get("HOME")
    if not home or not os.path.isabs(home):
        reject("HOME is not an absolute path")
    flags = os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW | os.O_CLOEXEC
    try:
        current = os.open(home, flags)
    except OSError as error:
        reject("cannot open HOME: " + error.strerror)
    try:
        check_directory(current)
        for part in STATE_PARTS:
            try:
                child = os.open(part, flags, dir_fd=current)
            except FileNotFoundError:
                try:
                    os.mkdir(part, 0o700, dir_fd=current)
                    child = os.open(part, flags, dir_fd=current)
                except OSError as error:
                    reject("cannot create state directory: " + error.strerror)
            except OSError as error:
                reject("cannot open state directory: " + error.strerror)
            os.close(current)
            current = child
            check_directory(current)
        return current
    except BaseException:
        os.close(current)
        raise


def check_file(fd):
    info = os.fstat(fd)
    if not stat.S_ISREG(info.st_mode):
        reject("state is not a regular file")
    if info.st_uid != os.getuid():
        reject("state has wrong owner")
    if info.st_nlink != 1:
        reject("state has unexpected link count")
    if info.st_size > MAX_BYTES:
        reject("state exceeds byte cap")


def read_state():
    directory = open_state_directory()
    try:
        flags = os.O_RDONLY | os.O_NONBLOCK | os.O_NOFOLLOW | os.O_CLOEXEC
        try:
            fd = os.open(STATE_NAME, flags, dir_fd=directory)
        except FileNotFoundError:
            return 2
        except OSError as error:
            reject("cannot open state: " + error.strerror)
        try:
            check_file(fd)
            chunks = []
            remaining = MAX_BYTES + 1
            while remaining:
                chunk = os.read(fd, min(8192, remaining))
                if not chunk:
                    break
                chunks.append(chunk)
                remaining -= len(chunk)
            data = b"".join(chunks)
            if len(data) > MAX_BYTES:
                reject("state exceeds byte cap")
            sys.stdout.buffer.write(data)
            return 0
        finally:
            os.close(fd)
    finally:
        os.close(directory)


def existing_target_is_safe(directory):
    flags = os.O_RDONLY | os.O_NONBLOCK | os.O_NOFOLLOW | os.O_CLOEXEC
    try:
        fd = os.open(STATE_NAME, flags, dir_fd=directory)
    except FileNotFoundError:
        return
    except OSError as error:
        reject("cannot validate existing state: " + error.strerror)
    try:
        check_file(fd)
    finally:
        os.close(fd)


def write_all(fd, data):
    offset = 0
    while offset < len(data):
        written = os.write(fd, data[offset:])
        if written <= 0:
            raise OSError("short write")
        offset += written


def write_state(raw):
    data = raw.encode("utf-8")
    if len(data) > MAX_BYTES:
        reject("write exceeds byte cap")
    directory = open_state_directory()
    temporary = None
    try:
        existing_target_is_safe(directory)
        for _ in range(32):
            temporary = ".sportray.%s.tmp" % secrets.token_hex(16)
            try:
                fd = os.open(temporary, os.O_WRONLY | os.O_CREAT | os.O_EXCL |
                    os.O_NOFOLLOW | os.O_CLOEXEC, 0o600, dir_fd=directory)
                break
            except FileExistsError:
                continue
            except OSError as error:
                reject("cannot create temporary state: " + error.strerror)
        else:
            reject("cannot allocate temporary state")
        try:
            check_file(fd)
            os.fchmod(fd, 0o600)
            write_all(fd, data)
            os.fsync(fd)
        finally:
            os.close(fd)
        os.replace(temporary, STATE_NAME, src_dir_fd=directory, dst_dir_fd=directory)
        temporary = None
        os.fsync(directory)
        return 0
    finally:
        if temporary:
            try:
                os.unlink(temporary, dir_fd=directory)
            except OSError:
                pass
        os.close(directory)


def main():
    parser = argparse.ArgumentParser(add_help=False)
    parser.add_argument("operation", choices=("read", "write"))
    parser.add_argument("--data")
    args = parser.parse_args()
    if args.operation == "read":
        if args.data is not None:
            reject("read does not accept data")
        return read_state()
    if args.data is None:
        reject("write requires data")
    return write_state(args.data)


if __name__ == "__main__":
    try:
        sys.exit(main())
    except RejectedState as error:
        print("sportray settings state rejected: " + str(error), file=sys.stderr)
        sys.exit(4)
    except OSError as error:
        print("sportray settings state failed: " + str(error), file=sys.stderr)
        sys.exit(5)
