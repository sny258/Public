output "azure_vnet_id" {
    value = var.tags == "Prod" ? azurerm_virtual_network.vnet[0].id : ""
    description = "Vnet ID"
}
