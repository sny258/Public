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
}

# Initializing and mapping var to local context
locals {

  mod_location                  = var.location
  mod_rg_name                   = var.resource_group_name
  mod_vnet_name                 = var.vnet_name
  mod_subnet_name               = var.subnet_name
  mod_acrname                   = var.acr_name
  mod_dns_prefix                = var.dns_prefix
  mod_cluster_name              = var.cluster_name
  mod_agent_size                = var.agent_size
  mod_agent_count               = var.agent_count
  mod_subnet_rg                 = var.subnet_rg
  }

# Get Subnet Id 
data "azurerm_subnet" "tfsubnet" {
  name                 = local.mod_subnet_name
  virtual_network_name = local.mod_vnet_name
  resource_group_name  = local.mod_subnet_rg
}

##ACR Provisioning
resource "azurerm_container_registry" "acr" {
  name                     = local.mod_acrname
  resource_group_name      = local.mod_rg_name
  location                 = local.mod_location
  sku                      = "Premium"
  admin_enabled            = true
}

resource "azurerm_private_endpoint" "tfprivateendpoint" {
  name                = "${local.mod_acrname}-pep"
  location            = local.mod_location
  resource_group_name = local.mod_rg_name
  subnet_id           = data.azurerm_subnet.tfsubnet.id

  private_service_connection {
    name                           = "${local.mod_acrname}-pec"
    private_connection_resource_id = azurerm_container_registry.acr.id
    subresource_names              = [ "registry" ]
    is_manual_connection           = false
  }
}
// data "azurerm_key_vault" "akv" {
//   name                = "akssshkey" // KeyVault name
//   resource_group_name = "emna-dv-iac-agentpool-rgp" // resourceGroup
// }


// data "azurerm_key_vault_secret" "kvsecret" {
// name = "publickey" // Name of secret
// key_vault_id = data.azurerm_key_vault.akv.id
// }

#aks
resource "azurerm_kubernetes_cluster" "aks" {
  location            = local.mod_location
  name                = local.mod_cluster_name
  resource_group_name = local.mod_rg_name
  dns_prefix          = local.mod_dns_prefix
  kubernetes_version  = "1.24.6"

  #private_cluster_enabled = true

  default_node_pool {
    name       = "agentpool"
    vm_size    = local.mod_agent_size
    node_count = local.mod_agent_count
    type       = "VirtualMachineScaleSets"
    enable_auto_scaling = false
    vnet_subnet_id = data.azurerm_subnet.tfsubnet.id
  }

   windows_profile {
     admin_username    = "winadmin"
     admin_password    = "windowsadmin@123"
   }

  linux_profile {
    admin_username = "ubuntu"
    ssh_key {
            #key_data = data.azurerm_key_vault_secret.kvsecret.value
            key_data = var.ssh_key
        }
    }

  identity {
    type = "SystemAssigned"           #only one of `identity,service_principal` can be specified
  }

  network_profile {
    load_balancer_sku = "Standard"
    network_plugin    = "azure"
  }

  # service_principal {
  #   client_id     = var.aks_service_principal_app_id
  #   client_secret = var.aks_service_principal_client_secret
  # }

  #role_based_access_control_enabled = true
    depends_on = [
    azurerm_private_endpoint.tfprivateendpoint
  ]
  
}

resource "azurerm_role_assignment" "akstoacr" {
  principal_id                     = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                            = azurerm_container_registry.acr.id
  skip_service_principal_aad_check = true
  depends_on = [
    azurerm_private_endpoint.tfprivateendpoint,
    azurerm_container_registry.acr,
    azurerm_kubernetes_cluster.aks
  ]
}

resource "azurerm_kubernetes_cluster_node_pool" "example" {
   name                  = "windws"            # max characters allowed was 6
   kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
   vm_size               = "Standard_DS2_v2"
   node_count            = 1
   os_type               = "Windows"
   vnet_subnet_id = data.azurerm_subnet.tfsubnet.id
    depends_on = [
    azurerm_kubernetes_cluster.aks
  ]
 }
