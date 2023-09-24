resource "azurerm_resource_group" "vnet_rg" {
  name     = var.resourcegroup_name
  location = var.location
  tags     = {
    environment  = var.tags
  }
}

resource "azurerm_virtual_network" "vnet" {
  count = var.tags == "Prod" ? 1 : 0
  name                = var.vnet_name
  address_space       = var.vnet_address_space
  location            = azurerm_resource_group.vnet_rg.location
  resource_group_name = azurerm_resource_group.vnet_rg.name
  tags     = {
      environment  = var.tags
    }
}
