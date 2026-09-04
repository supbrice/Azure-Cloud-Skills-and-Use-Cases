#!/usr/bin/env bash
# Read-only Azure RBAC export. Flags Owner and User Access Administrator
# at subscription or management-group scope — the usual identity-hygiene hits.
set -euo pipefail

SUBSCRIPTION=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --subscription)
      SUBSCRIPTION="$2"
      shift 2
      ;;
    -h|--help)
      echo "Usage: $0 --subscription <subscription-id>"
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 2
      ;;
  esac
done

if [[ -z "$SUBSCRIPTION" ]]; then
  echo "Pass --subscription <id>." >&2
  exit 2
fi

if ! command -v az >/dev/null 2>&1; then
  echo "Azure CLI (az) is required." >&2
  exit 1
fi

az account set --subscription "$SUBSCRIPTION"

# include-inherited catches MG-level assignments that land on the subscription.
JSON="$(az role assignment list --all --include-inherited --output json)"

python3 - "$JSON" <<'PY'
import json, sys

HIGH_IMPACT = {
    "Owner",
    "User Access Administrator",
}

raw = sys.argv[1]
rows = json.loads(raw)
print(f"{'SCOPE':<80} {'ROLE':<28} {'PRINCIPAL'}")
print("-" * 140)
hits = 0
for row in sorted(rows, key=lambda r: (r.get("roleDefinitionName") or "", r.get("scope") or "")):
    role = row.get("roleDefinitionName") or ""
    scope = row.get("scope") or ""
    if role not in HIGH_IMPACT:
        continue
    # Subscription or MG scope only. RG-scoped Owner is still wide but less so.
    if "/resourceGroups/" in scope:
        continue
    principal = row.get("principalName") or row.get("principalId")
    print(f"{scope:<80} {role:<28} {principal}")
    hits += 1
print(f"\n{hits} standing Owner / User Access Administrator assignment(s) above RG scope.")
print("This script does not remove assignments. Review, then use PIM or a scoped custom role.")
PY
