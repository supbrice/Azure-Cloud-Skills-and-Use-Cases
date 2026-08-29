# Terraform

Composition lives in [lab/](lab/). Modules are the Lab 03 artifacts.

| Module | Labs |
| --- | --- |
| [modules/spoke-network](modules/spoke-network) | 02, 03, 04 |
| [modules/identity-rbac](modules/identity-rbac) | 01, 03 |
| [modules/hybrid-gateway](modules/hybrid-gateway) | 02 (off by default) |
| [modules/monitoring](modules/monitoring) | 05 |

```bash
cd lab
cp terraform.tfvars.example terraform.tfvars
terraform init -backend=false
terraform validate
terraform plan
```
