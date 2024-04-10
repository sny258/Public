######### Region & Network Vars #########
variable "location" {
  description = "The location/region where resources/infrastructure will be created."
  default     = "eu-west-1"
}

variable "vpc_id" {
  type        = string
  description = "VPC where resources/infrastructure will be created "
  #default     = "vpc-0f537d653d63107ef"
  default     = "vpc-f6822793"               #playground env Default VPC
}

variable "subnet_ids" {
  type        = list(string)
  description = "Subnet/s to be used for infrastructure"
  default     = ["subnet-011e5d3d6eed07498", "subnet-0670eb3bdfc294b5f"]
  #names      = [private2-default (eu-west-1b), private1-default (eu-west-1c)]
}

variable "security_group_id" {
  description = "Security Group ID"
  default     = "sg-085ed924dcdaac13b"              #"GitlabRunnerTestSG"
}

#Cluster configuration
variable "cluster_config" {
  type = object({
    name    = string
    version = string
  })
  default = {
    name    = "gitlab-runner-cluster"
    version = "1.28"
  }
}

variable "public_access_cidrs" {
  type        = list(string)
  description = "Indicates which CIDR blocks can access the Amazon EKS public API server endpoint when enabled. EKS defaults this to a list with 0.0.0.0/0."
  default     = ["49.36.233.246/32"]
}

#EKS cluster Add-ons
variable "addons" {
  type = list(object({
    name    = string
    version = string
  }))
  default = [
    {
      name    = "kube-proxy"
      version = "v1.28.1-eksbuild.1"
    },
    {
      name    = "vpc-cni"
      version = "v1.14.1-eksbuild.1"
    },
    {
      name    = "coredns"
      version = "v1.10.1-eksbuild.4"
    },
    {
      name    = "aws-ebs-csi-driver"
      version = "v1.26.1-eksbuild.1"
    }
  ]
}




# #Node group details
# variable "node_groups" {
#   type = list(object({
#     name           = string
#     instance_types = list(string)
#     ami_type       = string
#     capacity_type  = string
#     disk_size      = number
#     scaling_config = object({
#       desired_size = number
#       min_size     = number
#       max_size     = number
#     })
#     update_config = object({
#       max_unavailable = number
#     })
#   }))
#   default = [
#     {
#       name           = "gitlab_runner_nodegroup"
#       instance_types = ["t2.medium"]                    #Max ANI 3, Max IPs 18
#       ami_type       = "AL2_x86_64"                     #Amazon Linux 2
#       capacity_type  = "ON_DEMAND"
#       disk_size      = 20
#       scaling_config = {
#         desired_size = 2
#         max_size     = 3
#         min_size     = 1
#       }
#       update_config = {
#         max_unavailable = 1
#       }
#     },
#     # {
#     #   name           = "t3-micro-spot"
#     #   instance_types = ["t3.micro"]
#     #   ami_type       = "AL2_x86_64"
#     #   capacity_type  = "SPOT"
#     #   disk_size      = 20
#     #   scaling_config = {
#     #     desired_size = 2
#     #     max_size     = 3
#     #     min_size     = 1
#     #   }
#     #   update_config = {
#     #     max_unavailable = 1
#     #   }
#     # },
#   ]
# }





########## launch config variables #############

variable "gitlab_url" {
  description = "URL of gitlab instance"
  default     = "https://sourcery-test.assaabloy.net"
}

variable "ami" {
  description = "Instance AMI which will be associated with EKS cluster"
  type        = string
  default     = "ami-0cdc583db5fc2be50"       #amazon-eks-node-1.28-v20240110
}

variable "instance_size" {
  description = "EC2 instance size"
  type        = string
  default     = "t2.medium"
}

variable "key_pair" {
  description = "Key pair for EC2"
  type        = string
  default     = "GitlabRunnerTest-Key"
}

variable "node_group_name" {
  description = "Node group name for EKS cluster"
  type        = string
  default     = "gitlab_runner_nodegroup"
}

variable "desired_size" {
  description = "desired size of node group"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "max size of node group"
  type        = number
  default     = 3
}

variable "min_size" {
  description = "min size of node group"
  type        = number
  default     = 1
}

variable "max_unavailable" {
  description = "max unavailable node from node group"
  type        = number
  default     = 1
}