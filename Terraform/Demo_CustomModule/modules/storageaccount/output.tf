output "storageid" {
  description = "This is the id of the provisioned storage accoutn"
  value = azurerm_storage_account.sanjustorage.id
}

output "StorageTier" {
  description = "The tier of the storage account"
  value = azurerm_storage_account.sanjustorage.access_tier
}