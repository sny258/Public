variable "location" {
  description = "The location/region where the virtual network is created. Changing this forces a new resource to be created."
  default     = "East US"
}
variable "resource_group_name" {
  description = "The name of the resource group in which the resources will be created"
  default     = "terraform-rg"
}
variable "tags" {
  description = "tags to be associated with VM"
  default     = "dev"
}
variable "admin_pass" {
  description = "Admin password"
  default     = "Pass123$$"
}
variable "app_service_plan_name" {
  default     = "asp-sanju"
  description = "The name of the app service plan"
}
variable "app_service_name_prefix" {
  default     = "appsvc-sanju"
  description = "The beginning part of the app service name"
}