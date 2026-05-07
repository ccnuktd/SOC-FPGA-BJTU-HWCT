#!/usr/bin/env python3
"""Synchronize shared RTL files into diff-tools/rtl.

The repository keeps two RTL trees:
  - rtl/: source of truth for synthesizable RTL
  - diff-tools/rtl/: Verilator/difftest RTL tree

Only files listed in SYNC_FILES are copied automatically. Files listed in
PROTECTED_FILES intentionally differ because they contain simulation-only
memory loading, UART stdout output, debug ports, DPI-C hooks, or board/sim
parameter differences.
"""

from __future__ import annotations

import argparse
import filecmp
import shutil
import subprocess
import sys
from pathlib import Path


SYNC_FILES = [
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


def same_file(left: Path, right: Path) -> bool:
    return left.exists() and right.exists() and filecmp.cmp(left, right, shallow=False)


def sync_file(root: Path, rel: str, dry_run: bool) -> bool:
    src = root / "rtl" / rel
    dst = root / "diff-tools" / "rtl" / rel
    if not src.exists():
        print(f"[ERROR] source missing: rtl/{rel}", file=sys.stderr)
        return False
    if same_file(src, dst):
        print(f"[OK] {rel}")
        return True
    print(f"[SYNC] rtl/{rel} -> diff-tools/rtl/{rel}")
    if not dry_run:
        dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(src, dst)
    return True


def command_sync(args: argparse.Namespace) -> int:
    root = repo_root()
    ok = True
    for rel in SYNC_FILES:
        ok = sync_file(root, rel, args.dry_run) and ok
    return 0 if ok else 1


def command_check(_: argparse.Namespace) -> int:
    root = repo_root()
    dirty = []
    missing = []
    for rel in SYNC_FILES:
        src = root / "rtl" / rel
        dst = root / "diff-tools" / "rtl" / rel
        if not src.exists() or not dst.exists():
            missing.append(rel)
        elif not same_file(src, dst):
            dirty.append(rel)

    if missing:
        print("[ERROR] Missing synchronized RTL files:")
        for rel in missing:
            print(f"  - {rel}")
    if dirty:
        print("[ERROR] diff-tools/rtl is out of sync for:")
        for rel in dirty:
            print(f"  - {rel}")
        print("Run `make rtl-sync` to update the synchronized files.")
    if not missing and not dirty:
        print("[OK] diff-tools/rtl synchronized files match rtl/")
    return 1 if missing or dirty else 0


def command_report(_: argparse.Namespace) -> int:
    root = repo_root()
    dirty = []
    missing = []

    print("Synchronized files:")
    for rel in SYNC_FILES:
        src = root / "rtl" / rel
        dst = root / "diff-tools" / "rtl" / rel
        if not src.exists() or not dst.exists():
            missing.append(rel)
            status = "MISSING"
        elif same_file(src, dst):
            status = "OK"
        else:
            dirty.append(rel)
            status = "DIFF"
        print(f"  [{status}] {rel}")

    if dirty:
        print("\nDiffs for out-of-sync synchronized files:")
        for rel in dirty:
            src = root / "rtl" / rel
            dst = root / "diff-tools" / "rtl" / rel
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

    if missing:
        print("\nMissing synchronized files, contents not shown:")
        for rel in missing:
            print(f"  - {rel}")

    print("\nProtected simulation-specific files, contents not shown:")
    for rel in PROTECTED_FILES:
        src = root / "rtl" / rel
        dst = root / "diff-tools" / "rtl" / rel
        if not dst.exists():
            print(f"  [SIM-ONLY] diff-tools/rtl/{rel}")
        elif not src.exists():
            print(f"  [NO-RTL] diff-tools/rtl/{rel}")
        elif same_file(src, dst):
            print(f"  [SAME] {rel}")
        else:
            print(f"  [PROTECTED-DIFF] {rel}")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description="Synchronize shared RTL into diff-tools/rtl")
    sub = parser.add_subparsers(dest="command", required=True)

    p_sync = sub.add_parser("sync", help="copy synchronized files from rtl/ to diff-tools/rtl/")
    p_sync.add_argument("--dry-run", action="store_true", help="print actions without copying")
    p_sync.set_defaults(func=command_sync)

    p_check = sub.add_parser("check", help="fail if synchronized files differ")
    p_check.set_defaults(func=command_check)

    p_report = sub.add_parser("report", help="show synchronized and protected RTL status")
    p_report.set_defaults(func=command_report)

    args = parser.parse_args()
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
