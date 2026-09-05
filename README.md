# azure-architect-labs

Reference labs for **Brice** ([supbrice](https://github.com/supbrice)) — Azure Solutions Architect Expert (Nov 2024) and Azure Administrator Associate (Sep 2024).

This repo used to be a beginner Azure 101 list (VM / App Service / AKS / SQL / Functions plus `az group create`). That does not match the work: **hybrid Azure, Entra ID, Terraform + PowerShell + Python, and operations**. These labs do.

They are **labs and readable patterns**, not a live customer estate. They do not claim production SLAs or invented metrics.

## Who this is for

Hiring managers and reviewers who want to see how I think about:

| Resume / cert theme | Where it shows up |
| --- | --- |
| Entra ID, Conditional Access, RBAC, identity hygiene | [Lab 01](labs/01-identity-access/README.md) |
| Hybrid connectivity (VPN, on-prem prefixes, private DNS) | [Lab 02](labs/02-hybrid-connectivity/README.md) |
| Terraform modules + Python/PowerShell around the pipeline | [Lab 03](labs/03-terraform-modules/README.md) |
| DNS, VPN, NSG-as-firewall, VLAN→subnet mapping, endpoint checks | [Lab 04](labs/04-networking-dns-vpn/README.md) |
| Azure Monitor, Log Analytics, incident notes, SLA *mindset* | [Lab 05](labs/05-monitor-ops/README.md) |
| ServiceNow Tier 2/3 (context only) | [docs/ops-itsm.md](docs/ops-itsm.md) |

AZ-104 and AZ-305 skill mapping: [docs/cert-skill-map.md](docs/cert-skill-map.md).

LinkedIn: [linkedin.com/in/ngubriceche](https://www.linkedin.com/in/ngubriceche)

## What is in here

```text
labs/                         # narrative + runbooks for each lab
terraform/modules/            # reusable IaC (network, identity, VPN, monitor)
terraform/lab/                # one disposable composition you can plan
scripts live next to each lab # az CLI, PowerShell, Python — readable, parameterized
.github/workflows/validate.yml
```

Kubernetes, multi-cloud, and generic PaaS blurbs are out of scope. AKS is an Azure option, not the story.

## How to use a lab

1. Read the lab README (decisions first, commands second).
2. Open the Terraform module it points at. Review `variables` and `outputs` before `main.tf`.
3. Run the script in `--what-if` / print-only mode. Apply in a **disposable** subscription only if you accept the cost.

VPN Gateway is **off by default**. It is slow to provision and bills even when idle.

```bash
# no Azure login required
python3 labs/03-terraform-modules/scripts/check_naming.py --self-test
python3 labs/05-monitor-ops/scripts/query_workspace.py --print-query failed-signins

# Terraform shape check (needs terraform >= 1.6)
cd terraform/lab
terraform init -backend=false
terraform validate
```

Apply path (optional, costs money):

```bash
cp terraform.tfvars.example terraform.tfvars   # fill subscription_id
terraform plan -out=lab.tfplan
# terraform apply lab.tfplan                   # only in a throwaway subscription
```

## Honest framing

- Patterns are aligned with hybrid identity and IaC work (nVent-style), not a dump of that employer’s configs.
- Default Conditional Access state is `disabled`. Enabling CA without a break-glass path locks people out.
- “90%+ SLA” on a resume is an **operations target**. Labs show the Monitor / IR / ticket discipline that supports it. They do not publish fake availability numbers.
- ServiceNow is the ITSM system of record in that work. It is documented, not simulated as a product lab.

## Prerequisites if you apply anything

- Azure subscription you can destroy
- Entra ID role that can read directory roles (Privileged Role Administrator / Global Reader for audits)
- Entra ID P1 if you want Conditional Access resources
- Terraform >= 1.6, Azure CLI, PowerShell 7 + `Az` / `Microsoft.Graph` modules
- Python 3.11+ (see [labs/05-monitor-ops/scripts/requirements.txt](labs/05-monitor-ops/scripts/requirements.txt) for optional query clients)
