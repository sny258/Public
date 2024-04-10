output "eks_cluster_arn" {
  value = aws_eks_cluster.eks_cluster.arn
}

output "eks_cluster_endpoint" {
  value = aws_eks_cluster.eks_cluster.endpoint
}

output "certificate_authority" {
  value = aws_eks_cluster.eks_cluster.certificate_authority[0].data
}

output "eks_cluster_dns_ip" {
  value = aws_eks_cluster.eks_cluster.kubernetes_network_config[0].service_ipv4_cidr
}
