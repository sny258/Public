output "eks_cluster_role_arn" {
  value = aws_iam_role.iam_cluster_role.arn
}

output "node_group_role_arn" {
  value = aws_iam_role.eks_nodegroup_role.arn
}