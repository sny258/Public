################################################################################
# Cluster IAM Role
################################################################################
variable "iam_role_path" {
  description = "Cluster IAM role path"
  type        = string
  default     = "/"
}

variable "cluster_name" {
  type        = string
  default     =  "" 
}

variable "eks_cluster_role_tags" {
  type    = map(string)
  default = {
    Name = ""
    Environment = ""
    Project = ""
    Owner = ""
    CreatedBy = ""
  }
}