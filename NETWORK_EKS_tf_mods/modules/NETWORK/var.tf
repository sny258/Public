######### Region & Network Vars #########
variable "location" {
  description = "The location/region where resources/infrastructure will be created."
  default     = "eu-central-1"
}

variable "vpc_name" {
  type    = string
  default = ""
}

variable "vpc_cidr" {
  type    = string
  default = ""
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
      cidr  = ""
      name  = ""
      az    = ""
    }
  ]
}

variable "igw_name" {
  description = "Internet Gateway name"
  default     = "terraform-vpc-igw"
}

variable "pub_sub_rt_name" {
  description = "Public subnet's route table name"
  default     = "terraform-pub-sub-rt"
}


##Private subnet details
variable "prv_sub_required" {
  type    = bool
  default = false
}

variable "prv_sub_details" {
  type = list(object({
    cidr    = string
    name    = string
    az      = string
  }))
  default = [
    {
      cidr  = ""
      name  = ""
      az    = ""
    }
  ]
}


variable "nat_required" {
  type    = bool
  default = false
}