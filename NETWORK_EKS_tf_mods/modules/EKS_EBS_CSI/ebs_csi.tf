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

# ### For EBS CSI Driver #############
# ### Assume role Policy for EBS-CSI-DRIVER ###
# data "aws_iam_policy_document" "ebs_csi_driver_assume_role_policy" {
#   statement {
#     actions = ["sts:AssumeRoleWithWebIdentity"]
#     effect  = "Allow"
#     condition {
#       test     = "StringEquals"
#       #variable = "${replace(local.oidc_identifier_url, "https://", "")}:sub"
#       variable = "${replace(local.oidc_identifier_https, "https://", "")}:sub"
#       values   = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
#     }
#     principals {
#       identifiers = [local.oidc_identifier_arn]
#       type        = "Federated"
#     }
#   }
# }

### IAM ROLE for EBS-CSI-DRIVER ###
resource "aws_iam_role" "ebs_csi_role" {
  #assume_role_policy  = data.aws_iam_policy_document.ebs_csi_driver_assume_role_policy.json
  name                = "${var.cluster_name}-ebs-csi-role"
  assume_role_policy    = jsonencode(
    {
      Statement = [
        {
          Action    = "sts:AssumeRoleWithWebIdentity"
          Condition = {
            StringEquals = {
              "${replace(local.oidc_identifier_https, "https://", "")}:sub" =   "system:serviceaccount:kube-system:ebs-csi-controller-sa"
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

### Policy attachment for EBS_CSI ###
resource "aws_iam_role_policy_attachment" "ebs-csi" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.ebs_csi_role.name
}

### EBS-CSI ###
resource "aws_eks_addon" "ebs_csi" {
  cluster_name              = var.cluster_name  
  service_account_role_arn  = aws_iam_role.ebs_csi_role.arn
  addon_name                = var.addon_name
  addon_version             = var.addon_version
  resolve_conflicts         = var.resolve_conflicts
}