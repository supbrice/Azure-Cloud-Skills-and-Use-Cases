# Lab 01 — Identity, Conditional Access, RBAC

**AZ-104:** manage Entra groups, review CA, assign Azure RBAC  
**AZ-305:** design least privilege, privileged access, identity governance  
**Resume:** Entra ID, access controls, identity hygiene

## The problem this lab is for

Hybrid estates fail more often on **standing privilege** than on missing VMs. Owner at subscription, Global Administrator without PIM, and Conditional Access with no break-glass account are the usual findings.

This lab shows a reviewer:

1. A custom Azure role that is *not* Contributor.
2. Assignment to an Entra **group**, not a person.
3. A Conditional Access policy that is created **disabled**.
4. Scripts that list standing privilege so you can argue about it.

## What to read

| Artifact | Why |
| --- | --- |
| [terraform/modules/identity-rbac](../../terraform/modules/identity-rbac) | Group + custom role + optional CA |
| [scripts/Audit-PrivilegedAccess.ps1](scripts/Audit-PrivilegedAccess.ps1) | Graph audit of directory roles and guests |
| [scripts/export-standing-rbac.sh](scripts/export-standing-rbac.sh) | `az` export of Owner / User Access Admin |

Wired in [terraform/lab](../../terraform/lab) as `module.identity`. Scope is the **lab resource group**, not the subscription. That is intentional.

## Architect notes (not exam trivia)

- **Scope first.** Owner at `/subscriptions/<id>` is a finding. Contributor on a single RG is often acceptable for a workload team.
- **Groups, then roles.** Users join `LAB - Network Operators`. The custom role is assigned to the group.
- **CA is a lockout engine.** Default `state = "disabled"`. Exclude at least one break-glass cloud-only account *before* you ever set `enabled`.
- **PIM vs standing.** Terraform `azurerm_role_assignment` is standing access. Call that out in a design review. Eligible PIM assignments are the production pattern; this lab does not fake PIM.
- **Hygiene checks:** guest Global Admins, unused privileged roles, app registrations with `Directory.ReadWrite.All`. The PowerShell script covers the first two.

## Run the audit (read-only)

```powershell
# PowerShell 7
Install-Module Microsoft.Graph.Identity.DirectoryManagement, Microsoft.Graph.Groups -Scope CurrentUser
Connect-MgGraph -Scopes "RoleManagement.Read.Directory", "User.Read.All", "Group.Read.All"
./scripts/Audit-PrivilegedAccess.ps1 -OutputPath ./privileged-audit.csv
```

```bash
az login
az account set --subscription "$SUBSCRIPTION_ID"
./scripts/export-standing-rbac.sh --subscription "$SUBSCRIPTION_ID"
```

Neither script changes the directory.

## Apply path (optional)

```bash
cd terraform/lab
# enable_conditional_access = true only if you have Entra ID P1
terraform plan
```

Cleanup: `terraform destroy` in the same directory. CA objects are destroyed with the module if you created them.

## Honest limits

- No live PIM catalog, access reviews, or entitlement management in this repo.
- CA grant is MFA only — not device compliance or named locations. Add those in the tenant after you have inventory.
- Custom role actions are a **starting set** for network ops, not a signed-off enterprise catalog.
