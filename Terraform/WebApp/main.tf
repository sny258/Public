variable "app_service_plan_name" {
  default     = "asp-sanju"
  description = "The name of the app service plan"
}

variable "app_service_name_prefix" {
  default     = "appsvc-sanju"
  description = "The beginning part of the app service name"
}

resource "random_integer" "app_service_name_suffix" {
  min = 1000
  max = 9999
}


resource "azurerm_app_service_plan" "lkm" {
  name                = var.app_service_plan_name
  location            = "East US"
  resource_group_name = "TerraformRG"
  kind                = "Linux"
  reserved            = true

  sku {
    tier = "Basic"
    size = "B1"
  }
}

resource "azurerm_app_service" "lkm" {
  name                = "${var.app_service_name_prefix}-${random_integer.app_service_name_suffix.result}"
  location            = "East US"
  resource_group_name = "TerraformRG"
  app_service_plan_id = azurerm_app_service_plan.lkm.id
}

output "website_hostname" {
  value       = azurerm_app_service.lkm.default_site_hostname
  description = "The hostname of the website"
}