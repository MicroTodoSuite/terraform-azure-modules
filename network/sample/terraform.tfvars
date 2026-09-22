# Example configuration of the sample. Names are built in locals.tf (PC-IAC-026).
client              = "lex"
project             = "mts"
environment         = "fprd"
subscription_id     = ""
location            = "eastus2"
resource_group_name = ""
address_space       = "10.70.0.0/16"
node_subnet_prefix  = "10.70.0.0/22"
reserved_cidrs      = ["10.10.0.0/16", "10.20.0.0/16", "10.30.0.0/16", "10.40.0.0/16", "10.50.0.0/16"]
