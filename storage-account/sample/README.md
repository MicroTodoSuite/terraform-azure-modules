# storage-account sample

Creates one encrypted, Entra-only account named `lexmtsfprdstsample` with a
private container, using local state. The account carries `prevent_destroy`,
so remove the lifecycle block in a scratch copy before destroying the sample.
Fill the subscription, an existing resource group, and your public address in
`terraform.tfvars` first:

```bash
terraform init
terraform plan
```
