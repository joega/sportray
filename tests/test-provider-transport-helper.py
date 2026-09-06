#!/usr/bin/python3
"""Fixture-driven provider transport safety coverage without live network I/O."""

import importlib.util
import json
from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parent.parent
SPEC = importlib.util.spec_from_file_location("transport", ROOT / "scripts" / "provider-transport-helper.py")
transport = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(transport)
FIXTURE = json.loads((ROOT / "fixtures" / "transport-helper" / "cases.json").read_text())


class Response:
    def __init__(self, status, body, length=None):
        self.status, self.body, self.length, self.offset = status, body, length, 0
        self.fp = None
    def getheader(self, name): return self.length if name == "Content-Length" else None
    def read(self, amount):
        result = self.body[self.offset:self.offset + amount]
        self.offset += len(result)
        return result


class Connection:
    def __init__(self, response): self.response, self.calls, self.closed = response, [], False
    def request(self, *args, **kwargs): self.calls.append((args, kwargs))
    def getresponse(self): return self.response
    def close(self): self.closed = True


class Socket:
    def __init__(self): self.timeout = None
    def settimeout(self, value): self.timeout = value


class ProviderTransportHelperTests(unittest.TestCase):
    def factory(self, response):
        connection = Connection(response)
        return (lambda *args, **kwargs: connection), connection

    def test_fixture_normal_origin_and_body(self):
        factory, connection = self.factory(Response(200, FIXTURE["normalBody"].encode()))
        self.assertEqual(transport.fetch(FIXTURE["allowedUrl"], factory), FIXTURE["normalBody"].encode())
        self.assertEqual(connection.calls[0][0], ("GET", "/apis/site/v2/sports/football/nfl/scoreboard?dates=20260906"))
        self.assertTrue(connection.closed)

    def test_rejects_non_exact_origins_and_redirects(self):
        for value in ("http://site.api.espn.com/x", "https://site.api.espn.com.evil/x",
                      "https://user@site.api.espn.com/x", "https://site.api.espn.com:444/x",
                      "https://site.api.espn.com:not-a-port/x"):
            with self.assertRaises(transport.TransportError): transport.validate_url(value)
        factory, _ = self.factory(Response(FIXTURE["redirectStatus"], b""))
        with self.assertRaises(transport.TransportError): transport.fetch(FIXTURE["allowedUrl"], factory)

    def test_rejects_chunked_oversize_and_applies_remaining_socket_deadline(self):
        factory, _ = self.factory(Response(200, b"x" * FIXTURE["oversizedBytes"]))
        with self.assertRaises(transport.TransportError): transport.fetch(FIXTURE["allowedUrl"], factory)
        sock = Socket()
        response = type("R", (), {"fp": type("F", (), {"raw": type("Raw", (), {"_sock": sock})()})()})()
        transport.apply_read_deadline(response, transport.time.monotonic() + 1)
        self.assertGreater(sock.timeout, 0)


if __name__ == "__main__": unittest.main()
