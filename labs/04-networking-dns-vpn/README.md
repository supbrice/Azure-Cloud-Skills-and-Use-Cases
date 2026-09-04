# Lab 04 — Networking, DNS, VPN path checks

**AZ-104:** NSGs, DNS, Network Watcher, VPN diagnostics  
**AZ-305:** segmentation, hybrid DNS, path design  
**Resume:** DNS, DHCP, VPN, firewalls, VLANs, endpoint monitoring

## The problem this lab is for

On-prem I think in **VLANs + DHCP scopes + a firewall rule**. In Azure the analogues are:

| On-prem | Azure in this lab |
| --- | --- |
| VLAN / L2 segment | Subnet + NSG profile |
| DHCP server | **Platform DHCP** on the VNet (you do not run Windows DHCP for Azure NICs) |
| Firewall object | NSG (spoke) and optionally Azure Firewall (hub, not provisioned here) |
| Internal DNS zone | Private DNS zone `internal.lab.example` + VNet link |
| Endpoint ping | `az network watcher` / PowerShell resolution + TCP probe |

Custom `dns_servers` on the VNet is how you steer hybrid name resolution to AD DS or a DNS Private Resolver. Empty list = Azure-provided DNS.

## What to read

| Artifact | Why |
| --- | --- |
| [terraform/modules/spoke-network](../../terraform/modules/spoke-network) | Subnets + NSG profiles (`app`, `identity`, `gateway`) |
| [terraform/lab/main.tf](../../terraform/lab/main.tf) | Address plan + private DNS zone + registration link |
| [scripts/Test-HybridNameResolution.ps1](scripts/Test-HybridNameResolution.ps1) | Resolve + TCP probe |
| [scripts/check-nsg-and-dns.sh](scripts/check-nsg-and-dns.sh) | `az` dump of NSG rules, VNet DNS, VPN status |

## Address plan (lab)

```text
Azure hub           10.10.0.0/16
  GatewaySubnet     10.10.0.0/27     # no NSG
  shared            10.10.1.0/24     # app profile
  identity          10.10.2.0/24     # RDP/SSH from VNet only
On-prem aggregate   10.50.0.0/16     # stand-in for VLAN 50–5x
```

Pick non-overlapping space before you build a tunnel. Overlap is the most expensive “typo” in hybrid.

## DHCP note

Azure assigns NIC addresses from the subnet prefix. You do **not** deploy a DHCP relay into the subnet for Azure VMs. On-prem DHCP still matters for offices and for AD site design. If you set custom DNS on the VNet, those servers must be reachable **before** domain join works — that is a path problem (Lab 02), not a DHCP problem.

## Firewall note

NSGs are stateful L4. They are not a full NVA. I use them as the default subnet control. Central SNAT, FQDN rules, and threat intel belong on Azure Firewall or an NVA in the hub. This lab does not pretend an NSG is that NVA.

## Run the checks (needs a deployed lab + az login)

```bash
chmod +x scripts/check-nsg-and-dns.sh
./scripts/check-nsg-and-dns.sh \
  --resource-group rg-lab-eus-architect \
  --vnet lab-eus-hub-vnet
```

```powershell
./scripts/Test-HybridNameResolution.ps1 `
  -Name "something.internal.lab.example" `
  -TcpTarget "10.10.1.4" `
  -TcpPort 53
```

Network Watcher IP flow verify (once a NIC exists):

```bash
az network watcher test-ip-flow \
  --direction Inbound \
  --protocol TCP \
  --local 10.10.2.4:3389 \
  --remote 10.50.10.20:50000 \
  --resource-group rg-lab-eus-architect \
  --vm <windows-jump> \
  --nic <nic-name>
```

That last command is documented, not wrapped — it needs a real VM.

## Honest limits

- No UniFi / Cisco IOS configs. VLAN mapping is the address plan + NSG profile.
- No packet capture automation (can be enabled per incident).
- VPN Gateway apply is still Lab 02’s cost decision.
