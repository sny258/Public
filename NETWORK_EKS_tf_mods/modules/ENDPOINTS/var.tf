variable "vpc_id" {
  type    = string
  default = ""
}

variable "vpc_cidr" {
  type    = string
  default = ""
}

variable "security_group_id" {
  type    = string
  default = ""
}

variable "subnet_ids" {
  type    = list(string)
  default = []
}

variable "route_table_id" {
  type    = list(string)
  default = []
} 

variable "vpc_private_endpoints" {
  type = list(object({
    #required         = bool
    endpoint_type    = string
    endpoint_name    = string
    service_name     = string
  }))
  default = [
    {
      #required       = false
      endpoint_type  = ""
      endpoint_name  = ""
      service_name   = ""
    }
  ]
}
