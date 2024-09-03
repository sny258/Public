
#Network details
variable "vpc_id" {
  type    = string
  default = ""
}

variable "private_subnet_details" {
  type    = map
  default = {}
}

variable "public_subnet_details" {
  type    = map
  default = {}
}

variable "main_route_table_id" {
  type    = string
  default = ""
}


#NAT gateway details
variable "nat_required" {
  type    = bool
  default = false
}   

variable "create_eip" {
  type    = bool
  default = false
} 

variable "eip_allocation_id" {
  type    = string
  default = ""
} 

variable "nat_name" {
  type    = string
  default = ""
}  

variable "nat_pub_subnet" {
  type    = string
  default = ""
}  

variable "nat_rt_name" {
  description = "Public subnet's route table name"
  default     = ""
}

variable "nat_prv_subnet" {
  type    = list(string)
  default = []
}  


# #NAT gateway details
# variable "nat_details" {
#   type = list(object({
#     #nat_required       = bool
#     create_eip         = bool              #nat_required will override it
#     eip_allocation_id  = string
#     nat_name           = string
#     nat_pub_subnet     = string
#     nat_rt_name        = string
#   }))
#   default = [
#     {
#       #nat_required       = true
#       create_eip         = true
#       eip_allocation_id  = "eipalloc-0aeac40406b4bd9d9"       #"3.72.164.102"
#       nat_name           = "terraform-nat"
#       nat_pub_subnet     = "terraform-public-subnet1"
#       nat_rt_name        = "terraform-nat-rt"
#     },
#     {
#       #nat_required       = true
#       create_eip         = true
#       eip_allocation_id  = "eipalloc-0aeac40406b4bd9d9"       #"3.72.164.102"
#       nat_name           = "terraform-nat-2"
#       nat_pub_subnet     = "terraform-public-subnet2"
#       nat_rt_name        = "terraform-nat-rt-2"
#     }
#   ]
# }