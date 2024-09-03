
### EKS cluster ###
resource "aws_eks_cluster" "eks_cluster" {
  name                      = var.cluster_name
  role_arn                  = var.cluster_role_arn
  version                   = var.cluster_version
  vpc_config {
   subnet_ids               = var.subnet_ids
   endpoint_private_access  = var.cluster_endpoint_private_access
   endpoint_public_access   = var.cluster_endpoint_public_access
   public_access_cidrs      = var.cluster_endpoint_public_access ? var.cluster_public_access_cidrs : []
  }
  kubernetes_network_config {
    ip_family         = var.cluster_ip_family
    service_ipv4_cidr = var.cluster_service_ipv4_cidr
  }
  #enabled_cluster_log_types = ["api","audit",]
  tags = var.eks_cluster_tags
  depends_on = [
    #aws_iam_role_policy_attachment.AmazonEKSClusterPolicy,
    #aws_iam_role_policy_attachment.AmazonEKSVPCResourceController
  ]
}

### OIDC Provider ###
data "tls_certificate" "eks" {
  url = aws_eks_cluster.eks_cluster.identity[0].oidc[0].issuer
}

### OIDC issuer ###
resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.eks_cluster.identity[0].oidc[0].issuer
}