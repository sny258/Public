module "vnetNew" {
  source  = "Azure/vnet/azurerm"
  version = "2.6.0"
  resource_group_name = "TerraformRG"
  vnet_location  = "East US"
  address_space = ["180.0.0.0/16"]
  subnet_prefixes = ["180.0.1.0/24","180.0.2.0/24"]
  subnet_names = ["devsubnet","testsubnet"]

  tags = {
      env = "dev"
      team = "frontend"
  }
}

