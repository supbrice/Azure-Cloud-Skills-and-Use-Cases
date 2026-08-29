# Lab 03 — Terraform module patterns

**AZ-104:** deploy resources consistently  
**AZ-305:** landing-zone style building blocks, repeatable environments  
**Resume:** Terraform + Python (and PowerShell) around IaC

## The problem this lab is for

Copy-pasted `azurerm_virtual_network` blocks drift. A module with **validated names**, **explicit subnet maps**, and **NSG profiles** is how I keep lab / dev / later prod from becoming three different networks.

This is not a claim that these modules are a Microsoft Cloud Adoption Framework landing zone. They are the pattern I want a reviewer to read.

## Layout

```text
terraform/
  modules/
    spoke-network/     # VNet, subnets, NSG profiles
    identity-rbac/     # Entra group, custom role, optional CA
    hybrid-gateway/    # optional, expensive
    monitoring/        # LAW, action group, NSG diagnostics, one alert
  lab/                 # one disposable composition
```

Root [terraform/lab/versions.tf](../../terraform/lab/versions.tf) pins `azurerm ~> 4.0` and `azuread ~> 3.0`, requires `subscription_id`, and documents an **azurerm backend** you should use in a pipeline (local state is the lab default).

## Patterns I want noticed

1. **Composition, not a mega-module.** Hub network, identity, and monitor are separate. VPN is `count` gated.
2. **Profiles instead of 40 NSG variables.** `nsg_profile = "identity" | "app" | "gateway"`.
3. **GatewaySubnet cannot have an NSG.** The module refuses to attach one.
4. **Sensitive values** (`vpn_shared_key`) are marked `sensitive`. `*.tfvars` is gitignored; only `*.tfvars.example` is committed.
5. **Python in the pipeline** — naming convention check that runs **without** Azure.

## Naming check (no Azure)

Convention: `{env}-{region}-{role}` with a short catalog of roles.

```bash
python3 scripts/check_naming.py --self-test
python3 scripts/check_naming.py lab-eus-hub-vnet
python3 scripts/check_naming.py --file names.txt
```

CI runs the self-test in [.github/workflows/validate.yml](../../.github/workflows/validate.yml).

## Pipeline shape

This GitHub repo validates `fmt` + `validate` + Python. A production pipeline I would run at work looks like:

1. `terraform fmt -check` / `check_naming.py`
2. `terraform plan` against remote state (OIDC to Azure, not a PAT in a variable group)
3. Human approval
4. `terraform apply`
5. PowerShell or `az` smoke (VPN status, diagnostic settings present)

An Azure DevOps sketch lives in [azure-pipelines.validate.yml](azure-pipelines.validate.yml). It does **not** apply.

## Honest limits

- No module registry, no workspaces-as-environments, no full policy-as-code library.
- `terraform validate` does not prove the tenant will accept CA or VPN SKUs.
- Bicep is on the resume; this lab is Terraform-first so the IaC story stays one language.
