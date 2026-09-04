#!/usr/bin/env python3
"""Validate Azure resource names used in this repo's lab convention.

Convention: {env}-{region}-{role}[-optional-suffix]
  env:    lab | dev | prod
  region: eus | cus | wus | eus2
  role:   catalog below (vnet, nsg, law, ...)

This is a pipeline gate, not an Azure API call.
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

ENVS = ("lab", "dev", "prod")
REGIONS = ("eus", "cus", "wus", "eus2")
ROLES = (
    "hub-vnet",
    "hub-vng",
    "spoke-vnet",
    "vnet",
    "nsg",
    "snet",
    "vng",
    "pip",
    "law",
    "ag",
    "rg",
)

NAME_RE = re.compile(
    r"^(?P<env>lab|dev|prod)-(?P<region>eus2|eus|cus|wus)-(?P<rest>.+)$"
)


def validate_name(name: str) -> list[str]:
    """Return a list of problems. Empty list means the name is accepted."""
    problems: list[str] = []
    if not name:
        return ["empty name"]
    if name != name.lower():
        problems.append("must be lowercase")
    if not re.fullmatch(r"[a-z0-9-]+", name):
        problems.append("only a-z, 0-9, and hyphen")
    if len(name) < 3 or len(name) > 64:
        problems.append("length must be 3-64")

    match = NAME_RE.match(name)
    if not match:
        problems.append(f"expected {{env}}-{{region}}-{{role}}, env={ENVS}, region={REGIONS}")
        return problems

    rest = match.group("rest")
    if not any(rest == role or rest.startswith(role + "-") for role in ROLES):
        problems.append(f"role must start with one of: {', '.join(ROLES)}")
    return problems


def _self_test() -> int:
    cases = {
        "lab-eus-hub-vnet": [],
        "lab-eus-hub-vnet-nsg": [],
        "lab-eus-hub-vng": [],
        "lab-eus-law": [],
        "prod-cus-law": [],
        "LAB-eus-vnet": ["must be lowercase"],
        "lab_eus_vnet": ["only a-z, 0-9, and hyphen", "expected {env}-{region}-{role}, env="],
        "lab-eus-vmss": ["role must start with one of:"],
        "": ["empty name"],
    }
    failed = 0
    for name, expected_prefixes in cases.items():
        got = validate_name(name)
        if not expected_prefixes:
            ok = got == []
        else:
            ok = len(got) >= 1 and any(
                any(item.startswith(prefix) for item in got) for prefix in expected_prefixes
            )
        if not ok:
            print(f"SELF-TEST FAIL {name!r}: got {got}")
            failed += 1
    if failed == 0:
        print(f"SELF-TEST PASS ({len(cases)} cases)")
    return failed


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("names", nargs="*", help="Resource names to check")
    parser.add_argument("--file", type=Path, help="File with one name per line")
    parser.add_argument("--self-test", action="store_true", help="Run built-in cases")
    args = parser.parse_args(argv)

    if args.self_test:
        return _self_test()

    names = list(args.names)
    if args.file:
        names.extend(
            line.strip()
            for line in args.file.read_text(encoding="utf-8").splitlines()
            if line.strip() and not line.startswith("#")
        )
    if not names:
        parser.error("pass names, --file, or --self-test")

    exit_code = 0
    for name in names:
        problems = validate_name(name)
        if problems:
            exit_code = 1
            print(f"FAIL  {name}: {'; '.join(problems)}")
        else:
            print(f"OK    {name}")
    return exit_code


if __name__ == "__main__":
    sys.exit(main())
