terraform {
  #required_version = ">=0.12"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2.0"
    }
  }
  
    backend "azurerm" {
    /*
       ACCESS KEY AND OTHER SECRETS SHOULD BE ADDED TO VARIABLE GROUP IN AZDO LIBRARIES   
    */
    storage_account_name = "glbldvterraformstatesta" #"storage_account_name"
    container_name       = "terraformstate"          #"blob_container_name"
    #key                  = "sql_paas_state.tfstate"  #"state_file_name"
    #access_key            = var.access_key
    #sas_token             = var.sas_token
  } 
}

provider "azurerm" {
  features {}
  #subscription_id               = var.subscription_id
  #tenant_id                     = var.tenant_id
  #client_id		                 = var.client_id
  #client_certificate_path       = var.client_certificate_path
  #client_certificate_password   = var.cert_password
  #client_secret	               = var.client_secret
}

# Initializing and mapping var to local context
locals {
  mod_sql_name                  = var.sql_name
  mod_location                  = var.location
  mod_rg_name                   = var.resource_group_name
  mod_vnet_name                 = var.vnet_name
  mod_subnet_name               = var.subnet_name
  mod_subscription_name         = var.subscription_name
  #mod_public_access             = var.public_network_access_enabled
  mod_vCore                     = var.capacity
  mod_tier                      = var.tier
  mod_location_code             = var.location_code
  mod_environment               = var.environment
  mod_environment_code          = var.environment_code
  #mod_zone_redundant            = var.zone_redundant
  #mod_storage_account_type      = var.storage_account_type
  mod_pricing_tier              = var.pricing_tier
  mod_data_max                  = var.data_max
  mod_solution_name             = var.solution_name
  mod_vnet_rgname               = var.vnet_rgname
  mod_db_name                   = var.db_name
  }

##############################################################################################################
# Create MSSQL Password
resource "random_string" "mssql_password" {
  length           = 16
  special          = true
  override_special = "_%@$"
  min_lower        = 4
  min_upper        = 4
  min_numeric      = 4
}

################################################################################################
# Get Subnet Id 
data "azurerm_subnet" "tfsubnet" {
  name                 = local.mod_subnet_name
  virtual_network_name = local.mod_vnet_name
  resource_group_name  = local.mod_vnet_rgname
}

##################################################################################################
# Getting object id for an given AD group 
data "azuread_group" "sqlpaastest" {
display_name = "sqlpaastest"
security_enabled = true
}

##############################################################################################################
# Create Database Server
resource "azurerm_mssql_server" "tfmssqlsvr" {
  name                          = local.mod_sql_name
  #name                           = "glbl-${lookup(local.mod_environment_code,local.mod_environment,"No environment code found")}-${local.mod_sql_name}-${lookup(local.mod_location_code,local.mod_location,"No location code found")}-sqs"
  location                       = local.mod_location
  resource_group_name            = local.mod_rg_name
  #administrator_login           = "mssqladmin"
  #administrator_login_password  = random_string.mssql_password.result
  version                        = "12.0"
  minimum_tls_version            = "1.2"
  azuread_administrator {
  azuread_authentication_only    = "true"
  login_username                 = "sqlpaastest"
  object_id                      = data.azuread_group.sqlpaastest.id
  }
  #public_network_access_enabled  = local.mod_public_access
  lifecycle {
    create_before_destroy        = true
  }
  tags = {
    solution_name = local.mod_solution_name
    mode_of_deployment    = "iac"
  }
}

##############################################################################################################
# create elastic pool
resource "azurerm_mssql_elasticpool" "tfelasticpool" {
  resource_group_name = local.mod_rg_name
  name                = replace(local.mod_sql_name,"sqs","epool")
  #name                = "${local.mod_sql_name}-epool"
  #name                = "glbl-${lookup(local.mod_environment_code,local.mod_environment,"No environment code found")}-${local.mod_sql_name}-${lookup(local.mod_location_code,local.mod_location,"No location code found")}-sqp"
  location            = local.mod_location
  server_name         = azurerm_mssql_server.tfmssqlsvr.name
  license_type        = "BasePrice"
  max_size_gb         = local.mod_data_max
  sku {
      name = local.mod_pricing_tier
      tier =  local.mod_tier
      family = "Gen5"
      capacity = local.mod_vCore
  }
  per_database_settings {
    min_capacity = 0
    #max_capacity = local.mod_vCore
    max_capacity = 1
  }
  zone_redundant            = true 
}

##############################################################################################################
# Create Database Instance
resource "azurerm_mssql_database" "tfmssqlinst" {
  #name = "${local.mod_sql_name}-sqd"
  #resource_group_name = local.mod_rg_name
  #location            = local.mod_location
  for_each = local.mod_db_name
  name                        =each.value
  #name                        = "glbl-${lookup(local.mod_environment_code,local.mod_environment,"No environment code found")}-${local.mod_sql_name}-${lookup(local.mod_location_code,local.mod_location,"No location code found")}-sqd"
  #name                        = "glbl-${lookup(local.mod_environment_code,local.mod_environment,"No environment code found")}-${each.value}-${lookup(local.mod_location_code,local.mod_location,"No location code found")}-sqd"
  server_id                   = azurerm_mssql_server.tfmssqlsvr.id
  collation                   ="SQL_Latin1_General_CP1_CI_AS"
  sku_name                    ="ElasticPool"
  elastic_pool_id             = azurerm_mssql_elasticpool.tfelasticpool.id
  zone_redundant              = true 
  storage_account_type        = "ZRS" 
  tags = {
    solution_name = local.mod_solution_name
    mode_of_deployment    = "iac"
  } 
}

##############################################################################################################
# Create private endpoint
resource "azurerm_private_endpoint" "tfprivateendpoint" {
  name                = replace(local.mod_sql_name,"sqs","pe")
  #name                = "${local.mod_sql_name}-pe"
  #name                ="glbl-${lookup(local.mod_environment_code,local.mod_environment,"No environment code found")}-${local.mod_sql_name}-${lookup(local.mod_location_code,local.mod_location,"No location code found")}-pep"
  location            = local.mod_location
  resource_group_name = local.mod_rg_name
  subnet_id           = data.azurerm_subnet.tfsubnet.id
  private_service_connection {
    #name                           = "${local.mod_sql_name}-pec"
    name                           = replace(local.mod_sql_name,"sqs","pec")
    private_connection_resource_id = azurerm_mssql_server.tfmssqlsvr.id
    subresource_names              = [ "sqlServer" ]
    is_manual_connection           = false
  }
}


##############################################################################################################
# Enable Firewall
/*resource "azurerm_sql_firewall_rule" "tfmssql-firewall" {
  #name                = "${local.mod_sql_name}-mssql-firewall"
  count                = local.mod_public_access ? 1 : 0
  name                 ="glbl-${lookup(local.mod_environment_code,local.mod_environment,"No environment code found")}-${local.mod_sql_name}-${lookup(local.mod_location_code,local.mod_location,"No location code found")}-firewall-afw"  
  resource_group_name = local.mod_rg_name
  server_name         = azurerm_mssql_server.tfmssqlsvr.name
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
