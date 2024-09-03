###################
#Network details
variable "region" {
  type        = string
  default     = ""
}

variable "subnet_ids" {
  type        = list(string)
  default     = []
}


#EKS cluster
variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = ""
}


#custom launch template
variable "ami_id" {
  type        = string
  default     = ""
}

variable "instance_types" {
  type        = list(string)
  default     = []
}

variable "security_group_id" {
  type        = string
  default     = ""
}

variable "volume_size" {
  type        = number
  default     = 30
}

variable "volume_type" {
  type        = string
  default     = ""
}



#EKS node group
variable "node_group_name" {
  type        = string
  default     = ""
}

variable "node_role_arn" {
  type        = string
  default     = ""
}

variable "capacity_type" {
  type        = string
  default     = ""
}

variable "desired_size" {
  type        = number
  default     = 1
}

variable "min_size" {
  type        = number
  default     = 1
}

variable "max_size" {
  type        = number
  default     = 1
}

variable "max_unavailable" {
  type        = number
  default     = 1
}

variable "node_labels" {
  type        = map(string)
  default     = {}
}

variable "node_group_tags" {
  type        = map(string)
  default     = {}
}