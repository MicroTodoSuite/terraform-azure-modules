# container-registry sample

Creates one Standard registry named `lexmtsfprdacrsample` with local state. Its public endpoint is
on and it admits only Entra identities, with no admin user and no anonymous pull. Fill the
subscription and an existing resource group in `terraform.tfvars` first:

```bash
terraform init
terraform plan
```
