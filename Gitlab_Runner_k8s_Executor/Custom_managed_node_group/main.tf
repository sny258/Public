terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
#  backend "s3" {
#    bucket = "terraform-statefile-gitlabrunner"
#    key    = "statefile/k8gitlabrunner.tfstate"
#    region = "eu-west-1"
#    encrypt = true
#  }
}

# Configure the AWS Provider
provider "aws" {
  region = var.location
#  access_key = "my-access-key"
#  secret_key = "my-secret-key"
}



######### IAM role/s  ##########
## IAM role for EC2 instance, where all policies will be addedd
resource "aws_iam_role" "node_group_role" {
  name = "gr_node_group_role"
  path = "/"

  assume_role_policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": ["ec2.amazonaws.com"]
      },
      "Effect": "Allow"
    }
  ]
}
EOF
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
  role       = aws_iam_role.node_group_role.name
  policy_arn = aws_iam_policy.ng_autoscaler_policy.arn           
}
###Adding predefined policy to IAM role
resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node_group_role.name
}
resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node_group_role.name
}
resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node_group_role.name
}

resource "aws_iam_role_policy_attachment" "AmazonSSMManagedInstanceCore" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.node_group_role.name
}

# #instance profile which will be the bridge between EC2 and IAM role.
# #this will be attached to EC2 machine, no the IAM role
# resource "aws_iam_instance_profile" "ecs_service_role" {
#   role = aws_iam_role.ecs_instance_role.name
# }


## IAM role for EKS cluster, where all policies will be addedd
resource "aws_iam_role" "eks_cluster_role" {
  name = "gr_eks_cluster_role"
  path = "/"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "EKSClusterAssumeRole",
            "Effect": "Allow",
            "Principal": {
                "Service": "eks.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF
}

###Adding predefined policy to IAM role
resource "aws_iam_role_policy_attachment" "AmazonEKSClusterPolicy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}
resource "aws_iam_role_policy_attachment" "AmazonEKSVPCResourceController" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
}




# ####### EKS Cluster ##########
# resource "aws_eks_cluster" "eks_cluster" {
#   name     = var.cluster_config.name
#   role_arn = aws_iam_role.eks_cluster_role.arn
#   version  = var.cluster_config.version

#   vpc_config {
#     subnet_ids         = var.subnet_ids
#     security_group_ids = [var.security_group_id]
#   }

#   depends_on = [
#     aws_iam_role_policy_attachment.AmazonEKSClusterPolicy,
#     aws_iam_role_policy_attachment.AmazonEKSVPCResourceController
#   ]
# }

# ####### NODE GROUP ##########
# resource "aws_eks_node_group" "gitlab_runner_ng" {
#   for_each        = { for node_group in var.node_groups : node_group.name => node_group }
#   cluster_name    = aws_eks_cluster.eks_cluster.name
#   node_group_name = each.value.name
#   node_role_arn   = aws_iam_role.node_group_role.arn
#   subnet_ids      = var.subnet_ids

#   scaling_config {
#     desired_size = try(each.value.scaling_config.desired_size, 2)         #use default in case no values provided using try function
#     max_size     = try(each.value.scaling_config.max_size, 3)
#     min_size     = try(each.value.scaling_config.min_size, 1)
#   }

#   update_config {
#     max_unavailable = try(each.value.update_config.max_unavailable, 1)
#   }

#   ami_type       = each.value.ami_type
#   instance_types = each.value.instance_types
#   capacity_type  = each.value.capacity_type
#   disk_size      = each.value.disk_size

#   depends_on = [
#     aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
#     aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly,
#     aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy
#   ]
# }

# ##### Add-ons for the EKS cluster ########
# resource "aws_eks_addon" "addons" {
#   for_each          = { for addon in var.addons : addon.name => addon }
#   cluster_name      = aws_eks_cluster.eks_cluster.id
#   addon_name        = each.value.name
#   addon_version     = each.value.version
#   resolve_conflicts = "OVERWRITE"
# }


