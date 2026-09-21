# Inputs of the aks-cluster module. The name arrives built by the root
# (PC-IAC-025); the subnet and identities arrive as IDs, because the cluster
# receives them and creates neither (PC-IAC-023). Two CIDR blocks overlap
# exactly when their network addresses, truncated to the shorter prefix, are
# equal; the range validations apply that test.

variable "client" {
  type        = string
  description = "Client code, from MTS-IAC-101."

  validation {
    condition     = can(regex("^[a-z0-9]{2,10}$", var.client))
    error_message = "The client code must be 2 to 10 lowercase letters or digits."
  }
}

variable "project" {
  type        = string
  description = "Project code, from MTS-IAC-101."

  validation {
    condition     = can(regex("^[a-z0-9]{2,15}$", var.project))
    error_message = "The project code must be 2 to 15 lowercase letters or digits."
  }
}

variable "environment" {
  type        = string
  description = "Environment code, from MTS-IAC-101."

  validation {
    condition     = contains(["shd", "eco", "fdev", "fstg", "fprd"], var.environment)
    error_message = "The environment must be one of shd, eco, fdev, fstg, or fprd."
  }
}

variable "cluster" {
  type = object({
    name                = string
    resource_group_name = string
    location            = string
    kubernetes_version  = string
  })
  description = "Standard name of the cluster, its resource group and programmatic region, and its Kubernetes version (the 1.35 minor, optionally with a patch)."

  validation {
    condition     = can(regex("^[a-z0-9]+(-[a-z0-9]+)*$", var.cluster.name)) && length(var.cluster.name) <= 28 && length(var.cluster.resource_group_name) > 0 && can(regex("^[a-z][a-z0-9]+$", var.cluster.location))
    error_message = "The cluster needs a standard name of at most 28 characters, a resource group, and a programmatic region name."
  }

  validation {
    condition     = can(regex("^1\\.35(\\.[0-9]+)?$", var.cluster.kubernetes_version))
    error_message = "The cluster must run Kubernetes 1.35 (gitops specs/009-full-platform-rollout research decision 9)."
  }
}

