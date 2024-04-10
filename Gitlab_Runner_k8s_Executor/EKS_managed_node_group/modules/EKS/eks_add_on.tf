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


### VPC-CNI ###
resource "aws_eks_addon" "vpc_cni" {
  cluster_name        = aws_eks_cluster.eks_cluster.name
  addon_name          = "vpc-cni"
  #addon_version      = "v1.15.4-eksbuild.1"
  #resolve_conflicts  = "OVERWRITE"
}

### Kube-Proxy ###
resource "aws_eks_addon" "kube_proxy" {
  cluster_name        = aws_eks_cluster.eks_cluster.name
  addon_name          = "kube-proxy"
  #addon_version      = "v1.28.2-eksbuild.2" 
  #resolve_conflicts  = "OVERWRITE"
}

### Core-DNS ###
resource "aws_eks_addon" "coredns" {
  cluster_name        = aws_eks_cluster.eks_cluster.name
  addon_name          = "coredns"
  #addon_version      = "v1.10.1-eksbuild.6"
  #resolve_conflicts  = "OVERWRITE"
  depends_on = [
    aws_eks_node_group.eks_node_group
  ]
}


#### For EBS CSI Driver #############
### Assume role Policy for EBS-CSI-DRIVER ###
data "aws_iam_policy_document" "csi_driver_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"
    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
    }
    principals {
      identifiers = [aws_iam_openid_connect_provider.eks.arn]
      type        = "Federated"
    }
  }
}

### IAM ROLE for EBS-CSI-DRIVER ###
resource "aws_iam_role" "ebs_csi_role" {
  assume_role_policy  = data.aws_iam_policy_document.csi_driver_assume_role_policy.json
  #name               = "gwl-gitlab-runner-eu-central-1-ebs-csi-role"
  name                = "${var.cluster_name}-ebs-csi-role"
}

### Policy attachment for EBS_CSI ###
resource "aws_iam_role_policy_attachment" "ebs-csi" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.ebs_csi_role.name
}

### EBS-CSI ###
resource "aws_eks_addon" "ebs_csi" {
  cluster_name              = aws_eks_cluster.eks_cluster.name  
  service_account_role_arn  = aws_iam_role.ebs_csi_role.arn
  addon_name                = "aws-ebs-csi-driver"
  #addon_version            = "v1.25.0-eksbuild.1"
  #resolve_conflicts        = "OVERWRITE"
  depends_on = [
    aws_eks_node_group.eks_node_group
  ]
}




#### For EFS CSI Driver #############
### Assume role Policy for EFS-CSI-DRIVER ###
data "aws_iam_policy_document" "efs_csi_driver_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"
    condition {
      test     = "StringLike"
      variable = "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:efs-csi-*"]
    }
    condition {
      test     = "StringLike"
      variable = "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }
    principals {
      identifiers = [aws_iam_openid_connect_provider.eks.arn]
      type        = "Federated"
    }
  }
}

### IAM ROLE for EFS-CSI-DRIVER ###
resource "aws_iam_role" "efs_csi_role" {
  assume_role_policy  = data.aws_iam_policy_document.efs_csi_driver_assume_role_policy.json
  name                = "${var.cluster_name}-efs-csi-role"
}

### Policy attachment for EFS_CSI ###
resource "aws_iam_role_policy_attachment" "efs-csi" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEFSCSIDriverPolicy"
  role       = aws_iam_role.efs_csi_role.name
}

### EFS-CSI ###
resource "aws_eks_addon" "efs_csi" {
  cluster_name              = aws_eks_cluster.eks_cluster.name  
  service_account_role_arn  = aws_iam_role.efs_csi_role.arn
  addon_name                = "aws-efs-csi-driver"
  #addon_version            = "v1.25.0-eksbuild.1"
  #resolve_conflicts        = "OVERWRITE"
  depends_on = [
    aws_eks_node_group.eks_node_group
  ]
}
