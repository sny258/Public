
##### Add-ons for the EKS cluster ########
resource "aws_eks_addon" "addons" {
  cluster_name      = var.cluster_name
  addon_name        = var.addon_name
  addon_version     = var.addon_version
  resolve_conflicts = var.resolve_conflicts
  depends_on = [
    #aws_eks_node_group.eks_node_group
  ]
}