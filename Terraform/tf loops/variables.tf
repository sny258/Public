variable "resourcegroup_name" {
  type        = string
  description = "The name of the resource group"
  default     = "rg1"
}

variable "location" {
  type        = string
  description = "The region for the deployment"
  default     = "westus"
}

variable "tags" {
  type        = map(string)
  description = "Tags used for the deployment"
  default = {
    "Environment" = "Lab"
    "Owner"       = "sanju"
  }
}

variable "vnet_name" {
  type        = string
  description = "The name of the vnet"
  default     = "vnet1"
}

variable "vnet_address_space" {
  type        = list(any)
  description = "the address space of the VNet"
  default     = ["10.13.0.0/16"]
}

# variable "subnets" {
#   type = map(any)
#   default = {
#     subnet_1 = {
#       name             = "subnet_1"
#       address_prefixes = ["10.13.1.0/24"]
#     }
#     subnet_2 = {
#       name             = "subnet_2"
#       address_prefixes = ["10.13.2.0/24"]
#     }
#     subnet_3 = {
#       name             = "subnet_3"
#       address_prefixes = ["10.13.3.0/24"]
#     }
#   }
# }

# variable "subnets" {
#   type = set(string)
#   default = ["10.13.1.0/24", "10.13.2.0/24", "10.13.3.0/24"]
# }

variable "subnets" {
  type = map(string)
  default = {
    subnet_1 = "10.13.1.0/24"
    subnet_2 = "10.13.2.0/24"
    subnet_3 = "10.13.3.0/24"    
  }
}
