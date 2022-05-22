# Create MSSQL Password
# resource "random_string" "sql_password" {
#   length            = 16
#   special           = true
#   override_special  = "_%@$"
#   min_lower         = 4
#   min_upper         = 4
#   min_numeric       = 4
# }

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_mssql_server" "server" {
  name                         = var.sql_name
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = var.location
  version                      = "12.0"
  administrator_login          = "AdminUser"
  #administrator_login_password = random_string.sql_password.result
  administrator_login_password = var.admin_pass
}

resource "azurerm_mssql_database" "database" {
  name           = "${var.sql_name}-db"
  server_id      = azurerm_mssql_server.server.id
  collation      = "SQL_Latin1_General_CP1_CI_AS"
  sku_name       = "S0"
}