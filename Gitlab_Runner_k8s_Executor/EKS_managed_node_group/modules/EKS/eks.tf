#############################################################################
# Cluster
data "aws_partition" "current" {}
data "aws_caller_identity" "current" {}

### EKS cluster ###
resource "aws_eks_cluster" "eks_cluster" {
  #enabled_cluster_log_types = ["api","audit",]
  name                      = var.cluster_name
  role_arn                  = var.cluster_iam_role
  version                   = var.cluster_version
  

  vpc_config {
   subnet_ids                    = var.subnet_ids
   endpoint_private_access       = var.cluster_endpoint_private_access
   endpoint_public_access        = var.cluster_endpoint_public_access
   #public_access_cidrs           = var.cluster_public_access_cidrs
   public_access_cidrs           =var.cluster_endpoint_public_access ? var.cluster_public_access_cidrs : []
  }

  kubernetes_network_config {
    ip_family         = var.cluster_ip_family
    service_ipv4_cidr = var.cluster_service_ipv4_cidr
  }
  
  # encryption_config {
  #   provider {
  #     key_arn= var.keyarn
  #     }
  #   resources =["secrets"]
  # }
  
  timeouts {}

  tags = var.eks_cluster_tags
  depends_on = [
    #aws_iam_role_policy_attachment.AmazonEKSClusterPolicy,
    #aws_iam_role_policy_attachment.AmazonEKSVPCResourceController,
    ##aws_security_group.eks_second_sg,
    #aws_cloudwatch_log_group.eks_cw
  ]
}

### JGWK gitlab runner Node Group ###
resource "aws_eks_node_group" "eks_node_group" {
  # Required
  cluster_name    = var.cluster_name
  node_group_name = var.eks_node_group
  node_role_arn   = var.node_iam_role
  subnet_ids      = var.subnet_ids

  scaling_config {
    min_size               = var.min_size
    max_size               = var.max_size
    desired_size           = var.desired_size
  }
  
  ami_type             = var.ami_type 
  release_version      = var.release_version
  version              = var.eks_version
  capacity_type        = var.capacity_type
  disk_size            = var.disk_size
  force_update_version = var.force_update_version
  instance_types       = var.instance_type
  labels               = var.labels
  
  tags        = var.eks_cluster_tags
  depends_on  = [ 
    aws_eks_cluster.eks_cluster,
    #aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
    #aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly,
    #aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy
  ]
}


# ### Cloudwatch Logs ###
# resource "aws_cloudwatch_log_group" "eks_cw" {
#   name              = "/aws/eks/${var.cluster_name}/cluster"
#   retention_in_days = var.cloudwatch_log_group_retention_in_days
#   #tags = var.cw_log_group_tags 
# }


# #############################################################################
# # EKS Cluster secondory Security Group
# resource "aws_security_group" "eks_second_sg" {
#   name        = var.second_sg_name
#   description = "controls access to the cluster"
#   vpc_id      = var.vpc_id
#   ingress {
#     protocol    = "-1"
#     from_port   = 0
#     to_port     = 0
#     cidr_blocks = ["10.0.0.0/16"]                     #VPC CIDR
#     description = "All Traffic from VPC"
#   }
#   ingress {
#     protocol    = "-1"
#     from_port   = 0
#     to_port     = 0
#     cidr_blocks =["212.247.19.62/32"]
#     description = "All Traffic from Stockholm VPN"    
#   }
#   egress {
#     protocol    = "-1"
#     from_port   = 0
#     to_port     = 0
#     cidr_blocks = ["0.0.0.0/0"]
#   }
#     tags = var.eks_cluster_sg_tags
# }