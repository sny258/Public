variable "location" {
  description = "The location/region where the virtual network is created. Changing this forces a new resource to be created."
  default     = "East US"
}
variable "resource_group_name" {
  description = "The name of the resource group in which the resources will be created"
  default     = "terraform-rg"
}
variable "vm_hostname" {
  description = "local name of the VM"
  default     = "tfVM"
}
# variable "vnet_name" {
#   description = "The name of the virtual network be created"
#   default     = "VMvnet"
# }
# variable "subnet_name" {
#   description = "The name of the dubnet to be created"
#   default     = "VMsubnet"
# }
# variable "nic_name" {
#   description = "The name of the network interface card to be created"
#   default     = "VMnic"
# }
variable "tags" {
  description = "tags to be associated with VM"
  default     = "dev"
}
variable "admin_pass" {
  description = "Admin password"
  default     = "Pass123$$"
}