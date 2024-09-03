######### Region & Network Vars #########
# variable "region" {
#   type        = string
#   default     = "eu-central-1"
# }

# VPC, subnets and NAT gateway details
variable "vpc_required" {
  type    = bool
  default = true
}

variable "vpc_details" {
  type = map
  default = {
    vpc_name = "GWL-Lab-Integration-VPN"
    vpc_cidr = "10.33.4.0/22"
  }
}


#Public subnet details
variable "pub_sub_required" {
  type    = bool
  default = true
}

variable "pub_sub_details" {
  type = list(object({
    cidr    = string
    name    = string
    az      = string
  }))
  default = [
    {
      cidr  = "10.33.4.0/26"
      name  = "GWL-lab-integration-vpn-public-subnet-1"
      az    = "eu-central-1a"
    },
    {
      cidr  = "10.33.4.64/26"
      name  = "GWL-lab-integration-vpn-public-subnet-2"
      az    = "eu-central-1b"
    }
  ]
}

variable "igw_name" {
  description = "Internet Gateway name"
  default     = "GWL-lab-integration-vpn-internet-gateway"
}

variable "pub_sub_rt_name" {
  description = "Public subnet's route table name"
  default     = "GWL-lab-integration-vpn-public-route-table"
}


##Private subnet details
variable "prv_sub_required" {
  type    = bool
  default = true
}

variable "prv_sub_details" {
  type = list(object({
    cidr    = string
    name    = string
    az      = string
  }))
  default = [
    {
      cidr  = "10.33.5.0/24"
      name  = "GWL-lab-integration-vpn-EKS-subnet-1"
      az    = "eu-central-1a"
    },
    {
      cidr  = "10.33.6.0/23"
      name  = "GWL-lab-integration-vpn-EKS-subnet-2"
      az    = "eu-central-1b"
    }
  ]
}


##If public subnet is not required or If public subnet is required but not private then NAT can't be created !!!
#NAT gateway details
variable "nat_required" {
  type    = bool
  default = true
}  

variable "private_subnet_details" {
  type    = map
  default = {}
}

variable "public_subnet_details" {
  type    = map
  default = {}
}

variable "nat_details" {
  type = list(object({
    create_eip         = bool              #nat_required will override it
    eip_allocation_id  = string
    nat_name           = string
    nat_pub_subnet     = string
    nat_rt_name        = string
    nat_prv_subnet     = list(string)
  }))
  default = [
    {
      create_eip         = true
      eip_allocation_id  = "eipalloc-0aeac40406b4bd9d9"       #"3.72.164.102"
      nat_name           = "GWL-lab-integration-vpn-natgateway"
      nat_pub_subnet     = "GWL-lab-integration-vpn-public-subnet-2"
      nat_rt_name        = "GWL-lab-integration-vpn-NAT-Routetable"
      nat_prv_subnet     = ["GWL-lab-integration-vpn-EKS-subnet-1","GWL-lab-integration-vpn-EKS-subnet-2"]
    },
    # {
    #   create_eip         = true
    #   eip_allocation_id  = "eipalloc-0aeac40406b4bd9d9"       #"3.72.164.102"
    #   nat_name           = "terraform-nat-1b"
    #   nat_pub_subnet     = "terraform-public-subnet-1b"
    #   nat_rt_name        = "terraform-nat-rt-1b"
    #   nat_prv_subnet     = ["terraform-private-subnet-1b"]
    # },
  ]
}




#VPC private endpoint details
variable "vpc_endpoint_required" {
  type    = bool
  default = true
}

variable "endpoint_vpc_details" {
  type = object({
    vpc_id            = string
    subnet_ids        = list(string)
    vpc_cidr          = string
    security_group_id = string
    route_table_id    = string
  })
  default = {
      vpc_id            = "vpc-xxxxx"
      subnet_ids        = ["subnet-xxxxx", "subnet-xxxxx"]
      vpc_cidr          = "10.0.0.0/16"
      security_group_id = "sg-xxxxx"
      route_table_id    = "rtb-xxxxx"
  }
} 

variable "vpc_private_endpoints" {
  type = list(object({
    endpoint_type     = string
    endpoint_name     = string
    service_name      = string
  }))
  default = [
    {
      endpoint_type     = "Interface"
      endpoint_name     = "GWL-lab-integration-vpn-vpc-endpoint-ecr-api"
      service_name      = "com.amazonaws.eu-central-1.ecr.api"  
    },
    {
      endpoint_type     = "Interface"
      endpoint_name     = "GWL-lab-integration-vpn-vpc-endpoint-ecr-dkr"
      service_name      = "com.amazonaws.eu-central-1.ecr.dkr"
    },
    {
      endpoint_type  = "Gateway"
      endpoint_name  = "GWL-lab-integration-vpn-vpc-endpoint-s3"
      service_name   = "com.amazonaws.eu-central-1.s3"
    }
  ]
}
