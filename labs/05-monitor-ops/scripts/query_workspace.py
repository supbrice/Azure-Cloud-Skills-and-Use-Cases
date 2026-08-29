#!/usr/bin/env python3
"""Print or run the lab KQL queries.

--print-query never talks to Azure. --workspace-id uses DefaultAzureCredential
and azure-monitor-query (optional extras in requirements.txt).
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

QUERIES = Path(__file__).resolve().parent.parent / "queries"

KNOWN = {
    "failed-signins": "failed-signins.kql",
    "vpn-and-nsg": "vpn-and-nsg.kql",
    "rbac-changes": "rbac-changes.kql",
}


def load_query(name: str) -> str:
    if name not in KNOWN:
        known = ", ".join(sorted(KNOWN))
        raise SystemExit(f"Unknown query {name!r}. Choose: {known}")
    return (QUERIES / KNOWN[name]).read_text(encoding="utf-8")


def print_query(name: str) -> int:
    print(load_query(name))
    return 0


def run_query(workspace_id: str, name: str) -> int:
    try:
        from azure.identity import DefaultAzureCredential
        from azure.monitor.query import LogsQueryClient, LogsQueryStatus
    except ImportError:
        print(
            "Install extras: pip install -r labs/05-monitor-ops/scripts/requirements.txt",
            file=sys.stderr,
        )
        return 2

    from datetime import timedelta

    client = LogsQueryClient(DefaultAzureCredential())
    result = client.query_workspace(
        workspace_id=workspace_id,
        query=load_query(name),
        timespan=timedelta(hours=24),
    )
    if result.status != LogsQueryStatus.SUCCESS:
        print(f"Query status: {result.status}", file=sys.stderr)
        if getattr(result, "partial_error", None):
            print(result.partial_error, file=sys.stderr)
        return 1
    if not result.tables:
        print("No tables (workspace may not have this table yet).")
        return 0
    table = result.tables[0]
    print("\t".join(table.columns))
    for row in table.rows:
        print("\t".join("" if c is None else str(c) for c in row))
    return 0


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--query-name",
        default="failed-signins",
        choices=sorted(KNOWN),
        help="Logical query name",
    )
    parser.add_argument(
        "--print-query",
        nargs="?",
        const="__flag__",
        default=None,
        metavar="NAME",
        help="Print KQL and exit (no Azure). Optional name overrides --query-name.",
    )
    parser.add_argument(
        "--workspace-id",
        help="Log Analytics workspace GUID (customer id)",
    )
    args = parser.parse_args(argv)

    if args.print_query is not None:
        name = args.query_name if args.print_query == "__flag__" else args.print_query
        if name not in KNOWN:
            parser.error(f"Unknown query {name!r}. Choose: {', '.join(sorted(KNOWN))}")
        return print_query(name)
    if not args.workspace_id:
        parser.error("pass --print-query or --workspace-id")
    return run_query(args.workspace_id, args.query_name)


if __name__ == "__main__":
    sys.exit(main())
