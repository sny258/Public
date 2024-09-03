
#### EKS Fargate Profile #########
resource "aws_eks_fargate_profile" "eks_fargate_profile" {
  cluster_name           = var.cluster_name
  fargate_profile_name   = var.fargate_profile_name
  subnet_ids             = var.subnet_ids
  pod_execution_role_arn = var.pod_execution_role_arn
  selector {
    namespace = var.namespace
    labels = var.pod_labels
  }
  // Add more selectors as needed
  tags = var.fargate_profile_tags
  depends_on  = [ 
    #aws_eks_cluster.eks_cluster
  ]
}