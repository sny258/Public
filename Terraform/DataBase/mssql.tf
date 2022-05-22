terraform {
  #required_version = ">=0.12"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">2.0"
    }
  }
}

provider "azurerm" {
  features {}
}


# Initializing and mapping var to local context
locals {
  mod_sql_name      = var.sql_name
  mod_location      = var.location
  mod_tags          = var.tags
  mod_rg_name       = var.resource_group_name
  mod_vnet_name     = var.vnet_name
  mod_subnet_name   = var.subnet_name
}

##############################################################################################################
# Create MSSQL Password
resource "random_string" "mssql_password" {
  length            = 16
  special           = true
  override_special  = "_%@$"
  min_lower         = 4
  min_upper         = 4
  min_numeric       = 4
}

################################################################################################
# Get Subnet Id
data "azurerm_subnet" "tfsubnet" {
  name = local.mod_subnet_name
  virtual_network_name = local.mod_vnet_name
  resource_group_name = local.mod_rg_name
}

##############################################################################################################
# Create Database Server
resource "azurerm_mssql_server" "tfmssqlsvr" {
  name                          = local.mod_sql_name
  location                      = local.mod_location
  resource_group_name           = local.mod_rg_name
  administrator_login           = "mssqladmin"
  administrator_login_password  = random_string.mssql_password.result
  version                       = "12.0"
  public_network_access_enabled = false
  lifecycle  {
    create_before_destroy=true
    }
  tags                          = {
    environment = local.mod_tags
  }
}

##############################################################################################################
# Create Database Instance
resource "azurerm_mssql_database" "tfmssqlinst" {
  name                = "${local.mod_sql_name}-sqd"
  #resource_group_name = local.mod_rg_name
  #location            = local.mod_location
  server_id           = azurerm_mssql_server.tfmssqlsvr.id
  collation           = "SQL_Latin1_General_CP1_CI_AS"   
  sku_name            = "S0"
}

##############################################################################################################
# Create private endpoint
resource "azurerm_private_endpoint" "tfprivateendpoint" {
	name = "${local.mod_sql_name}-pe"
  location = local.mod_location
  resource_group_name = local.mod_rg_name
  subnet_id = data.azurerm_subnet.tfsubnet.id
  private_service_connection {
  name = "${local.mod_sql_name}-psc"
  private_connection_resource_id = azurerm_mssql_server.tfmssqlsvr.id
  subresource_names              = [ "sqlServer" ]
  is_manual_connection = false
  }
}


##############################################################################################################
# Enable Firewall
/*resource "azurerm_sql_firewall_rule" "tfmssql-firewall" {
  name                = "${local.mod_sql_name}-mssql-firewall"
  resource_group_name = "${local.mod_rg_name}"
  server_name         = "${azurerm_sql_server.tfmssqlsvr.name}"
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"
}*/

##############################################################################################################
# Enable VNet restrictions
/*resource "azurerm_sql_virtual_network_rule" "mssql-snet-control" {
  name                = "${local.mod_sql_name}-vnet-rule"
  resource_group_name = "${local.mod_rg_name}"
  server_name         = "${azurerm_sql_server.tfmssqlsvr.name}"
  subnet_id           = "${data.azurerm_subnet.tfsubnet.id}"
  depends_on          = [azurerm_sql_server.tfmssqlsvr]
}*/
