# Cert and skill map

These labs are written against the skills measured by **AZ-104** (Administrator) and **AZ-305** (Solutions Architect), plus the hybrid / identity / IaC work on the resume. They are not exam dumps.

| Lab | AZ-104 (do the work) | AZ-305 (design the work) | Resume stack |
| --- | --- | --- | --- |
| 01 Identity | Manage Entra users/groups, assign Azure RBAC, review CA | Design identity, governance, least-privilege access | Entra ID, Conditional Access, identity hygiene |
| 02 Hybrid | Implement VNet, VPN Gateway, DNS, hybrid name resolution | Choose S2S vs ExpressRoute, hub layout, DNS strategy | Hybrid cloud, VPN, on-prem prefixes |
| 03 Terraform modules | Deploy and configure resources repeatably | Standardize landing-zone style building blocks | Terraform + Python checks in a pipeline |
| 04 Networking | NSGs, DNS zones, Network Watcher, VPN diagnostics | Segment networks, map VLANs to subnets, endpoint path | DNS, DHCP (platform), firewalls, VLANs |
| 05 Monitor / ops | Azure Monitor, Log Analytics, alerts, activity logs | Design monitoring, ops procedures, reliability mindset | Azure Monitor, IR docs, SLA discipline |

## What I am not mapping

- AZ-400 / Jenkins / generic CI product tours
- Multi-cloud landing zones (AWS/GCP)
- AKS as the primary architecture (it remains an optional compute platform)
- Invented production KPIs

Administrator work is “can I implement and operate this safely.” Architect work is “why this control, this scope, this blast radius.” Each lab README calls out both.