variable "identities" {
  type = object({
    cluster_identity_id = string
    kubelet = object({
      id        = string
      client_id = string
      object_id = string
    })
  })
  description = "The pre-created user-assigned identities the cluster runs as: the control plane's, and the kubelet's that pulls images. The control-plane identity needs Managed Identity Operator on the kubelet identity and Network Contributor on the node subnet."

  validation {
    condition     = alltrue([for id in [var.identities.cluster_identity_id, var.identities.kubelet.id] : can(regex("^/subscriptions/[0-9a-f-]{36}/resourceGroups/[^/]+/providers/Microsoft.ManagedIdentity/userAssignedIdentities/[^/]+$", id))])
    error_message = "The identities must be user-assigned managed identity resource IDs."
  }

  validation {
    condition     = alltrue([for id in [var.identities.kubelet.client_id, var.identities.kubelet.object_id] : can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", id))])
    error_message = "The kubelet identity's client and object IDs must be GUIDs."
  }
}

variable "network" {
  type = object({
    subnet_id      = string
    vnet_cidr      = string
    pod_cidr       = string
    service_cidr   = string
    dns_service_ip = string
    reserved_cidrs = list(string)
  })
  description = "The private node subnet, the address space of its VNet, the Azure CNI Overlay pod range, the service range and DNS address, and the connected networks (every AWS VPC) the pod and service ranges must not overlap."

  validation {
    condition     = can(regex("^/subscriptions/[0-9a-f-]{36}/resourceGroups/[^/]+/providers/Microsoft.Network/virtualNetworks/[^/]+/subnets/[^/]+$", var.network.subnet_id))
    error_message = "The node subnet must be a subnet resource ID."
  }

  validation {
    condition     = alltrue([for cidr in concat([var.network.vnet_cidr, var.network.pod_cidr, var.network.service_cidr], var.network.reserved_cidrs) : can(cidrhost(cidr, 0))])
    error_message = "The VNet, pod, service, and reserved ranges must be IPv4 CIDR blocks."
  }

  validation {
    condition     = try(!(cidrhost(format("%s/%d", split("/", var.network.pod_cidr)[0], min(tonumber(split("/", var.network.pod_cidr)[1]), tonumber(split("/", var.network.vnet_cidr)[1]))), 0) == cidrhost(format("%s/%d", split("/", var.network.vnet_cidr)[0], min(tonumber(split("/", var.network.pod_cidr)[1]), tonumber(split("/", var.network.vnet_cidr)[1]))), 0)) && alltrue([for reserved in var.network.reserved_cidrs : !(cidrhost(format("%s/%d", split("/", var.network.pod_cidr)[0], min(tonumber(split("/", var.network.pod_cidr)[1]), tonumber(split("/", reserved)[1]))), 0) == cidrhost(format("%s/%d", split("/", reserved)[0], min(tonumber(split("/", var.network.pod_cidr)[1]), tonumber(split("/", reserved)[1]))), 0))]), false)
    error_message = "The pod range must overlap neither the VNet nor any reserved network."
  }

  validation {
    condition     = try(!(cidrhost(format("%s/%d", split("/", var.network.service_cidr)[0], min(tonumber(split("/", var.network.service_cidr)[1]), tonumber(split("/", var.network.vnet_cidr)[1]))), 0) == cidrhost(format("%s/%d", split("/", var.network.vnet_cidr)[0], min(tonumber(split("/", var.network.service_cidr)[1]), tonumber(split("/", var.network.vnet_cidr)[1]))), 0)) && !(cidrhost(format("%s/%d", split("/", var.network.service_cidr)[0], min(tonumber(split("/", var.network.service_cidr)[1]), tonumber(split("/", var.network.pod_cidr)[1]))), 0) == cidrhost(format("%s/%d", split("/", var.network.pod_cidr)[0], min(tonumber(split("/", var.network.service_cidr)[1]), tonumber(split("/", var.network.pod_cidr)[1]))), 0)) && alltrue([for reserved in var.network.reserved_cidrs : !(cidrhost(format("%s/%d", split("/", var.network.service_cidr)[0], min(tonumber(split("/", var.network.service_cidr)[1]), tonumber(split("/", reserved)[1]))), 0) == cidrhost(format("%s/%d", split("/", reserved)[0], min(tonumber(split("/", var.network.service_cidr)[1]), tonumber(split("/", reserved)[1]))), 0))]), false)
    error_message = "The service range must overlap neither the VNet, the pod range, nor any reserved network."
  }

  validation {
    condition     = try(tonumber(split("/", "${var.network.dns_service_ip}/32")[1]) >= tonumber(split("/", var.network.service_cidr)[1]) && cidrhost(format("%s/%d", split("/", "${var.network.dns_service_ip}/32")[0], min(tonumber(split("/", "${var.network.dns_service_ip}/32")[1]), tonumber(split("/", var.network.service_cidr)[1]))), 0) == cidrhost(format("%s/%d", split("/", var.network.service_cidr)[0], min(tonumber(split("/", "${var.network.dns_service_ip}/32")[1]), tonumber(split("/", var.network.service_cidr)[1]))), 0) && var.network.dns_service_ip != cidrhost(var.network.service_cidr, 0), false)
    error_message = "The DNS service address must lie inside the service range and must not be its network address."
  }
}

variable "api_server_authorized_ip_ranges" {
  type        = list(string)
  description = "Operator addresses allowed to reach the public API server, each a /32 block."

  validation {
    condition     = length(var.api_server_authorized_ip_ranges) > 0 && alltrue([for cidr in var.api_server_authorized_ip_ranges : can(cidrhost(cidr, 0)) && endswith(cidr, "/32")])
    error_message = "The API allowlist must name at least one address, and only /32 blocks; 0.0.0.0/0 and ranges are refused."
  }
}

variable "system_node_pool" {
  type = object({
    vm_size   = string
    vcpus     = number
    min_count = number
    max_count = number
  })
  description = "Size and autoscaler bounds of the system node pool; vcpus is the vCPU count of vm_size, checked against the regional quota."

  validation {
    condition     = can(regex("^Standard_[A-Za-z0-9_]+$", var.system_node_pool.vm_size)) && var.system_node_pool.vcpus > 0 && var.system_node_pool.min_count >= 1 && var.system_node_pool.min_count <= var.system_node_pool.max_count
    error_message = "The node pool needs an Azure VM size, a positive vCPU count, and 1 <= min_count <= max_count."
  }

  validation {
    condition     = var.system_node_pool.max_count * var.system_node_pool.vcpus <= var.regional_vcpu_quota
    error_message = "The autoscaler's maximum must fit the regional vCPU quota (MTS-IAC-104)."
  }
}

variable "regional_vcpu_quota" {
  type        = number
  description = "The subscription's regional vCPU quota for the node VM family."

  validation {
    condition     = var.regional_vcpu_quota > 0
    error_message = "The regional vCPU quota must be positive."
  }
}

variable "admin_group_object_ids" {
  type        = set(string)
  description = "Entra group object IDs bound to cluster-admin; with local accounts disabled, they are the only way in."

  validation {
    condition     = length(var.admin_group_object_ids) > 0 && alltrue([for id in var.admin_group_object_ids : can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", id))])
    error_message = "Name at least one Entra admin group by object ID; with local accounts disabled, no one could reach the cluster otherwise."
  }
}

variable "additional_tags" {
  type        = map(string)
  description = "Tags added to the cluster besides the governance tags, such as Owner, CostCenter, and Repository."
  default     = {}

  validation {
    condition     = alltrue([for key in keys(var.additional_tags) : length(key) > 0 && key != "Name"])
    error_message = "Tag keys must not be empty and must not override Name."
  }
}
