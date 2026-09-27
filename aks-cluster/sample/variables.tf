# Inputs of the sample.

variable "client" {
  type        = string
  description = "Client code."
}

variable "project" {
  type        = string
  description = "Project code."
}

variable "environment" {
  type        = string
  description = "Environment code."
}

variable "subscription_id" {
  type        = string
  description = "Azure subscription of the sample; empty in terraform.tfvars, where the operator supplies it."
}

variable "location" {
  type        = string
  description = "Azure region of the sample."
}

variable "resource_group_name" {
  type        = string
  description = "Existing resource group of the sample; empty in terraform.tfvars, where it is looked up (PC-IAC-026)."
}

variable "cluster_identity_id" {
  type        = string
  description = "Existing control-plane identity of the sample."
}

variable "kubelet_identity" {
  type = object({
    id        = string
    client_id = string
    object_id = string
  })
  description = "Existing kubelet identity of the sample."
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
  description = "Existing subnet and the ranges of the sample."
}

variable "operator_cidrs" {
  type        = list(string)
  description = "Operator /32 addresses for the sample API server."
}

variable "admin_group_object_ids" {
  type        = set(string)
  description = "Entra groups that administer the sample cluster."
}
