#!/usr/bin/env python3
"""Verify a release Android App Bundle before it is uploaded to Play.

Runs automatically after every `bundleRelease` (see android/app/build.gradle.kts)
and can be run by hand:

    python3 tool/verify_release_bundle.py
    python3 tool/verify_release_bundle.py path/to/app-release.aab

Why this exists
---------------
Play rejects or silently degrades a bundle whose *merged* manifest disagrees
with the Play Console declarations. The advertising ID permission was already
lost once this way and had to be restored in 457c67d, and nothing would have
caught it before upload. Checking the source manifest is not enough: the
manifest merger combines every plugin's manifest and applies the
`tools:node="remove"` rules, so only the manifest inside the finished bundle
says what actually ships.

Expected values live in tool/release_checks.json, except the version, which
comes from pubspec.yaml so the two can never drift.

Implementation note
-------------------
A bundle stores its manifest as protobuf (Android's Resources.proto), not as
XML or the binary XML that aapt2 reads, and `aapt2 dump` refuses a .aab
outright. bundletool would decode it, but it is a large download that this
project does not otherwise need. The fields this script reads sit at a stable,
documented offset pattern, so it reads them directly. See _attribute_value.
"""

from __future__ import annotations

import json
import re
import subprocess
import sys
import zipfile
from pathlib import Path

MANIFEST_IN_BUNDLE = "base/manifest/AndroidManifest.xml"

# Protobuf wire tags inside an XmlAttribute message (Resources.proto).
TAG_NAME = b"\x12"   # field 2, attribute name
TAG_VALUE = b"\x1a"  # field 3, attribute value, always a length-delimited string

GREEN, RED, YELLOW, DIM, BOLD, OFF = (
    ("\033[32m", "\033[31m", "\033[33m", "\033[2m", "\033[1m", "\033[0m")
    if sys.stdout.isatty()
    else ("", "", "", "", "", "")
)


# --------------------------------------------------------------------------
# protobuf helpers
# --------------------------------------------------------------------------

def _read_varint(blob: bytes, pos: int) -> tuple[int, int]:
    """Read a base-128 varint. Returns (value, offset just past it)."""
    value = 0
    shift = 0
    while pos < len(blob):
        byte = blob[pos]
        value |= (byte & 0x7F) << shift
        pos += 1
        if not byte & 0x80:
            return value, pos
        shift += 7
        if shift > 63:
            break
    raise ValueError("malformed varint in manifest")


def _string_at(blob: bytes, pos: int) -> str:
    """Read a length-delimited string whose length varint starts at pos."""
    length, start = _read_varint(blob, pos)
    return blob[start:start + length].decode("utf-8", "replace")


def _attribute_value(blob: bytes, name: str, start: int = 0) -> str | None:
    """Value of the manifest attribute called `name`.

    An XmlAttribute serialises as name (field 2) then value (field 3), so the
    value's tag byte follows the name text directly.
    """
    needle = name.encode()
    pos = start
    while True:
        found = blob.find(needle, pos)
        if found < 0:
            return None
        after = found + len(needle)
        if blob[after:after + 1] == TAG_VALUE:
            return _string_at(blob, after + 1)
        pos = found + 1


def declared_permissions(blob: bytes) -> set[str]:
    """Every permission the merged manifest actually declares.

    Located through the `uses-permission` elements rather than by scanning for
    permission-shaped strings, so a permission merely mentioned in a metadata
    value or a <queries> block is never mistaken for a declared one.
    """
    found: set[str] = set()
    attr_name = TAG_NAME + bytes([4]) + b"name" + TAG_VALUE
    pos = 0
    while True:
        element = blob.find(b"uses-permission", pos)
        if element < 0:
            return found
        # Stay inside this element; attributes follow their element closely.
        window_end = min(element + 512, len(blob))
        attr = blob.find(attr_name, element, window_end)
        if attr >= 0:
            found.add(_string_at(blob, attr + len(attr_name)))
        pos = element + 1


# --------------------------------------------------------------------------
# inputs
# --------------------------------------------------------------------------

def repo_root() -> Path:
    return Path(__file__).resolve().parent.parent


def find_bundle(explicit: str | None) -> Path:
    if explicit:
        return Path(explicit).resolve()
    return repo_root() / "build/app/outputs/bundle/release/app-release.aab"


def pubspec_version(root: Path) -> tuple[str, str]:
    """(versionName, versionCode) from the active version line in pubspec.yaml."""
    text = (root / "pubspec.yaml").read_text()
    match = re.search(r"^version:\s*([0-9.]+)\+([0-9]+)", text, re.MULTILINE)
    if not match:
        raise SystemExit("could not read an active 'version:' line from pubspec.yaml")
    return match.group(1), match.group(2)


