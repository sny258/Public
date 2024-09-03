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


#EKS fargate profile role arn
variable "fargate_profile_name" {
  type        = string
  default     = ""
}

variable "pod_execution_role_arn" {
  type        = string
  default     = ""
}

variable "namespace" {
  type        = string
  default     = "default"
}

variable "pod_labels" {
  type        = map(string)
  default     = {}
}

variable "fargate_profile_tags" {
  type        = map(string)
  default     = {}
}