#################################################




####### EKS Cluster ##########
resource "aws_eks_cluster" "eks_cluster" {
  name     = var.cluster_config.name
  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = var.cluster_config.version

  #endpoint_private_access = true               
  #endpoint_public_access  = false        #default is public with [0.0.0.0/0]

  vpc_config {
    subnet_ids            = var.subnet_ids
    security_group_ids    = [var.security_group_id]
    #endpoint_private_access = false               
    endpoint_public_access  = true        #default is public with [0.0.0.0/0]
    public_access_cidrs     = var.public_access_cidrs
  }

  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.AmazonEKSVPCResourceController
  ]
}

##### aws  launch template for nodes ######
resource "aws_launch_template" "gr_eks_cluster_lt" {
  name_prefix          = "${var.cluster_config.name}-launch-template-"
  image_id             = var.ami
  instance_type        = var.instance_size
  key_name             = var.key_pair

  vpc_security_group_ids = [var.security_group_id, aws_eks_cluster.eks_cluster.vpc_config[0].cluster_security_group_id]

  # ebs_optimized        = true                     #additional cost   
  # block_device_mappings {
  #   device_name = "/dev/xvda"                     #default path '/dev/xvda'
  #   ebs {
  #     volume_size = 60                            #default '30GB'
  #     delete_on_termination = true                #default 'Yes'
  #     volume_type = "gp3"                         #default 'gp3'
  #   }
  # }

  user_data = base64encode(<<EOF
MIME-Version: 1.0
Content-Type: multipart/mixed; boundary="//"
--//
Content-Type: text/x-shellscript; charset="us-ascii"
#!/bin/bash
set -ex
/etc/eks/bootstrap.sh "${var.cluster_config.name}"

yum update -y
yum install -y openssl telnet
#Downloading and Adding gitlab certs for docker
gitlab_url_without_https=$(echo "${var.gitlab_url}" | sed 's/^https:\/\///')
mkdir -p /etc/docker/certs.d/registry.$gitlab_url_without_https
openssl s_client -showcerts -connect $gitlab_url_without_https:443 -servername $gitlab_url_without_https < /dev/null 2>/dev/null | awk '/-----BEGIN CERTIFICATE-----/, /-----END CERTIFICATE-----/' > /etc/docker/certs.d/registry.$gitlab_url_without_https/$gitlab_url_without_https.crt
--//--
EOF
  )

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "EKS Instance - ${var.cluster_config.name}#DoNotDelete"
    }
  }
  # depends_on = [
  #   aws_eks_cluster.eks_cluster
  # ]
}

####### NODE GROUP ##########
resource "aws_eks_node_group" "gitlab_runner_ng" {
  cluster_name    = aws_eks_cluster.eks_cluster.name
  node_group_name = var.node_group_name
  node_role_arn   = aws_iam_role.node_group_role.arn
  subnet_ids      = var.subnet_ids

  scaling_config {
    desired_size = try(var.desired_size, 1)         #use default in case no values provided using try function
    max_size     = try(var.max_size, 3)
    min_size     = try(var.min_size, 1)
  }

  launch_template {
    id      = aws_launch_template.gr_eks_cluster_lt.id
    version = "$Latest"
  }

  update_config {
    max_unavailable = try(var.max_unavailable, 1)
  }

  capacity_type  = "ON_DEMAND"

  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly,
    aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy,
    #aws_launch_template.gr_eks_cluster_lt
  ]
}

##### Add-ons for the EKS cluster ########
resource "aws_eks_addon" "addons" {
  for_each          = { for addon in var.addons : addon.name => addon }
  cluster_name      = aws_eks_cluster.eks_cluster.id
  addon_name        = each.value.name
  addon_version     = each.value.version
  resolve_conflicts = "OVERWRITE"

  # depends_on = [
  #   #aws_eks_cluster.eks_cluster
  #   aws_eks_node_group.gitlab_runner_ng
  # ]
}