def certificate_sha1(bundle: Path) -> str | None:
    """SHA-1 of the signing certificate, uppercase hex, no separators."""
    try:
        out = subprocess.run(
            ["keytool", "-printcert", "-jarfile", str(bundle)],
            capture_output=True, text=True, timeout=120,
        ).stdout
    except (OSError, subprocess.SubprocessError):
        return None
    match = re.search(r"SHA1:\s*([0-9A-Fa-f:]+)", out)
    return match.group(1).replace(":", "").upper() if match else None


# --------------------------------------------------------------------------
# report
# --------------------------------------------------------------------------

class Report:
    def __init__(self) -> None:
        self.failures: list[str] = []
        self.warnings: list[str] = []

    def ok(self, label: str, detail: str = "") -> None:
        print(f"  {GREEN}PASS{OFF}  {label}" + (f"  {DIM}{detail}{OFF}" if detail else ""))

    def fail(self, label: str, detail: str) -> None:
        print(f"  {RED}FAIL{OFF}  {label}\n        {detail}")
        self.failures.append(label)

    def warn(self, label: str, detail: str) -> None:
        print(f"  {YELLOW}WARN{OFF}  {label}\n        {detail}")
        self.warnings.append(label)


def main(argv: list[str]) -> int:
    root = repo_root()
    bundle = find_bundle(argv[1] if len(argv) > 1 else None)

    if not bundle.exists():
        # Reached when the build that should have produced it already failed.
        # Gradle reports that failure; do not bury it behind a second one.
        print(f"{DIM}verify_release_bundle: no bundle at {bundle}, nothing to check{OFF}")
        return 0

    checks = json.loads((root / "tool/release_checks.json").read_text())

    with zipfile.ZipFile(bundle) as archive:
        blob = archive.read(MANIFEST_IN_BUNDLE)

    size_mb = bundle.stat().st_size / (1024 * 1024)
    print(f"\n{BOLD}Verifying release bundle{OFF}")
    print(f"{DIM}  {bundle}{DIM}  ({size_mb:.1f} MB){OFF}\n")

    report = Report()

    # --- identity -----------------------------------------------------------
    expected_id = checks["applicationId"]
    actual_id = _attribute_value(blob, "package")
    if actual_id == expected_id:
        report.ok("application id", actual_id)
    else:
        report.fail("application id", f"expected {expected_id}, bundle has {actual_id}")

    # --- version ------------------------------------------------------------
    want_name, want_code = pubspec_version(root)
    got_code = _attribute_value(blob, "versionCode")
    got_name = _attribute_value(blob, "versionName")

    if got_code == want_code:
        report.ok("version code matches pubspec", got_code)
    else:
        report.fail("version code matches pubspec",
                    f"pubspec.yaml says {want_code}, bundle has {got_code}")

    if got_name == want_name:
        report.ok("version name matches pubspec", got_name)
    else:
        report.fail("version name matches pubspec",
                    f"pubspec.yaml says {want_name}, bundle has {got_name}")

    # --- permissions --------------------------------------------------------
    declared = declared_permissions(blob)

    missing = [p for p in checks["requiredPermissions"] if p not in declared]
    if missing:
        for perm in missing:
            report.fail(f"required permission {perm}", checks["requiredPermissions"][perm])
    else:
        report.ok("required permissions present",
                  f"{len(checks['requiredPermissions'])} checked")

    present = [p for p in checks["forbiddenPermissions"] if p in declared]
    if present:
        for perm in present:
            report.fail(f"forbidden permission {perm}", checks["forbiddenPermissions"][perm])
    else:
        report.ok("stripped permissions stayed out",
                  f"{len(checks['forbiddenPermissions'])} checked")

    # --- signing ------------------------------------------------------------
    expected_sha1 = checks["uploadKeySha1"].replace(":", "").upper()
    actual_sha1 = certificate_sha1(bundle)
    if actual_sha1 is None:
        report.warn("signing certificate",
                    "could not read it; keytool is unavailable or the bundle is unsigned")
    elif actual_sha1 == expected_sha1:
        report.ok("signed with the upload key", actual_sha1[:16] + "...")
    else:
        report.fail("signed with the upload key",
                    f"expected {expected_sha1}\n        bundle has  {actual_sha1}\n"
                    "        A bundle signed with the wrong key cannot be accepted by Play.")

    # --- verdict ------------------------------------------------------------
    print()
    if report.failures:
        print(f"{RED}{BOLD}Release bundle FAILED {len(report.failures)} check(s). "
              f"Do not upload it.{OFF}")
        print(f"{DIM}Expected values live in tool/release_checks.json.{OFF}\n")
        return 1

    tail = f" ({len(report.warnings)} warning(s))" if report.warnings else ""
    print(f"{GREEN}{BOLD}Release bundle passed all checks{tail}.{OFF}")
    print(f"{DIM}Remember: the Play Console Data Safety form must still agree "
          f"with these permissions.{OFF}\n")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
