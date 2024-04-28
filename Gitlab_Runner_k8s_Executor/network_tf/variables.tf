######### Region & Network Vars #########
variable "location" {
  description = "The location/region where resources/infrastructure will be created."
  default     = "eu-west-1"
}

variable "vpc_details" {
  type = map
  default = {
    name = "gwl-gitlab-runners-vpc"
    cidr = "10.34.0.0/23"
  }
}

# variable "subnet_cidr" {
#   type = list(object({
#     cidr    = string
#     name    = string
#     az      = string
#   }))
#   default = [
#     {
#       cidr  = "10.34.0.0/25"
#       name  = "gwl-gitlab-runners-public-subnet1"
#       az    = "eu-west-1a"
#     },
#     {
#       cidr  = "10.34.1.0/25"
#       name  = "gwl-gitlab-runners-private-subnet1"
#       az    = "eu-west-1a"
#     },
#     {
#       cidr  = "10.34.0.128/25"
#       name  = "gwl-gitlab-runners-public-subnet2"
#       az    = "eu-west-1b"
#     },
#     {
#       cidr  = "10.34.1.128/25"
#       name  = "gwl-gitlab-runners-private-subnet2"
#       az    = "eu-west-1b"
#     }
#   ]
# }

# ##Getting Public subnet/s ID only for RT association
# locals {
#   public_subnet_a = join(",", [for name, sub in aws_subnet.subnet : sub.id if lookup(sub.tags, "Name", "") == "gwl-gitlab-runners-public-subnet1"])
#   public_subnet_b = join(",", [for name, sub in aws_subnet.subnet : sub.id if lookup(sub.tags, "Name", "") == "gwl-gitlab-runners-public-subnet2"])
#   private_subnet_a = join(",", [for name, sub in aws_subnet.subnet : sub.id if lookup(sub.tags, "Name", "") == "gwl-gitlab-runners-private-subnet1"])
#   private_subnet_b = join(",", [for name, sub in aws_subnet.subnet : sub.id if lookup(sub.tags, "Name", "") == "gwl-gitlab-runners-private-subnet2"])
# }


variable "public_subnet_cidr" {
  type = list(object({
    cidr    = string
    name    = string
    az      = string
  }))
  default = [
    {
      cidr  = "10.34.0.0/25"
      name  = "gwl-gitlab-runners-public-subnet1"
      az    = "eu-west-1a"
    },
    {
      cidr  = "10.34.0.128/25"
      name  = "gwl-gitlab-runners-public-subnet2"
      az    = "eu-west-1b"
    }
  ]
}

variable "igw_name" {
  description = "Internet Gateway name"
  default     = "gwl-gitlab-runners-vpc-igw"
}

variable "pub_sub_rt_name" {
  description = "Public subnet's route table name"
  default     = "gwl-gitlab-runners-pub-sub-rt"
}

variable "nat_details" {
  type = map
  default = {
    elastic_ip = "10.39.132.82/32"
    nat_name = "gwl-gitlab-runners-nat"
    nat_pub_subnet = "gwl-gitlab-runners-public-subnet1"
  }
}

variable "nat_rt_name" {
  description = "Public subnet's route table name"
  default     = "gwl-gitlab-runners-nat-rt"
}

variable "private_subnet_cidr" {
  type = list(object({
    cidr    = string
    name    = string
    az      = string
  }))
  default = [
    {
      cidr  = "10.34.1.0/25"
      name  = "gwl-gitlab-runners-private-subnet1"
      az    = "eu-west-1a"
    },
    {
      cidr  = "10.34.1.128/25"
      name  = "gwl-gitlab-runners-private-subnet2"
      az    = "eu-west-1b"
    }
  ]
}