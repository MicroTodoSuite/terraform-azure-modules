# Outputs that prove the sample works.
output "container_registry_endpoint" {
  description = "Login server of the sample registry."
  value       = module.container_registry.container_registry_endpoint
}
