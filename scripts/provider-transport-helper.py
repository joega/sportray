#!/usr/bin/python3
"""Bounded, no-redirect HTTPS transport for Sportray provider JSON."""

import http.client
import socket
import sys
import time
from urllib.parse import urlsplit


MAX_BYTES = 2 * 1024 * 1024
DEADLINE_SECONDS = 10
ALLOWED_HOSTS = frozenset(("site.api.espn.com", "api-web.nhle.com", "statsapi.mlb.com"))


class TransportError(Exception):
    pass


def validate_url(value):
    try:
        parsed = urlsplit(value)
        port = parsed.port
    except ValueError as error:
        raise TransportError("invalid URL") from error
    if (parsed.scheme.lower() != "https" or not parsed.hostname or parsed.username
            or parsed.password or parsed.hostname.lower() not in ALLOWED_HOSTS
            or port not in (None, 443)):
        raise TransportError("unapproved origin")
    return parsed


def remaining(deadline):
    value = deadline - time.monotonic()
    if value <= 0:
        raise TransportError("deadline exceeded")
    return value


def apply_read_deadline(response, deadline):
    raw = getattr(getattr(response, "fp", None), "raw", None)
    stream_socket = getattr(raw, "_sock", None)
    if stream_socket is not None:
        stream_socket.settimeout(remaining(deadline))


def fetch(value, connection_factory=http.client.HTTPSConnection):
    parsed = validate_url(value)
    deadline = time.monotonic() + DEADLINE_SECONDS
    path = parsed.path or "/"
    if parsed.query:
        path += "?" + parsed.query
    try:
        connection = connection_factory(parsed.hostname, port=443, timeout=remaining(deadline))
        connection.request("GET", path, headers={"Accept": "application/json", "User-Agent": "Sportray/1"})
        response = connection.getresponse()
        if response.status < 200 or response.status >= 300:
            raise TransportError("HTTP status rejected")
        length = response.getheader("Content-Length")
        if length is not None and (not length.isdecimal() or int(length) > MAX_BYTES):
            raise TransportError("response exceeds byte cap")
        chunks = []
        total = 0
        while True:
            apply_read_deadline(response, deadline)
            chunk = response.read(min(8192, MAX_BYTES + 1 - total))
            if not chunk:
                break
            total += len(chunk)
            if total > MAX_BYTES:
                raise TransportError("response exceeds byte cap")
            chunks.append(chunk)
        connection.close()
        return b"".join(chunks)
    except (OSError, http.client.HTTPException, socket.timeout) as error:
        raise TransportError("transport failed") from error


def main(argv):
    if len(argv) != 2:
        raise TransportError("one URL is required")
    sys.stdout.buffer.write(fetch(argv[1]))


if __name__ == "__main__":
    try:
        main(sys.argv)
    except TransportError as error:
        print("sportray transport rejected: " + str(error), file=sys.stderr)
        sys.exit(4)
