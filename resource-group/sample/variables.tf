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
