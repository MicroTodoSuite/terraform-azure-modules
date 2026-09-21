# aks-cluster sample

Creates one single-node AKS 1.35 cluster named `lex-mts-fprd-aks-sample` with
local state, in an existing private subnet and with existing identities. Fill
the subscription, resource group, identities, subnet, your /32 address, and an
Entra admin group in `terraform.tfvars` first:

```bash
terraform init
terraform plan
```
