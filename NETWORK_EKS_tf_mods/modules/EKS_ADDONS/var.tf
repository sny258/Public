###################
variable "cluster_name" {
  type        = string
  default     = ""
}

#EKS cluster Add-ons
variable "addon_name" {
  type        = string
  default     = ""
}

variable "addon_version" {
  type        = string
  default     = ""
}

variable "resolve_conflicts" {
  type        = string
  default     = ""
}

