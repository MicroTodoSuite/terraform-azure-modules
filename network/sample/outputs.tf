# Outputs that prove the sample works.
output "subnet_ids" {
  description = "Resource IDs of the sample subnets."
  value       = module.network.subnet_ids
}
