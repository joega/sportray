#!/usr/bin/python3
"""Fixture-driven safety coverage for validated local team-logo acquisition."""

import importlib.util
import json
from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parent.parent
SPEC = importlib.util.spec_from_file_location("logo_image", ROOT / "scripts" / "logo-image-helper.py")
logo_image = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(logo_image)
FIXTURE = json.loads((ROOT / "fixtures" / "logo-image-helper" / "cases.json").read_text())


def png(width, height):
    return b"\x89PNG\r\n\x1a\n" + b"\x00\x00\x00\rIHDR" + width.to_bytes(4, "big") + height.to_bytes(4, "big") + b"\x08\x06\x00\x00\x00"


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
    def __init__(self, response): self.response, self.closed = response, False
    def request(self, *args, **kwargs): pass
    def getresponse(self): return self.response
    def close(self): self.closed = True


class LogoImageHelperTests(unittest.TestCase):
    def factory(self, response):
        connection = Connection(response)
        return (lambda *args, **kwargs: connection), connection

    def test_valid_png_becomes_local_data_url(self):
        factory, connection = self.factory(Response(200, png(32, 32)))
        result = logo_image.data_url(FIXTURE["allowedUrl"], factory)
        self.assertTrue(result.startswith("data:image/png;base64,"))
        self.assertTrue(connection.closed)

    def test_rejects_hostile_urls_and_redirects(self):
        for value in FIXTURE["hostileUrls"]:
            with self.assertRaises(logo_image.ImageError): logo_image.validate_url(value)
        factory, _ = self.factory(Response(FIXTURE["redirectStatus"], b""))
        with self.assertRaises(logo_image.ImageError): logo_image.fetch(FIXTURE["allowedUrl"], factory)

    def test_rejects_oversized_malformed_and_invalid_dimensions(self):
        factory, _ = self.factory(Response(200, b"x" * FIXTURE["oversizedBytes"]))
        with self.assertRaises(logo_image.ImageError): logo_image.fetch(FIXTURE["allowedUrl"], factory)
        with self.assertRaises(logo_image.ImageError): logo_image.validate_image(b"<svg/>")
        with self.assertRaises(logo_image.ImageError): logo_image.validate_image(
            png(FIXTURE["invalidWidth"], FIXTURE["invalidHeight"]))


if __name__ == "__main__": unittest.main()
