variable "resourcegroup_name" {
  type        = string
  description = "The name of the resource group"
  default     = "rg1"
}

variable "location" {
  type        = string
  description = "The region for the deployment"
  default     = "westus"
}

variable "tags" {
  description = "Tags used for the deployment"
  default =  "Prod"
  #default =  "Dev"
}

variable "vnet_name" {
  type        = string
  description = "The name of the vnet"
  default     = "vnet1"
}

variable "vnet_address_space" {
  type        = list(any)
  description = "the address space of the VNet"
  default     = ["10.13.0.0/16"]
}
