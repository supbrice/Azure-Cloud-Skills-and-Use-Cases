# Lab 02 — Hybrid connectivity

**AZ-104:** VNet, VPN Gateway, local network gateway, DNS  
**AZ-305:** hybrid network design, S2S vs ExpressRoute, name resolution  
**Resume:** Azure hybrid cloud, VPN, on-prem prefixes

## The problem this lab is for

A hybrid design is not “a VM in Azure plus a VPN checkbox.” You need:

- Address space that **does not overlap** on-prem VLANs
- A `GatewaySubnet` with **no NSG**
- A local network gateway that matches the real on-prem prefixes
- A DNS story (Azure-provided vs AD DS vs Private DNS Resolver)

## What to read

| Artifact | Why |
| --- | --- |
| [terraform/modules/hybrid-gateway](../../terraform/modules/hybrid-gateway) | PIP + VNG + LNG + IPsec connection |
| [terraform/lab/main.tf](../../terraform/lab/main.tf) | Hub VNet (`10.10.0.0/16`) + optional `module.vpn` |
| Lab 04 | DNS, NSG, VLAN→subnet mapping once the tunnel exists |

`enable_vpn_gateway` defaults to **false**. VpnGw1 is allocated even when idle.

## Decision notes

| Choice | When I pick it |
| --- | --- |
| Site-to-site IPsec (this lab) | Lab, branch, or first hybrid path. Shared key in a secret store. |
| ExpressRoute | Sustained throughput, private peering, or a contractual circuit. Not in this repo. |
| Hub-spoke + peering | More than one workload VNet. This lab is a single hub so the reviewer can finish the file. |
| Active-active gateway | Production HA. Lab uses a single instance on purpose. |
| Azure Firewall in the hub | Central egress / DNAT. NSGs still sit on spokes (Lab 04). |

On-prem `10.50.0.0/16` in `terraform.tfvars.example` is a **stand-in VLAN aggregate**, not a customer prefix.

## What Terraform creates when the flag is on

1. Standard public IP on the gateway
2. Route-based `VpnGw1`
3. Local network gateway → on-prem public IP + prefixes
4. IPsec connection with a **sensitive** shared key

Provision time is typically 30–45 minutes. Plan without applying is enough for a portfolio review.

```bash
cd terraform/lab
terraform plan -var='enable_vpn_gateway=false'
```

## After a real tunnel (ops)

```bash
az network vnet-gateway list --resource-group rg-lab-eus-architect -o table
az network vpn-connection show \
  --resource-group rg-lab-eus-architect \
  --name lab-eus-hub-vng-s2s \
  --query "{name:name,status:connectionStatus}" -o table
```

If `connectionStatus` is not `Connected`, do not blame DNS first — check PSK, peer IP, and advertised prefixes (see Lab 04).

## Honest limits

- No BGP, no zone-redundant gateway, no Virtual WAN.
- Shared key default in variables is a placeholder. Rotate if you ever apply.
- ExpressRoute / SD-WAN handoff is a design conversation, not a second module.
