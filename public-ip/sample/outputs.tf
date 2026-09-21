# Outputs that prove the sample works.
output "public_ip_dns_name" {
  description = "Provider FQDN of the sample address."
  value       = module.public_ip.public_ip_dns_name
}
