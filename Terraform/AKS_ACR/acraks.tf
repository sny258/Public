terraform {
  #required_version = ">=0.12"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2.0"
    }
  }
  
    #backend "azurerm" {
    #storage_account_name = "glblprterraformstatesta" #"storage_account_name"
    #container_name       = "state"          #"blob_container_name"
    #key                  = "sql_paas_state.tfstate"  #"state_file_name"
    #access_key            = var.access_key
    #sas_token             = var.sas_token
  #} 
}

provider "azurerm" {
  features {}
}


# Get Subnet Id 
data "azurerm_subnet" "tfsubnet" {
  name                 = var.subnet_name
  virtual_network_name = var.vnet_name
  resource_group_name  = var.subnet_rg
}

##ACR Provisioning
resource "azurerm_container_registry" "acr" {
  name                     = var.acr_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  sku                      = "Premium"
  admin_enabled            = true
}

resource "azurerm_private_endpoint" "tfprivateendpoint" {
  name                = "${var.acr_name}-pep"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = data.azurerm_subnet.tfsubnet.id

  private_service_connection {
    name                           = "${var.acr_name}-pec"
    private_connection_resource_id = azurerm_container_registry.acr.id
    subresource_names              = [ "registry" ]
    is_manual_connection           = false
  }
}

#aks
resource "azurerm_kubernetes_cluster" "aks" {
  location            = var.location
  name                = var.cluster_name
  resource_group_name = var.resource_group_name
  dns_prefix          = var.dns_prefix
  kubernetes_version  = "1.24.0"

  #private_cluster_enabled = true

  default_node_pool {
    name       = "agentpool"
    vm_size    = var.agent_size
    node_count = var.agent_count
    type       = "VirtualMachineScaleSets"
    enable_auto_scaling = false
    #vnet_subnet_id = data.azurerm_subnet.tfsubnet.id
  }

  # windows_profile {
  #   admin_username    = "winadmin"
  #   admin_password    = "windowsadmin@123"
  # }

  # linux_profile {
  #   admin_username = "ubuntu"
  #   ssh_key {
  #           key_data = file(var.ssh_public_key)
  #       }
  #   }

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
  
}

resource "azurerm_role_assignment" "akstoacr" {
  principal_id                     = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                            = azurerm_container_registry.acr.id
  skip_service_principal_aad_check = true
}

# resource "azurerm_kubernetes_cluster_node_pool" "example" {
#   name                  = "win2022"
#   kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
#   vm_size               = "Standard_DS2_v3"
#   node_count            = 2
#   os_type               = "Windows"
#   #orchestrator_version  = "1.24.0"
#   vnet_subnet_id = data.azurerm_subnet.tfsubnet.id
# }
