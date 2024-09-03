
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
  update_config {
    max_unavailable = try(var.max_unavailable, 1)
  }
  ami_type       = var.ami_type
  instance_types = var.instance_types
  capacity_type  = var.capacity_type
  disk_size      = var.disk_size
  labels         = var.node_labels
  tags           = var.node_group_tags
  depends_on = [
    #aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
    #aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly,
    #aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy,
    #aws_eks_cluster.eks_cluster
  ]
}
