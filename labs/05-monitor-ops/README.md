# Lab 05 — Monitor, Log Analytics, ops mindset

**AZ-104:** Azure Monitor, Log Analytics, alerts, activity log  
**AZ-305:** monitoring design, reliability operations  
**Resume:** Azure Monitor, incident docs, SLA *discipline* (not a fake 90% chart)

## The problem this lab is for

Identity and VPN labs are incomplete if nobody is paged. This lab wires:

- A Log Analytics workspace (30-day retention — a **cost** choice, not a compliance claim)
- NSG diagnostic settings
- One scheduled query alert on **failed Entra sign-ins**
- An action group that emails a mailbox you control

ServiceNow mapping (ticket fields, not an integration) lives in [docs/ops-itsm.md](../../docs/ops-itsm.md).

## What to read

| Artifact | Why |
| --- | --- |
| [terraform/modules/monitoring](../../terraform/modules/monitoring) | Workspace, action group, NSG diag, alert v2 |
| [queries/](queries/) | KQL you can paste in the portal or pass to the Python helper |
| [scripts/query_workspace.py](scripts/query_workspace.py) | Print KQL without Azure, or query with DefaultAzureCredential |
| [scripts/New-MonitorActionGroup.ps1](scripts/New-MonitorActionGroup.ps1) | Imperative alternative to the Terraform action group |

`SigninLogs` is empty until you send Entra diagnostic settings to the workspace. The alert is still a valid pattern.

## KQL

| File | Question |
| --- | --- |
| [failed-signins.kql](queries/failed-signins.kql) | Who is failing Entra sign-in, from where? |
| [vpn-and-nsg.kql](queries/vpn-and-nsg.kql) | Gateway / NSG counters (needs diagnostics) |
| [rbac-changes.kql](queries/rbac-changes.kql) | Who got Owner / UAA in Azure Activity |

```bash
# no Azure
python3 scripts/query_workspace.py --print-query failed-signins

# with az login / VS Code Azure / managed identity
python3 scripts/query_workspace.py \
  --workspace-id <workspace-guid> \
  --query-name rbac-changes
```

## SLA mindset (honest)

The resume target is **90%+** availability for the services I operated. A GitHub lab cannot prove that. What I *will* show a reviewer:

1. An alert that names a human mailbox
2. Queries that answer identity vs path vs RBAC change
3. A written handoff to ServiceNow ([docs/ops-itsm.md](../../docs/ops-itsm.md))

I will not put a Grafana-style “99.9%” badge on this README.

## Incident order I actually use

1. Is it identity (sign-in / CA) or path (VPN / DNS / NSG)?
2. Run Lab 01 audit or Lab 04 path checks — do not change both at once.
3. Open the ServiceNow ticket with the alert name and the KQL.
4. After restore: what control was missing (standing Owner, overlapping prefix, DNS on the VNet).

## Honest limits

- No Azure Workbooks JSON dump, no Sentinel analytics rules, no auto-created ServiceNow incidents.
- Failed-signin threshold (`25` / 15 minutes) is a **lab default**. Tune it or you will page on your own fat-finger MFA tests.
- Heartbeat-based availability for VMs is only useful if you deploy the agent. This composition does not deploy VMs.
