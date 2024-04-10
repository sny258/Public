variable "aws_region" {
  description = "Region where AWS resources will be provisioned"
  type        = string
  default     = "eu-west-1"
}

variable "vpc_id" {
  type        = string
  description = "VPC where resources/infrastructure will be created "
  default     = "vpc-f6822793" #playground env Default VPC
}

variable "subnet_ids" {
  type        = list(string)
  description = "Subnet/s to be used for infrastructure"
  default     = ["subnet-011e5d3d6eed07498", "subnet-0670eb3bdfc294b5f"]
}



###EKS Cluster
variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "gwl-gitlab-runner-eu-west-1-eks"
}

variable "cluster_version" {
  description = "Kubernetes `<major>.<minor>` version to use for the EKS cluster (i.e.: `1.22`)"
  type        = string
  default     = "1.29"
}

variable "cluster_endpoint_private_access" {
  description = "Indicates whether or not the Amazon EKS private API server endpoint is enabled"
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access" {
  description = "Indicates whether or not the Amazon EKS public API server endpoint is enabled"
  type        = bool
  default     = true
}

variable "cluster_public_access_cidrs" {
  description = "A list of CIDRs allowed to access cluster endpoint when cluster_endpoint_public_access is set to true"
  type        = list(string)
  #default     = ["49.36.233.246/32"]             #Local Machine IP
  default     = ["212.247.19.62/32"]
}

variable "cluster_iam_role" {
  description = "IAM role for the cluster will be inherit from IAM module"
  type        = string
  default     = ""
}



### Node Group
variable "eks_node_group" {
  type    = string
  default = "gwl-gitlab-runner-eu-west-1-node-group"
}

variable "node_iam_role" {
  description = "Node arn to perform the operations and fetch parameters"
  type        = string
  default     = ""
}

variable "instance_type" {
  description = "EC2 instance type for EKS cluster"
  default     = ["t3.medium"] #["c6a.xlarge"]
}

variable "ami_type" {
  description = "Optimised amiid for EKS cluster please choose default option"
  type        = string
  default     = "AL2_x86_64"
}

variable "capacity_type" {
  description = "Please choose the default capacity"
  type        = string
  default     = "ON_DEMAND"
}

variable "disk_size" {
  description = "Disk size for EKS nodes"
  type        = number
  default     = 50
}

variable "min_size" {
  description = "Minimum number of instances/nodes"
  type        = number
  default     = 2
}

variable "max_size" {
  description = "autoscalling parameters max numbers nodes for cluster"
  type        = number
  default     = 5
}

variable "desired_size" {
  description = "exact number of node/servers required for cluster"
  type        = number
  default     = 2
}

variable "labels" {
  type    = map(string)
  default = { node = "gwl-gitlab-runner-eu-west-1-Node" }
}


#### Tags
variable "eks_cluster_tags" {
  type = map(string)
  default = {
    Name        = "gwl-gitlab-runner-eu-west-1-eks"
    Environment = "PROD"
    Project     = "GWL"
    Owner       = "Product IT"
    CreatedBy   = "Terraform"
  }
}

# variable "eks_node_group_tags" {
#   type    = map(string)
#   default = {
#     Name = "gwl-gitlab-runner-eu-west-1-eks"
#     Environment = "PROD"
#     Project = "GWL"
#     Owner = "Product IT"
#     CreatedBy = "Terraform"
#   }
# }



variable "aws_access_key_id" {
  description = "aws access key id of admin account"
  type        = string
  default     = "ASIAS37Hxxxxxxxxxxxx"
}

variable "aws_secret_access_key" {
  description = "aws access secret key of admin account"
  type        = string
  default     = "podX29OsQQZ9lEkwxxxxxxxxxxxxxxxx"
}


variable "aws_session_token" {
  description = "aws account session token"
  type        = string
  default     = "IQoJxxxxxxxxxxxxx"
}

variable "aws_access_key_id_s3" {
  description = "aws access key id of admin account"
  type        = string
  default     = "AKIAS37HZJxxxxxxx"
}

variable "aws_secret_access_key_s3" {
  description = "aws access secret key of admin account"
  type        = string
  default     = "5Z/Lmz+sBv3lalcp8zIEo6J8xxxxxxxxxxxx"
}