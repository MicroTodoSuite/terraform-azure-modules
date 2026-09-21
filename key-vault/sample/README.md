# key-vault sample

Creates one empty, RBAC-only Key Vault named `lex-mts-fprd-kv-sample` with
local state. Purge protection means a destroyed sample vault keeps its name
reserved for the retention period. Fill the subscription, an existing resource
group, and your /32 address in `terraform.tfvars` first:

```bash
terraform init
terraform plan
```
