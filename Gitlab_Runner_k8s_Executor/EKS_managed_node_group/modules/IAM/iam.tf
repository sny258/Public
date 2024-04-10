#############################################################################
### IAM Role

data "aws_partition" "current" {}
data "aws_caller_identity" "current" {}

### IAM Role for cluster ###
resource "aws_iam_role" "iam_cluster_role" {
  name        = "${var.cluster_name}-cluster-role"
  path        = var.iam_role_path
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
  tags = var.eks_cluster_role_tags
}

###Policy for cloudwatch log-group (Inline Policy)
resource "aws_iam_role_policy" "Cluster_Cloudwatchlog" {
  name = "${var.cluster_name}-cluster-cw-policy"
  role = aws_iam_role.iam_cluster_role.id 
  policy = jsonencode(
    {
      Statement = [
        {
          Action = [
            "cloudwatch:PutMetricData",
          ]
          Effect   = "Allow"
          Resource = "*"
        },
      ]
      Version = "2012-10-17"
    }
  )
}

# Cluster IAM Policies
# Policies attached ref https://docs.aws.amazon.com/eks/latest/userguide/service_IAM_role.html
resource "aws_iam_role_policy_attachment" "EKSClusterPolicy" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy",
    "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController",
  ])
  role       = aws_iam_role.iam_cluster_role.id
  policy_arn = each.value
}



### Node IAM Role ###
resource "aws_iam_role" "eks_nodegroup_role" {
  name        = "${var.cluster_name}-cluster-nodegroup-role"
  path        = var.iam_role_path
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
  tags = var.eks_cluster_role_tags
}

# Node IAM Policy
resource "aws_iam_role_policy_attachment" "EKSNodeGroupPolicy" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
  ])
  role       = aws_iam_role.eks_nodegroup_role.id
  policy_arn = each.value
}



#creating custom policies for EKS cluster autoscaling
resource "aws_iam_policy" "ng_autoscaler_policy" {
  name        = "policy_for_node_group_autoscaling"

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
          "ec2:DescribeLaunchTemplateVersions"
        ],
        "Resource": "*"
      }
    ]
  })
}

##Attaching custom policies
resource "aws_iam_role_policy_attachment" "AmazonEKSNodeGroupAutoScalingPolicy" {
  role       = aws_iam_role.eks_nodegroup_role.name
  policy_arn = aws_iam_policy.ng_autoscaler_policy.arn           
}