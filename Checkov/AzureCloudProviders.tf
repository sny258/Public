terraform {
  required_version = ">0.12"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>2.0"
    }
  }
  #backend "azurerm" {
    #storage_account_name   = "xxxxxxxxxxxxxxx"       	#"storage_account_name"
    #container_name         = "xxxxxxxxxxxxxx"                	#"blob_container_name"
    #key                    = "state.tfstate1"       	#"state_file_name"
    #access_key             = "xxxx-xxxx-xxxx"			            #var.access_key
    #sas_token              = var.sas_token
  #}
}

provider "azurerm" {
  features {}
  #subscription_id = "xxxx-xxxx-xxxx-xxxx"                         #var.subscription_id
  #tenant_id       = "xxxx-xxxx-xxxx-xxxx"                         #var.tenant_id
  #client_id       = "xxxx-xxxx-xxxx-xxxx"                         #var.client_id
  #client_certificate_path       = "C:\\Cert\\spncert.pfx"				#var.client_certificate_path
  #client_certificate_password   = "xxxxxxxxxxx"					    #var.cert_password
  #client_secret   = "xxxx-xxxx-xxxx-xxxx"                         #var.client_secret
}