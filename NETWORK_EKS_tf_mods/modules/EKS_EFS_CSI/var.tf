#EKS cluster
variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = ""
}

#EKS cluster Add-on
variable "addon_name" {
  type        = string
  default     = "aws-efs-csi-driver"
}

variable "addon_version" {
  type        = string
  default     = ""
}

variable "resolve_conflicts" {
  type        = string
  default     = ""
}

