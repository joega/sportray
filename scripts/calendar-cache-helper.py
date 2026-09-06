#!/usr/bin/python3
"""Descriptor-bound persistence for Sportray's calendar cache.

The QML service provides only one of the fixed cache file names.  This helper
walks the cache directory from HOME through held descriptors and performs every
read, publication, and cleanup relative to that held directory descriptor.
"""

import argparse
import os
import secrets
import stat
import sys


MAX_BYTES = 8 * 1024 * 1024
CACHE_PARTS = (".cache", "sportray", "calendar")
MANIFEST_NAME = "manifest.json"


class RejectedCache(Exception):
    pass


def reject(message):
    raise RejectedCache(message)


def check_directory(fd):
    info = os.fstat(fd)
    if not stat.S_ISDIR(info.st_mode):
        reject("parent is not a directory")
    if info.st_uid != os.getuid():
        reject("parent has wrong owner")
    if info.st_mode & 0o022:
        reject("parent is writable by another user")


def open_cache_directory():
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
        for part in CACHE_PARTS:
            try:
                child = os.open(part, flags, dir_fd=current)
            except FileNotFoundError:
                try:
                    os.mkdir(part, 0o700, dir_fd=current)
                    child = os.open(part, flags, dir_fd=current)
                except OSError as error:
                    reject("cannot create cache directory: " + error.strerror)
            except OSError as error:
                reject("cannot open cache directory: " + error.strerror)
            os.close(current)
            current = child
            check_directory(current)
        return current
    except BaseException:
        os.close(current)
        raise


def valid_name(value):
    if value == MANIFEST_NAME:
        return True
    if not value.endswith(".json"):
        return False
    stem = value[:-5]
    if stem.count(":") != 1:
        return False
    league, date_key = stem.split(":")
    return (1 <= len(league) <= 32 and all(character in "abcdefghijklmnopqrstuvwxyz0123456789."
            for character in league)
        and len(date_key) == 10 and date_key[4] == "-" and date_key[7] == "-"
        and date_key.replace("-", "").isdigit())


def check_file(fd):
    info = os.fstat(fd)
    if not stat.S_ISREG(info.st_mode):
        reject("cache is not a regular file")
    if info.st_uid != os.getuid():
        reject("cache has wrong owner")
    if info.st_nlink != 1:
        reject("cache has unexpected link count")
    if info.st_size > MAX_BYTES:
        reject("cache exceeds byte cap")


def read_bounded(fd):
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
        reject("cache exceeds byte cap")
    return data


def read_cache(name):
    directory = open_cache_directory()
    try:
        flags = os.O_RDONLY | os.O_NONBLOCK | os.O_NOFOLLOW | os.O_CLOEXEC
        try:
            fd = os.open(name, flags, dir_fd=directory)
        except FileNotFoundError:
            return 2
        except OSError as error:
            reject("cannot open cache: " + error.strerror)
        try:
            check_file(fd)
            os.set_blocking(fd, True)
            sys.stdout.buffer.write(read_bounded(fd))
            return 0
        finally:
            os.close(fd)
    finally:
        os.close(directory)


def read_record():
    chunks = []
    size = 0
    while True:
        chunk = os.read(sys.stdin.fileno(), min(8192, MAX_BYTES + 1 - size))
        if not chunk:
            reject("write record is incomplete")
        marker = chunk.find(b"\0")
        if marker >= 0:
            chunks.append(chunk[:marker])
            size += marker
            if size > MAX_BYTES or chunk[marker + 1:]:
                reject("write exceeds byte cap")
            return b"".join(chunks)
        chunks.append(chunk)
        size += len(chunk)
        if size > MAX_BYTES:
            reject("write exceeds byte cap")


def write_all(fd, data):
    offset = 0
    while offset < len(data):
        written = os.write(fd, data[offset:])
        if written <= 0:
            raise OSError("short write")
        offset += written


def existing_target_is_safe(directory, name):
    flags = os.O_RDONLY | os.O_NONBLOCK | os.O_NOFOLLOW | os.O_CLOEXEC
    try:
        fd = os.open(name, flags, dir_fd=directory)
    except FileNotFoundError:
        return
    except OSError as error:
        reject("cannot validate existing cache: " + error.strerror)
    try:
        check_file(fd)
    finally:
        os.close(fd)


def allocate_temporary(directory, name):
    for _ in range(32):
        temporary = ".%s.%s.tmp" % (name, secrets.token_hex(16))
        try:
            fd = os.open(temporary, os.O_WRONLY | os.O_CREAT | os.O_EXCL |
                os.O_NOFOLLOW | os.O_CLOEXEC, 0o600, dir_fd=directory)
            return temporary, fd
        except FileExistsError:
            continue
        except OSError as error:
            reject("cannot create temporary cache: " + error.strerror)
    reject("cannot allocate temporary cache")


def write_cache(name):
    data = read_record()
    directory = open_cache_directory()
    temporary = None
    try:
        existing_target_is_safe(directory, name)
        temporary, fd = allocate_temporary(directory, name)
        try:
            check_file(fd)
            os.fchmod(fd, 0o600)
            write_all(fd, data)
            os.fsync(fd)
        finally:
            os.close(fd)
        os.replace(temporary, name, src_dir_fd=directory, dst_dir_fd=directory)
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


def remove_cache(name):
    directory = open_cache_directory()
    temporary = None
    try:
        flags = os.O_RDONLY | os.O_NONBLOCK | os.O_NOFOLLOW | os.O_CLOEXEC
        try:
            fd = os.open(name, flags, dir_fd=directory)
        except FileNotFoundError:
            return 2
        except OSError as error:
            reject("cannot open cache for removal: " + error.strerror)
        try:
            check_file(fd)
            original = os.fstat(fd)
        finally:
            os.close(fd)
        temporary, unused_fd = allocate_temporary(directory, name)
        os.close(unused_fd)
        os.unlink(temporary, dir_fd=directory)
        os.rename(name, temporary, src_dir_fd=directory, dst_dir_fd=directory)
        fd = os.open(temporary, flags, dir_fd=directory)
        try:
            check_file(fd)
            moved = os.fstat(fd)
            if (moved.st_dev, moved.st_ino) != (original.st_dev, original.st_ino):
                reject("cache changed during removal")
        finally:
            os.close(fd)
        os.unlink(temporary, dir_fd=directory)
        temporary = None
        os.fsync(directory)
        return 0
    finally:
        # A raced entry is intentionally left quarantined rather than risking
        # deletion of a replacement we did not validate.
        os.close(directory)


def main():
    parser = argparse.ArgumentParser(add_help=False)
    parser.add_argument("operation", choices=("read", "write", "remove"))
    parser.add_argument("name")
    args = parser.parse_args()
    if not valid_name(args.name):
        reject("invalid cache name")
    if args.operation == "read":
        return read_cache(args.name)
    if args.operation == "write":
        return write_cache(args.name)
    return remove_cache(args.name)


if __name__ == "__main__":
    try:
        sys.exit(main())
    except RejectedCache as error:
        print("sportray calendar cache rejected: " + str(error), file=sys.stderr)
        sys.exit(4)
    except OSError as error:
        print("sportray calendar cache failed: " + str(error), file=sys.stderr)
        sys.exit(5)
