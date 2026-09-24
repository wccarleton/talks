"""Regression tests for originals preservation and upload image preparation."""

import importlib.util
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from PIL import Image

spec = importlib.util.spec_from_file_location("optimizer", Path(__file__).with_name("optimize-media.py"))
media = importlib.util.module_from_spec(spec)
spec.loader.exec_module(media)


class PreparationTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.images = self.root / "images"
        self.images.mkdir()
        self.archive = self.root / "originals"

    def make_image(self, name, size=(2200, 1100), mode="RGB", **kwargs):
        path = self.images / name
        path.parent.mkdir(parents=True, exist_ok=True)
        Image.new(mode, size).save(path, **kwargs)
        return path

    def prepare(self, path):
        return media.prepare(path, self.images, self.archive)

    def test_exact_threshold_unchanged(self):
        for suffix in ("jpg", "png", "webp"):
            path = self.make_image(f"boundary.{suffix}", (2000, 1000))
            with path.open("ab") as stream:
                stream.write(b"\0" * (1_000_000 - path.stat().st_size))
            before = path.read_bytes()
            self.assertIsNone(self.prepare(path)[1])
            self.assertEqual(path.read_bytes(), before)
        self.assertFalse(self.archive.exists())

    def test_jpeg_resize_orientation_archive_and_progressive(self):
        exif = Image.Exif()
        exif[274] = 6
        path = self.make_image("nested/photo.JPG", exif=exif)
        original = path.read_bytes()
        digest = media.digest(path)
        _, target = self.prepare(path)
        self.assertEqual(target, path)
        with Image.open(path) as image:
            self.assertEqual(image.size, (1000, 2000))
            self.assertTrue(image.info.get("progressive"))
            self.assertNotIn(274, image.getexif())
        archive = self.archive / "nested" / f"photo.{digest[:12]}.JPG"
        self.assertEqual(archive.read_bytes(), original)

    def test_png_byte_trigger_no_upscale_and_transparency(self):
        path = self.make_image("nested/alpha.png", (80, 40), "RGBA")
        with path.open("ab") as stream:
            stream.write(b"\0" * 1_000_001)
        _, target = self.prepare(path)
        self.assertEqual(target.suffix, ".webp")
        self.assertFalse(path.exists())
        with Image.open(target) as image:
            self.assertEqual(image.size, (80, 40))
            self.assertEqual(image.getpixel((0, 0))[3], 0)

    def test_palette_transparency_survives(self):
        path = self.make_image("palette.png", mode="P", transparency=0)
        _, target = self.prepare(path)
        with Image.open(target) as image:
            self.assertEqual(image.convert("RGBA").getpixel((0, 0))[3], 0)

    def test_webp_keeps_filename(self):
        path = self.make_image("large.webp")
        self.assertEqual(self.prepare(path)[1], path)
        with Image.open(path) as image:
            self.assertEqual(image.size, (2000, 1000))

    def test_case_insensitive_conversion_collision(self):
        path = self.make_image("collision.png")
        other = self.make_image("collision.WEBP", (10, 10))
        before = (path.read_bytes(), other.read_bytes())
        with self.assertRaises(FileExistsError):
            self.prepare(path)
        self.assertEqual((path.read_bytes(), other.read_bytes()), before)
        self.assertFalse(self.archive.exists())

    def test_corrupt_archive_blocks_replacement(self):
        path = self.make_image("photo.jpg")
        original = path.read_bytes()
        self.archive.mkdir()
        archive = self.archive / f"photo.{media.digest(path)[:12]}.jpg"
        archive.write_bytes(b"corrupt archive")
        with self.assertRaisesRegex(RuntimeError, "archive differs"):
            self.prepare(path)
        self.assertEqual(path.read_bytes(), original)
        self.assertFalse(list(self.images.glob(".optimize-*")))

    def test_atomic_replace_failure_preserves_original(self):
        path = self.make_image("photo.jpg")
        original = path.read_bytes()
        with patch.object(media.os, "replace", side_effect=OSError("simulated failure")):
            with self.assertRaises(OSError):
                self.prepare(path)
        self.assertEqual(path.read_bytes(), original)
        self.assertEqual(next(self.archive.glob("*.jpg")).read_bytes(), original)
        self.assertFalse(list(self.images.glob(".optimize-*")))

    def test_nested_archive_refused(self):
        with self.assertRaises(ValueError):
            media.optimize(self.images, self.images / "originals")

    def test_invalid_image_fails(self):
        path = self.images / "broken.png"
        path.write_bytes(b"not an image")
        with self.assertRaises(OSError):
            self.prepare(path)
        self.assertEqual(path.read_bytes(), b"not an image")

    def test_recursive_processing_and_junk_skip(self):
        self.make_image("nested/good.png")
        (self.images / "._bad.png").write_bytes(b"OS junk")
        self.assertEqual(media.optimize(self.images, self.archive), 1)
        self.assertTrue((self.images / "nested/good.webp").exists())


if __name__ == "__main__":
    unittest.main()
