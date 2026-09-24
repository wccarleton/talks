"""Prepare JPEG, PNG and WebP uploads; archive originals outside the upload tree."""

from __future__ import annotations

import argparse
import hashlib
import os
import shutil
import sys
import tempfile
from pathlib import Path

from PIL import Image, ImageOps

MAX_EDGE = 2000
MAX_BYTES = 1_000_000
PHOTO_EXTENSIONS = {".jpg", ".jpeg", ".png", ".webp"}
JUNK = {"thumbs.db", "desktop.ini", ".ds_store", "__macosx"}


def digest(path: Path) -> str:
    with path.open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()


def archive_original(source: Path, relative: Path, archive_root: Path,
                     original_hash: str) -> Path:
    archived = archive_root / relative.parent / (
        f"{relative.stem}.{original_hash[:12]}{relative.suffix}"
    )
    archived.parent.mkdir(parents=True, exist_ok=True)
    if not archived.exists():
        fd, name = tempfile.mkstemp(prefix=".archive-", dir=archived.parent)
        os.close(fd)
        temporary = Path(name)
        try:
            shutil.copy2(source, temporary)
            if digest(temporary) != original_hash:
                raise RuntimeError(f"Source changed while archiving: {source}")
            # Publish a complete archive atomically, without overwriting an
            # existing archive (including a truncated-hash filename collision).
            try:
                os.link(temporary, archived)
            except FileExistsError:
                pass
        finally:
            temporary.unlink(missing_ok=True)
    if digest(archived) != original_hash:
        raise RuntimeError(f"Original archive differs from source: {archived}")
    return archived


def prepare(source: Path, image_root: Path, archive_root: Path) -> tuple[str, Path | None]:
    if source.is_symlink() or not source.resolve().is_relative_to(image_root):
        raise ValueError(f"Image must be a regular file within the upload folder: {source}")
    original_hash = digest(source)
    old_size = source.stat().st_size
    with Image.open(source) as opened:
        width, height = opened.size
        opened.verify()
    if max(width, height) <= MAX_EDGE and old_size <= MAX_BYTES:
        return "unchanged (within dimension and byte thresholds)", None

    target = source.with_suffix(".webp") if source.suffix.lower() == ".png" else source
    if target != source and any(p.name.casefold() == target.name.casefold()
                                for p in source.parent.iterdir()):
        raise FileExistsError(f"PNG-to-WebP target already exists: {target}")
    with Image.open(source) as opened:
        if getattr(opened, "n_frames", 1) > 1:
            raise ValueError(f"Refusing to flatten an animated image: {source}")
        image = ImageOps.exif_transpose(opened)
        image.thumbnail((MAX_EDGE, MAX_EDGE), Image.Resampling.LANCZOS)
        expected_size = image.size
        webp = target.suffix.lower() == ".webp"
        if webp:
            # Palette transparency is not represented by an A band.
            image = image.convert("RGBA" if "A" in image.getbands()
                                  or "transparency" in image.info else "RGB")
        else:
            image = image.convert("RGB")
        fd, name = tempfile.mkstemp(prefix=".optimize-", suffix=".tmp", dir=source.parent)
        os.close(fd)
        temporary = Path(name)
        try:
            if webp:
                image.save(temporary, "WEBP", quality=85, method=6)
            else:
                image.save(temporary, "JPEG", quality=88, optimize=True, progressive=True)
            with Image.open(temporary) as check:
                check.verify()
            with Image.open(temporary) as check:
                check.load()
                if check.size != expected_size or max(check.size) > MAX_EDGE:
                    raise RuntimeError(f"Encoded dimensions failed verification: {source}")
                if check.format != ("WEBP" if webp else "JPEG"):
                    raise RuntimeError(f"Encoded format failed verification: {source}")
            archived = archive_original(source, source.relative_to(image_root),
                                        archive_root, original_hash)
            if digest(source) != original_hash:
                raise RuntimeError(f"Source changed during optimization: {source}")
            if target == source:
                os.replace(temporary, target)
            else:
                # Atomic, no-clobber publication: never overwrite a WebP that
                # appeared after the initial collision check.
                os.link(temporary, target)
                source.unlink()
            return f"{old_size:,} -> {target.stat().st_size:,} bytes; original: {archived}", target
        finally:
            temporary.unlink(missing_ok=True)


def optimize(image_root: Path, archive_root: Path) -> int:
    image_root, archive_root = image_root.resolve(), archive_root.resolve()
    if image_root.is_relative_to(archive_root) or archive_root.is_relative_to(image_root):
        raise ValueError("Upload and original-archive folders must be separate, non-nested trees")
    if not image_root.is_dir():
        raise ValueError(f"Image folder does not exist: {image_root}")
    count = 0
    # Snapshot the paths so newly converted WebP files aren't processed twice.
    for source in sorted(image_root.rglob("*")):
        relative = source.relative_to(image_root)
        if any(p.lower() in JUNK or p.startswith("._") for p in relative.parts):
            continue
        if source.is_symlink():
            raise ValueError(f"Symlinks are not supported in the upload folder: {source}")
        if not source.is_file() or source.suffix.lower() not in PHOTO_EXTENSIONS:
            continue
        result, target = prepare(source, image_root, archive_root)
        print(f"{relative.as_posix()}: {result}", flush=True)
        if target is not None:
            count += 1
            if target != source:
                print(f"RENAMED: {relative.as_posix()} -> {target.relative_to(image_root).as_posix()}"
                      " (update slide references)", flush=True)
    print(f"Done: {count} image(s) optimized.", flush=True)
    return count


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--images", type=Path, required=True)
    parser.add_argument("--archive", type=Path, required=True)
    args = parser.parse_args()
    try:
        optimize(args.images, args.archive)
    except (OSError, ValueError, RuntimeError) as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
