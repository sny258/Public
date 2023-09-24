terraform {
  required_providers {
    azuredevops = {
      source  = "microsoft/azuredevops"
      version = ">=0.1.0"
    }
  }
}

provider "azuredevops" {
  org_service_url       = var.Azure_DevOps_Org_Url
  personal_access_token = var.Personal_Access_token
}

resource "random_pet" "name" {
}

resource "random_integer" "number" { 
  min = 10
  max = 20
}

resource "azuredevops_project" "project" {
  name               = "Terraform ${random_integer.number.result}"
  visibility         = "private"
  version_control    = "Git"
  work_item_template = "Basic"
}

resource "azuredevops_git_repository" "repo" {
  project_id = azuredevops_project.project.id
  name       = "Terraform ${random_pet.name.id} Git"
  initialization {
    init_type = "Clean"
  }
}
