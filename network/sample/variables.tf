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

variable "address_space" {
  type        = string
  description = "Address space of the sample VNet."
}

variable "node_subnet_prefix" {
  type        = string
  description = "Range of the sample node subnet."
}

variable "reserved_cidrs" {
  type        = list(string)
  description = "Networks the sample VNet must not overlap."
}
