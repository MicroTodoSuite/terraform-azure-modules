# Example configuration of the sample. Names are built in locals.tf and IDs are
# looked up by the operator (PC-IAC-026).
client              = "lex"
project             = "mts"
environment         = "fprd"
subscription_id     = ""
location            = "eastus2"
resource_group_name = ""
cluster_identity_id = ""

kubelet_identity = {
  id        = ""
  client_id = ""
  object_id = ""
}

network = {
  subnet_id      = ""
  vnet_cidr      = "10.70.0.0/16"
  pod_cidr       = "192.168.0.0/16"
  service_cidr   = "172.16.0.0/16"
  dns_service_ip = "172.16.0.10"
  reserved_cidrs = ["10.10.0.0/16", "10.20.0.0/16", "10.30.0.0/16", "10.40.0.0/16", "10.50.0.0/16"]
}

operator_cidrs         = []
admin_group_object_ids = []
