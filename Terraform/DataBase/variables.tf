variable "location" {
  description = "The location/region where the virtual network is created. Changing this forces a new resource to be created."
  default     = "East US"
}
variable "resource_group_name" {
  description = "The name of the resource group in which the resources will be created"
  default     = "terraform-rg"
}
variable "sql_name" {
    description = "SQL Name"
    default = "sqlpaastest77"
}
variable "tags" {
  description = "tags to be associated with VM"
  default     = "dev"
}
variable "admin_pass" {
  description = "Admin password"
  default     = "Pass123$$"
}