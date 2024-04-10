#############################################################################
### Cluster

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = ""
}

variable "cluster_version" {
  description = "Kubernetes `<major>.<minor>` version to use for the EKS cluster (i.e.: `1.22`)"
  type        = string
  default     = "1.28"
}

variable "cluster_iam_role" {
  description = "IAM role for the cluster will be inherit from IAM module"
  type        = string
  default     = ""
}

variable "subnet_ids" {
  description = "A list of subnet IDs where the nodes/node groups will be provisioned. If `control_plane_subnet_ids` is not provided, the EKS cluster control plane (ENIs) will be provisioned in these subnets"
  type        = list(string)
  default     = [""]
}

variable "cluster_endpoint_private_access" {
  description = "Indicates whether or not the Amazon EKS private API server endpoint is enabled"
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access" {
  description = "Indicates whether or not the Amazon EKS public API server endpoint is enabled"
  type        = bool
  default     = false
}

variable "cluster_public_access_cidrs" {
  description = "A list of CIDRs allowed to access cluster endpoint when cluster_endpoint_public_access is set to true"
  type        = list(string)
  default     = [""]
}

variable "cluster_ip_family" {
  description = "The IP family used to assign Kubernetes pod and service addresses. Valid values are `ipv4` (default) and `ipv6`. You can only specify an IP family when you create a cluster, changing this value will force a new cluster to be created"
  type        = string
  default     = null
}

variable "cluster_service_ipv4_cidr" {
  description = "The CIDR block to assign Kubernetes service IP addresses from. If you don't specify a block, Kubernetes assigns addresses from either the 10.100.0.0/16 or 172.20.0.0/16 CIDR blocks"
  type        = string
  default     = null
}



#############################################################################
# EKS Node group

variable "eks_node_group" {
  type        = string
  default     = ""
}

variable "node_iam_role" {
  description = "Node arn to perform the operations and fetch parameters"
  type        = string
  default     = ""
}

variable "min_size" {
  description = "Minimum number of instances/nodes"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "autoscalling parameters max numbers nodes required to run Atlassian application"
  type        = number
  default     = 3
}

variable "desired_size" {
  description = "exact number of node/servers require to run Atlassian"
  type        = number
  default     = 1
}

variable "ami_type" {
  description = "Optimised amiid for EKS cluster please choose default option"
  type        = string
  default     = ""
}

variable "release_version" {
  description = "release version for EKS cluster nodes please choose default option"
  type        = string
  default     = null
}

variable "eks_version" {
  description = "Version for EKS cluster nodes please choose default option"
  type        = string
  default     = null
}

variable "capacity_type" {
  description = "Please choose the default capacity"
  type        = string
  default     = ""
}

variable "force_update_version" {
  description = "Please choose the default option"
  type        = bool
  default     = null
}
variable "instance_type" {
  description = "Please choose the instance type to run Atlassian, default recommended is t3.medium"
  type        = list(string)
  default     = []
}

variable "disk_size" {
  description = "Disk size for EKS nodes"
  type        = number
  default     = 30
}

variable "labels" {
  type        = map(string)
  default     = {}                #{node="gwl-gitlab-runner-eu-west-1-Node"}
}


#############################################################################
# CloudWatch Log Group


# variable "cloudwatch_log_group_retention_in_days" {
#   description = "Number of days to retain log events. Default retention - 90 days"
#   type        = number
#   default     = 90
# }

# variable "vpc_id" {
#   description = "ID of the VPC where the cluster and its nodes will be provisioned"
#   type        = string
#   default     = ""
# }

# variable "second_sg_name" {
#   type        = string
#   default     = "gwl-gitlab-runner-eu-central-1-eks-sg"
# }



variable "eks_cluster_tags" {
  type    = map(string)
  default = {
    Name = ""
    Environment = ""
    Project = ""
    Owner = ""
    CreatedBy = ""
  }
}

# variable "eks_node_group_tags" {
#   type    = map(string)
#   default = {
#     Name = ""
#     Environment = ""
#     Project = ""
#     Owner = ""
#     CreatedBy = ""
#   }
# }

# variable "cw_log_group_tags" {
#   type    = map(string)
#   default = {
#     Name = "gwl-gitlab-runner-eu-central-1-eks"
#     Environment = "PROD"
#     Project = "GWL"
#     Owner = "Product IT"
#     CreatedBy = "Terraform"
#   }
# }

# variable "eks_cluster_sg_tags" {
#   type    = map(string)
#   default = {
#     Name = "gwl-gitlab-runner-eu-central-1-eks"
#     Environment = "PROD"
#     Project = "GWL"
#     Owner = "Product IT"
#     CreatedBy = "Terraform"
#   }
# }