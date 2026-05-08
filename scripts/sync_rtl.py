#!/usr/bin/env python3
"""Maintain diff-tools/rtl links to the top-level rtl tree.

The top-level rtl/ directory is the source of truth. diff-tools/rtl keeps
simulation-specific files as real files, while shared RTL files are symlinks
back to rtl/. This avoids maintaining two drifting copies of the same logic.
"""

from __future__ import annotations

import argparse
import os
import subprocess
import sys
from pathlib import Path


LINK_FILES = [
    "core/pa_core_clint.v",
    "core/pa_core_csr.v",
    "core/pa_core_exu.v",
    "core/pa_core_exu_div.v",
    "core/pa_core_exu_mul.v",
    "core/pa_core_idu.v",
    "core/pa_core_mau.v",
    "core/pa_core_pcgen.v",
    "perips/pa_perips_timer.v",
    "soc/pa_soc_rbm.v",
    "utils/pa_dff.v",
]

PROTECTED_FILES = [
    "pa_chip_param.v",
    "pa_chip_top_sim.v",
    "core/pa_core_rtu.v",
    "core/pa_core_top.v",
    "core/pa_core_xreg.v",
    "perips/pa_perips_tcm.v",
    "perips/pa_perips_uart.v",
]


def repo_root() -> Path:
    return Path(__file__).resolve().parents[1]


def paths(root: Path, rel: str) -> tuple[Path, Path]:
    return root / "rtl" / rel, root / "diff-tools" / "rtl" / rel


def link_target(src: Path, dst: Path) -> str:
    return os.path.relpath(src, start=dst.parent)


def is_expected_link(src: Path, dst: Path) -> bool:
    if not dst.is_symlink():
        return False
    actual = os.readlink(dst)
    return actual == link_target(src, dst)


def fix_link(root: Path, rel: str, dry_run: bool) -> bool:
    src, dst = paths(root, rel)
    if not src.exists():
        print(f"[ERROR] source missing: rtl/{rel}", file=sys.stderr)
        return False

    expected = link_target(src, dst)
    if is_expected_link(src, dst):
        print(f"[OK] {rel} -> {expected}")
        return True

    if dst.exists() or dst.is_symlink():
        print(f"[LINK] replace diff-tools/rtl/{rel} -> {expected}")
    else:
        print(f"[LINK] create diff-tools/rtl/{rel} -> {expected}")

    if not dry_run:
        dst.parent.mkdir(parents=True, exist_ok=True)
        if dst.exists() or dst.is_symlink():
            dst.unlink()
        dst.symlink_to(expected)
    return True


def command_sync(args: argparse.Namespace) -> int:
    root = repo_root()
    ok = True
    for rel in LINK_FILES:
        ok = fix_link(root, rel, args.dry_run) and ok
    return 0 if ok else 1


def command_check(_: argparse.Namespace) -> int:
    root = repo_root()
    bad = []
    missing = []
    for rel in LINK_FILES:
        src, dst = paths(root, rel)
        if not src.exists() or not dst.exists():
            missing.append(rel)
        elif not is_expected_link(src, dst):
            bad.append(rel)

    if missing:
        print("[ERROR] Missing linked RTL files:")
        for rel in missing:
            print(f"  - {rel}")
    if bad:
        print("[ERROR] diff-tools/rtl should link these files to rtl/:")
        for rel in bad:
            print(f"  - {rel}")
        print("Run `make rtl-sync` to recreate the links.")
    if not missing and not bad:
        print("[OK] diff-tools/rtl shared files are symlinked to rtl/")
    return 1 if missing or bad else 0


def command_report(_: argparse.Namespace) -> int:
    root = repo_root()
    bad = []

    print("Linked shared RTL files:")
    for rel in LINK_FILES:
        src, dst = paths(root, rel)
        expected = link_target(src, dst)
        if not src.exists() or not dst.exists():
            status = "MISSING"
            bad.append(rel)
        elif is_expected_link(src, dst):
            status = "LINK"
        else:
            status = "NOT-LINK"
            bad.append(rel)
        print(f"  [{status}] {rel} -> {expected}")

    if bad:
        print("\nDiffs for shared files that are not linked correctly:")
        for rel in bad:
            src, dst = paths(root, rel)
            if not src.exists() or not dst.exists():
                print(f"\n--- {rel} ---")
                print("missing source or destination, contents not shown")
                continue
            print(f"\n--- {rel} ---")
            result = subprocess.run(
                ["diff", "-u", str(src), str(dst)],
                cwd=root,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                check=False,
            )
            print(result.stdout, end="")

    print("\nProtected simulation-specific files, contents not shown:")
    for rel in PROTECTED_FILES:
        src, dst = paths(root, rel)
        if not dst.exists():
            print(f"  [MISSING] diff-tools/rtl/{rel}")
        elif not src.exists():
            print(f"  [SIM-ONLY] diff-tools/rtl/{rel}")
        elif dst.is_symlink():
            print(f"  [UNEXPECTED-LINK] {rel}")
        else:
            print(f"  [PROTECTED] {rel}")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description="Maintain diff-tools/rtl symlinks")
    sub = parser.add_subparsers(dest="command", required=True)

    p_sync = sub.add_parser("sync", help="create or repair diff-tools/rtl symlinks")
    p_sync.add_argument("--dry-run", action="store_true", help="print actions without changing files")
    p_sync.set_defaults(func=command_sync)

    p_check = sub.add_parser("check", help="fail if linked files are not symlinks to rtl/")
    p_check.set_defaults(func=command_check)

    p_report = sub.add_parser("report", help="show link status and protected files")
    p_report.set_defaults(func=command_report)

    args = parser.parse_args()
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
