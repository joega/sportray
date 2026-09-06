#!/usr/bin/python3
"""Fetch one approved team logo and emit a validated local data URL."""

import base64
import http.client
import socket
import sys
import time
from urllib.parse import urlsplit


MAX_BYTES = 256 * 1024
MAX_WIDTH = 1024
MAX_HEIGHT = 1024
MAX_PIXELS = MAX_WIDTH * MAX_HEIGHT
DEADLINE_SECONDS = 10
ALLOWED_HOSTS = frozenset(("a.espncdn.com", "assets.nhle.com"))


class ImageError(Exception):
    pass


def validate_url(value):
    try:
        parsed = urlsplit(value)
        port = parsed.port
    except ValueError as error:
        raise ImageError("invalid URL") from error
    if (parsed.scheme.lower() != "https" or not parsed.hostname or parsed.username
            or parsed.password or parsed.hostname.lower() not in ALLOWED_HOSTS
            or port not in (None, 443)):
        raise ImageError("unapproved origin")
    return parsed


def remaining(deadline):
    value = deadline - time.monotonic()
    if value <= 0:
        raise ImageError("deadline exceeded")
    return value


def apply_read_deadline(response, deadline):
    raw = getattr(getattr(response, "fp", None), "raw", None)
    stream_socket = getattr(raw, "_sock", None)
    if stream_socket is not None:
        stream_socket.settimeout(remaining(deadline))


def png_dimensions(data):
    if len(data) < 24 or data[:8] != b"\x89PNG\r\n\x1a\n" or data[12:16] != b"IHDR":
        raise ImageError("malformed PNG")
    return int.from_bytes(data[16:20], "big"), int.from_bytes(data[20:24], "big"), "image/png"


def jpeg_dimensions(data):
    if len(data) < 4 or data[:2] != b"\xff\xd8":
        raise ImageError("malformed JPEG")
    offset = 2
    while offset < len(data):
        while offset < len(data) and data[offset] == 0xff:
            offset += 1
        if offset >= len(data):
            break
        marker = data[offset]
        offset += 1
        if marker in (0xd8, 0xd9) or 0xd0 <= marker <= 0xd7:
            continue
        if offset + 2 > len(data):
            break
        size = int.from_bytes(data[offset:offset + 2], "big")
        if size < 2 or offset + size > len(data):
            break
        if marker in (0xc0, 0xc1, 0xc2, 0xc3, 0xc5, 0xc6, 0xc7, 0xc9, 0xca, 0xcb, 0xcd, 0xce, 0xcf):
            if size < 8:
                break
            return (int.from_bytes(data[offset + 5:offset + 7], "big"),
                    int.from_bytes(data[offset + 3:offset + 5], "big"), "image/jpeg")
        offset += size
    raise ImageError("malformed JPEG")


def webp_dimensions(data):
    if len(data) < 30 or data[:4] != b"RIFF" or data[8:12] != b"WEBP":
        raise ImageError("malformed WebP")
    kind = data[12:16]
    if kind == b"VP8X" and len(data) >= 30:
        return (1 + int.from_bytes(data[24:27], "little"),
                1 + int.from_bytes(data[27:30], "little"), "image/webp")
    if kind == b"VP8 " and len(data) >= 30 and data[23:26] == b"\x9d\x01\x2a":
        return (int.from_bytes(data[26:28], "little") & 0x3fff,
                int.from_bytes(data[28:30], "little") & 0x3fff, "image/webp")
    if kind == b"VP8L" and len(data) >= 25 and data[20] == 0x2f:
        bits = int.from_bytes(data[21:25], "little")
        return ((bits & 0x3fff) + 1, ((bits >> 14) & 0x3fff) + 1, "image/webp")
    raise ImageError("malformed WebP")


def validate_image(data):
    if data.startswith(b"\x89PNG\r\n\x1a\n"):
        width, height, mime = png_dimensions(data)
    elif data.startswith(b"\xff\xd8"):
        width, height, mime = jpeg_dimensions(data)
    elif data.startswith(b"RIFF"):
        width, height, mime = webp_dimensions(data)
    else:
        raise ImageError("unapproved image format")
    if not width or not height or width > MAX_WIDTH or height > MAX_HEIGHT or width * height > MAX_PIXELS:
        raise ImageError("image dimensions rejected")
    return mime


def fetch(value, connection_factory=http.client.HTTPSConnection):
    parsed = validate_url(value)
    deadline = time.monotonic() + DEADLINE_SECONDS
    path = parsed.path or "/"
    if parsed.query:
        path += "?" + parsed.query
    connection = None
    try:
        connection = connection_factory(parsed.hostname, port=443, timeout=remaining(deadline))
        connection.request("GET", path, headers={"Accept": "image/png,image/jpeg,image/webp", "User-Agent": "Sportray/1"})
        response = connection.getresponse()
        if response.status < 200 or response.status >= 300:
            raise ImageError("HTTP status rejected")
        length = response.getheader("Content-Length")
        if length is not None and (not length.isdecimal() or int(length) > MAX_BYTES):
            raise ImageError("image exceeds byte cap")
        chunks, total = [], 0
        while True:
            apply_read_deadline(response, deadline)
            chunk = response.read(min(8192, MAX_BYTES + 1 - total))
            if not chunk:
                break
            total += len(chunk)
            if total > MAX_BYTES:
                raise ImageError("image exceeds byte cap")
            chunks.append(chunk)
        return b"".join(chunks)
    except (OSError, http.client.HTTPException, socket.timeout) as error:
        raise ImageError("image transport failed") from error
    finally:
        if connection is not None:
            connection.close()


def data_url(value, connection_factory=http.client.HTTPSConnection):
    data = fetch(value, connection_factory)
    return "data:" + validate_image(data) + ";base64," + base64.b64encode(data).decode("ascii")


def main(argv):
    if len(argv) != 2:
        raise ImageError("one URL is required")
    sys.stdout.write(data_url(argv[1]))


if __name__ == "__main__":
    try:
        main(sys.argv)
    except ImageError as error:
        print("sportray logo rejected: " + str(error), file=sys.stderr)
        sys.exit(4)
