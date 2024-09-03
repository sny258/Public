#############################################################################
### IAM Role

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

### IAM Role for cluster ###
resource "aws_iam_role" "iam_cluster_role" {
  name   = "${var.cluster_name}-cluster-role"
  path   = var.iam_role_path
  #Assume role will go to Trust policy
  assume_role_policy    = jsonencode(
    {
      Statement = [
        {
          Action = "sts:AssumeRole"
          Effect = "Allow"
          Principal = {
            Service ="eks.amazonaws.com"
          }
        },
      ]
      Version = "2012-10-17"
    }
  )
  force_detach_policies = true
}

# Cluster IAM role policies attachment
resource "aws_iam_role_policy_attachment" "EKSClusterPolicyAttachment" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy",
    "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController",
  ])
  role       = aws_iam_role.iam_cluster_role.id
  policy_arn = each.value
}



### Node IAM Role ###
resource "aws_iam_role" "eks_nodegroup_role" {
  name   = "${var.cluster_name}-cluster-nodegroup-role"
  path   = var.iam_role_path
  #Assume role will go to Trust policy
  assume_role_policy    = jsonencode(
    {
      Statement = [
        {
          Action = "sts:AssumeRole"
          Effect = "Allow"
          Principal = {
            Service : "ec2.amazonaws.com"
          }
        },
      ]
      Version = "2012-10-17"
    }
  )
  force_detach_policies = true
  #tags = var.eks_cluster_role_tags
}

# Node IAM policy attachment
resource "aws_iam_role_policy_attachment" "EKSNodeGroupPolicyAttachment" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
  ])
  role       = aws_iam_role.eks_nodegroup_role.id
  policy_arn = each.value
}



#creating inline policies for EKS cluster autoscaling that will be attached to node IAM role
resource "aws_iam_role_policy" "ng_autoscaler_policy" {
  name   = "policy_for_node_group_autoscaling"
  role   = aws_iam_role.eks_nodegroup_role.name
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeAutoScalingInstances",
          "autoscaling:DescribeLaunchConfigurations",
          "autoscaling:DescribeTags",
          "autoscaling:SetDesiredCapacity",
          "autoscaling:TerminateInstanceInAutoScalingGroup",
          "ec2:DescribeLaunchTemplateVersions",
          "eks:DescribeNodegroup",                                #Additional for scale-out from 0 nodes
          "eks:ListNodegroups"                                    #Additional for scale-out from 0 nodes
        ],
        "Resource": "*"
      }
    ]
  })
}



#IAM role for EKS Fargate profile
resource "aws_iam_role" "eks_fargate_profile_role" {
  name = "${var.cluster_name}-AmazonEKSFargatePodExecutionRole"
  path = var.iam_role_path
  #Assume role policy will go to trust policy
  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks-fargate-pods.amazonaws.com"
      },
      "Condition": {
        "ArnLike": {
          "aws:SourceArn": "arn:aws:eks:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:fargateprofile/${var.cluster_name}/*"
        }
      }
    }]
    Version = "2012-10-17"
  })
}

# EKS Fargate Profile policy attachment
resource "aws_iam_role_policy_attachment" "EKSFargateProfilePolicyAttachment" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"
  ])
  role       = aws_iam_role.eks_fargate_profile_role.name
  policy_arn = each.value
}







##For creating and attaching custom policy to IAM role
# resource "aws_iam_policy" "custom_policy" {
#   name   = "custom_policy_for_IAM"
#   policy = jsonencode({
#     "Version": "2012-10-17",
#     "Statement": [
#       {
#         "Effect": "Allow",
#         "Action": [
#           *
#         ],
#         "Resource": "*"
#       }
#     ]
#   })
# }

# ##attaching custom policies to node iam role
# resource "aws_iam_role_policy_attachment" "custompolicyattachment" {
#   role       = aws_iam_role.eks_IAM_role.name
#   policy_arn = aws_iam_policy.custom_policy.arn           
# }