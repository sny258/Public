
#EKS cluster data block
data "aws_eks_cluster" "eks_cluster" {
  name = var.cluster_name
}

locals {
  k8s_cluster_dns_ip = data.aws_eks_cluster.eks_cluster.kubernetes_network_config[0].service_ipv4_cidr
  #k8s_cluster_dns_ip = "10.100.0.10" 
}

##### aws  launch template for nodes ######
resource "aws_launch_template" "eks_custom_ng_lt" {
  name_prefix          = "${var.cluster_name}-launch-template-"
  image_id             = var.ami_id
  #instance_type        = var.instance_types
  #key_name             = var.key_pair
  vpc_security_group_ids = [var.security_group_id]
  block_device_mappings {
    device_name = "/dev/xvda"                     #default path '/dev/xvda'
    ebs {
      volume_size = var.volume_size               #default '30GB'
      delete_on_termination = true                #default 'Yes'
      volume_type = var.volume_type               #default 'gp3'
    }
  }

  user_data = base64encode(<<EOF
MIME-Version: 1.0
Content-Type: multipart/mixed; boundary="//"
--//
Content-Type: text/x-shellscript; charset="us-ascii"
#!/bin/bash
set -ex
B64_CLUSTER_CA=${data.aws_eks_cluster.eks_cluster.certificate_authority[0].data}
API_SERVER_URL=${data.aws_eks_cluster.eks_cluster.endpoint}
K8S_CLUSTER_DNS_IP="${local.k8s_cluster_dns_ip}"
/etc/eks/bootstrap.sh "${var.cluster_name}" --b64-cluster-ca $B64_CLUSTER_CA --apiserver-endpoint $API_SERVER_URL --dns-cluster-ip $K8S_CLUSTER_DNS_IP

--//--
EOF
  )
  # tag_specifications {
  #   resource_type = "instance"
  #   tags = {
  #     Name = "EKS Instance - ${var.cluster_name}"
  #   }
  # }
}


#### EKS Node Group #########
resource "aws_eks_node_group" "eks_node_group" {
  cluster_name    = var.cluster_name
  node_group_name = var.node_group_name
  node_role_arn   = var.node_role_arn
  subnet_ids      = var.subnet_ids
  scaling_config {
    desired_size = try(var.desired_size, 1)         #use default in case no values provided using try function
    max_size     = try(var.max_size, 1)
    min_size     = try(var.min_size, 1)
  }
  launch_template {
    id      = aws_launch_template.eks_custom_ng_lt.id                 #will include ami & volume details
    version = aws_launch_template.eks_custom_ng_lt.latest_version     #"$Latest"
  }
  update_config {
    max_unavailable = try(var.max_unavailable, 1)
  } 
  instance_types = var.instance_types
  capacity_type  = var.capacity_type
  labels         = var.node_labels
  tags           = var.node_group_tags
  depends_on = [
    aws_launch_template.eks_custom_ng_lt
  ]
}
