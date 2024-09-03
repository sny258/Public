######## EKS cluster vars #########
### Network details ###
variable "region" {
  type        = string
  default     = "eu-central-1"
}

variable "subnet_ids" {
  type        = list(string)
  default     = []                  #["subnet-011e5d3d6eed07498", "subnet-0670eb3bdfc294b5f"]
}


### Cluster configuration ###
variable "eks_cluster_config" {
  type = object({
    cluster_name                    = string
    cluster_version                 = string
    #cluster_role_arn                = string
    cluster_endpoint_private_access = bool
    cluster_endpoint_public_access  = bool
    cluster_public_access_cidrs     = list(string)
    cluster_ip_family               = string
    cluster_service_ipv4_cidr       = string
  })
  default = {
    cluster_name                    = "gwl-lab-integration-vpn-eu-central-1-eks"
    cluster_version                 = "1.29"
    #cluster_role_arn                = "cluster_role_arn"
    cluster_endpoint_private_access = true
    cluster_endpoint_public_access  = false
    cluster_public_access_cidrs     = []
    cluster_ip_family               = null                #default: "ipv4"
    cluster_service_ipv4_cidr       = null
  }
}

variable "cluster_role_arn" {
  type        = string
  default     = ""
}

variable "eks_cluster_tags" {
  type    = map(string)
  default = {
    Name = "gwl-lab-integration-vpn-eu-central-1-eks"
    Environment = "Dev"
    Owner = "Product IT"
  }
}


### Node group details ###
variable "node_group_required" {
  type        = bool
  default     = true
}

variable "node_role_arn" {
  type        = string
  default     = ""
}

variable "eks_node_group" {
  type = list(object({
    node_group_name = string
    #node_role_arn   = string
    instance_types  = list(string)
    ami_type        = string
    capacity_type   = string
    disk_size       = number
    scaling_config = object({
      desired_size = number
      min_size     = number
      max_size     = number
    })
    update_config = object({
      max_unavailable = number
    })
    node_labels     = map(string)
    node_group_tags = map(string)
  }))
  default = [
    {
      node_group_name = "gwl-lab-integration-vpn-eu-central-1-node-group"
      #node_role_arn   = "node_role_arn"
      instance_types  = ["t3.micro"]
      ami_type        = "AL2_x86_64"                     #Amazon Linux 2
      capacity_type   = "ON_DEMAND"
      disk_size       = 50
      scaling_config = {
        desired_size = 1
        max_size     = 1
        min_size     = 1
      }
      update_config = {
        max_unavailable = 1
      }
      node_labels = {
        node = "gwl-lab-integration-vpn-eu-central-1-node-group"
      }
      node_group_tags = {}
    },
    # {
    #   node_group_name = "tf-eks-nodegroup-spot"
    #   #node_role_arn   = "node_role_arn"
    #   instance_types  = ["t2.micro", "t3.micro"]
    #   ami_type        = "AL2_x86_64"                     #Amazon Linux 2
    #   capacity_type   = "SPOT"
    #   disk_size       = 20
    #   scaling_config = {
    #     desired_size = 1
    #     max_size     = 1
    #     min_size     = 1
    #   }
    #   update_config = {
    #     max_unavailable = 1
    #   }
    #   node_labels = {
    #     node = "tf-eks-node"
    #   }
    #   node_group_tags = {}
    # },
  ]
}


### Fargate Profile details ###
variable "fargate_profile_required" {
  type        = bool
  default     = false
}

variable "pod_execution_role_arn" {
  type        = string
  default     = ""
}

variable "eks_fargate_profile" {
  type = list(object({
    fargate_profile_name   = string
    #pod_execution_role_arn = string
    namespace              = string
    pod_labels             = map(string)
    fargate_profile_tags   = map(string)
  }))
  default = [
    {
      fargate_profile_name   = "tf-eks-fargate-profile"
      #pod_execution_role_arn = "pod_execution_role_arn"
      namespace              = "default"
      pod_labels = {
        pod = "tf-eks-pod"
      }
      fargate_profile_tags   = {}
    },
    {
      fargate_profile_name   = "tf-eks-fargate-profile-2"
      #pod_execution_role_arn = "pod_execution_role_arn"
      namespace              = "default"
      pod_labels = {
        pod = "tf-eks-pod-2"
      }
      fargate_profile_tags   = {}
    },
  ]
}


### Custom node group details ###
variable "custom_ng_required" {
  type        = bool
  default     = false
}

variable "eks_custom_ng" {
  type = list(object({
    ami_id            = string
    volume_size       = number
    volume_type       = string
    ########################
    node_group_name = string
    capacity_type   = string
    instance_types  = list(string)
    scaling_config = object({
      desired_size = number
      min_size     = number
      max_size     = number
    })
    update_config = object({
      max_unavailable = number
    })
    node_labels     = map(string)
    node_group_tags = map(string)
  }))
  default = [
    {
      ami_id            = "ami-015ec21a6f971d24b"             #amazon-eks-node-1.29-v20240307
      volume_size       = 50
      volume_type       = "gp3"
      ########################
      node_group_name = "tf-eks-custom-nodegroup"
      capacity_type   = "ON_DEMAND"
      instance_types  = ["t3.medium"]
      scaling_config = {
        desired_size = 1
        max_size     = 1
        min_size     = 1
      }
      update_config = {
        max_unavailable = 1
      }
      node_labels = {
        node = "tf-custom-eks-node"
      }
      node_group_tags = {}
    },
    {
      ami_id            = "ami-007e98bcc6d41b74e"             #amazon-eks-node-1.29-v20240424
      volume_size       = 50
      volume_type       = "gp3"
      ########################
      node_group_name = "tf-eks-custom-nodegroup-2"
      capacity_type   = "SPOT"
      instance_types  = ["t2.micro", "t3.micro"]
      scaling_config = {
        desired_size = 1
        max_size     = 1
        min_size     = 1
      }
      update_config = {
        max_unavailable = 1
      }
      node_labels = {
        node = "tf-custom-eks-node"
      }
      node_group_tags = {}
    }
  ]
}


## Set version value as null for default version
### EKS cluster Add-ons ###
variable "addons" {
  type = list(object({
    #required          = bool
    name              = string
    version           = string
    resolve_conflicts = string
  }))
  default = [
    {
      #required          = true
      name              = "kube-proxy"
      version           = null                      #"v1.29.1-eksbuild.2"
      resolve_conflicts = "OVERWRITE"
    },
    {
      #required          = true
      name              = "vpc-cni"
      version           = null                #"v1.18.0-eksbuild.1"
      resolve_conflicts = "OVERWRITE"
    },
    {
      #required          = true
      name              = "coredns"
      version           = null                #"v1.11.1-eksbuild.6"
      resolve_conflicts = "OVERWRITE"
    }
  ]
}


### EKS cluster ebs csi Add-on ###
variable "ebs_csi_addon" {
  type = object({
    required          = bool
    name              = string
    version           = string
    resolve_conflicts = string
  })
  default = {
    required          = false
    name              = "aws-ebs-csi-driver"
    version           = null                                    #"v1.27.0-eksbuild.1"
    resolve_conflicts = "OVERWRITE"
  }
}


### EKS cluster efs-csi Add-on ###
variable "efs_csi_addon" {
  type = object({
    required          = bool
    name              = string
    version           = string
    resolve_conflicts = string
  })
  default = {
    required          = false
    name              = "aws-efs-csi-driver"
    version           = "v2.0.0-eksbuild.1"
    resolve_conflicts = "OVERWRITE"
  }
}