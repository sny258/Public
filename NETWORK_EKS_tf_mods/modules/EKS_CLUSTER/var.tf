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


#EKS cluster details
variable "cluster_name" {
  type        = string
  default     = ""
}

variable "cluster_version" {
  type        = string
  default     = ""
}

variable "cluster_role_arn" {
  type        = string
  default     = ""
}

variable "cluster_endpoint_private_access" {
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access" {
  type        = bool
  default     = false
}

variable "cluster_public_access_cidrs" {
  type        = list(string)
  default     = []
}

variable "cluster_ip_family" {
  type        = string
  default     = null
}

variable "cluster_service_ipv4_cidr" {
  type        = string
  default     = null
}


#tags
variable "eks_cluster_tags" {
  type    = map(string)
  default = {}
}
