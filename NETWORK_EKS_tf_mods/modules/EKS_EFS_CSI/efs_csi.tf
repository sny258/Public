#Caller Identity provider
data "aws_caller_identity" "current" {}

#EKS cluster
data "aws_eks_cluster" "eks" {
  name = var.cluster_name
}

locals{
  oidc_identifier_https = data.aws_eks_cluster.eks.identity[0].oidc[0].issuer
  oidc_identifier_url = replace(local.oidc_identifier_https, "https://", "")
  oidc_identifier_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${local.oidc_identifier_url}"
}

# ### For EFS CSI Driver #############
# ### Assume role Policy for EFS-CSI-DRIVER ###
# data "aws_iam_policy_document" "efs_csi_driver_assume_role_policy" {
#   statement {
#     actions = ["sts:AssumeRoleWithWebIdentity"]
#     effect  = "Allow"
#     condition {
#       test     = "StringLike"
#       variable = "${replace(local.oidc_identifier_https, "https://", "")}:sub"
#       values   = ["system:serviceaccount:kube-system:efs-csi-*"]
#     }
#     condition {
#       test     = "StringLike"
#       variable = "${replace(local.oidc_identifier_https, "https://", "")}:aud"
#       values   = ["sts.amazonaws.com"]
#     }
#     principals {
#       identifiers = [local.oidc_identifier_arn]
#       type        = "Federated"
#     }
#   }
# }

### IAM ROLE for EFS-CSI-DRIVER ###
resource "aws_iam_role" "efs_csi_role" {
  #assume_role_policy  = data.aws_iam_policy_document.efs_csi_driver_assume_role_policy.json
  name                = "${var.cluster_name}-efs-csi-role"
  assume_role_policy    = jsonencode(
    {
      Statement = [
        {
          Action    = "sts:AssumeRoleWithWebIdentity"
          Condition = {
            StringLike = {
              "${replace(local.oidc_identifier_https, "https://", "")}:aud" = "sts.amazonaws.com"
              "${replace(local.oidc_identifier_https, "https://", "")}:sub" =   "system:serviceaccount:kube-system:efs-csi-*"
            }
          }
          Effect    = "Allow"
          Principal = {
            Federated = "${local.oidc_identifier_arn}"
          }
        }
      ]
      Version   = "2012-10-17"
    }
  )
}

### Policy attachment for EFS_CSI ###
resource "aws_iam_role_policy_attachment" "efs-csi" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEFSCSIDriverPolicy"
  role       = aws_iam_role.efs_csi_role.name
}

### EFS-CSI ###
resource "aws_eks_addon" "efs_csi" {
  cluster_name              = var.cluster_name  
  service_account_role_arn  = aws_iam_role.efs_csi_role.arn
  addon_name                = var.addon_name
  addon_version             = var.addon_version
  resolve_conflicts         = var.resolve_conflicts
}
