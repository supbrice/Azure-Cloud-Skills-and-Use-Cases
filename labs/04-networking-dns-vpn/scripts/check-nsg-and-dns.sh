#!/usr/bin/env bash
# Dump VNet DNS, NSG rules, and VPN connection status for a lab resource group.
set -euo pipefail

RG=""
VNET=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --resource-group)
      RG="$2"
      shift 2
      ;;
    --vnet)
      VNET="$2"
      shift 2
      ;;
    -h|--help)
      echo "Usage: $0 --resource-group <rg> --vnet <vnet-name>"
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 2
      ;;
  esac
done

if [[ -z "$RG" || -z "$VNET" ]]; then
  echo "Pass --resource-group and --vnet." >&2
  exit 2
fi

if ! command -v az >/dev/null 2>&1; then
  echo "Azure CLI (az) is required." >&2
  exit 1
fi

echo "== VNet DNS servers (empty dhcpOptions.dnsServers = Azure-provided) =="
az network vnet show \
  --resource-group "$RG" \
  --name "$VNET" \
  --query "{name:name,addressSpace:addressSpace.addressPrefixes,dns:dhcpOptions.dnsServers,subnets:subnets[].{name:name,prefix:addressPrefix}}" \
  --output json

echo
echo "== NSGs in resource group (rules only, no flow logs) =="
az network nsg list --resource-group "$RG" --query "[].{name:name,id:id}" --output table

mapfile -t NSGS < <(az network nsg list --resource-group "$RG" --query "[].name" -o tsv)
for nsg in "${NSGS[@]:-}"; do
  [[ -z "$nsg" ]] && continue
  echo
  echo "-- $nsg --"
  az network nsg rule list \
    --resource-group "$RG" \
    --nsg-name "$nsg" \
    --query "sort_by(@, &priority)[].{pri:priority,name:name,dir:direction,access:access,proto:protocol,src:sourceAddressPrefix,dst:destinationAddressPrefix,port:destinationPortRange}" \
    --output table
done

echo
echo "== Private DNS zones =="
az network private-dns zone list --resource-group "$RG" --output table || true

echo
echo "== VPN connections (empty if enable_vpn_gateway is false) =="
az network vpn-connection list --resource-group "$RG" \
  --query "[].{name:name,status:connectionStatus,mode:connectionMode}" \
  --output table || true
