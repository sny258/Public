terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
  #  backend "s3" {
  #    bucket = "terraform-statefile-gitlabrunner"
  #    key    = "statefile/k8gitlabrunner.tfstate"
  #    region = "eu-west-1"
  #    encrypt = true
  #  }
}

# Configure the AWS Provider
provider "aws" {
  region = var.region
}


################################################
##########################

module "NETWORK" {
  source             = "./modules/NETWORK"
  count              = var.vpc_required ? 1 : 0
  vpc_name           = var.vpc_details["vpc_name"]
  vpc_cidr           = var.vpc_details["vpc_cidr"]
  pub_sub_required   = var.pub_sub_required
  pub_sub_details    = var.pub_sub_details
  igw_name           = var.igw_name
  pub_sub_rt_name    = var.pub_sub_rt_name
  #####################################
  prv_sub_required   = var.prv_sub_required
  prv_sub_details    = var.prv_sub_details
  ##########################################
  nat_required       = var.nat_required
}


module "NAT" {
  source                 = "./modules/NAT"
  for_each               =  { for nat in var.nat_details : nat.nat_name => nat if var.vpc_required == true && var.nat_required == true }
  vpc_id                 = module.NETWORK[0].vpc_id
  private_subnet_details = module.NETWORK[0].private_subnets
  public_subnet_details  = module.NETWORK[0].public_subnets
  main_route_table_id    = module.NETWORK[0].vpc_main_rt_id
  ###################################
  create_eip         = each.value.create_eip
  eip_allocation_id  = each.value.eip_allocation_id
  nat_name           = each.value.nat_name
  nat_pub_subnet     = each.value.nat_pub_subnet
  nat_rt_name        = each.value.nat_rt_name
  nat_prv_subnet     = each.value.nat_prv_subnet
  depends_on = [
    module.NETWORK
  ]
}



## A VPC endpoint is a connection between your VPC and other AWS services or AWS Marketplace partner services without requiring internet access.
## It allows you to privately access services hosted on AWS without needing to traverse the public internet, and consequently without the need of the NAT Gateways. External calls will still be handled by NAT Gateways though.
## Interface endpoints supports 1 subnet each AZ.
module "ENDPOINTS" {
  source                 = "./modules/ENDPOINTS"
  count                  = var.vpc_endpoint_required ? 1 : 0
  vpc_id                 = var.vpc_required ? module.NETWORK[0].vpc_id : var.endpoint_vpc_details.vpc_id
  subnet_ids             = var.vpc_required ? (var.nat_required ? module.NETWORK[0].private_subnet_ids : module.NETWORK[0].public_subnet_ids ) : var.endpoint_vpc_details.subnet_ids
  #All route tables are added to s3 endpoint (main, public subent and NAT) in module itself
  #route_table_id         = var.nat_required ? module.NETWORK.nat_rt_id : module.NETWORK.pub_sub_rt_id
  security_group_id      = var.vpc_required ? module.NETWORK[0].vpc_default_sg_id : var.endpoint_vpc_details.security_group_id
  vpc_private_endpoints  = var.vpc_private_endpoints
  vpc_cidr               = var.vpc_required ? var.vpc_details["vpc_cidr"] : var.endpoint_vpc_details.vpc_cidr
  depends_on = [
    module.NAT
  ]
}



### Iam roles ###
module "IAM" {
  source                 = "./modules/IAM"
  cluster_name           = var.eks_cluster_config.cluster_name
  #eks_cluster_role_tags  = var.eks_cluster_tags
}


### EKS cluster ###
module "EKS_CLUSTER" {
  source                           = "./modules/EKS_CLUSTER"
  cluster_name                     = var.eks_cluster_config.cluster_name
  cluster_version                  = var.eks_cluster_config.cluster_version
  cluster_role_arn                 = module.IAM.eks_cluster_role_arn
  subnet_ids                       = var.vpc_required ? (var.nat_required ? module.NETWORK[0].private_subnet_ids : module.NETWORK[0].public_subnet_ids) : var.subnet_ids
  cluster_endpoint_private_access  = var.eks_cluster_config.cluster_endpoint_private_access
  cluster_endpoint_public_access   = var.eks_cluster_config.cluster_endpoint_public_access
  cluster_public_access_cidrs      = var.eks_cluster_config.cluster_public_access_cidrs
  #Any var not sent from here, will take modules var's value for provisioning
  #cluster_ip_family               = var.eks_cluster_config.cluster_ip_family
  #cluster_service_ipv4_cidr       = var.eks_cluster_config.cluster_service_ipv4_cidr
  eks_cluster_tags                 = var.eks_cluster_tags
  depends_on = [
    module.NETWORK,
    module.NAT,
    module.IAM
  ]
}


## EKS node group requires subnets with internet access
### EKS node group ###
module "EKS_NODE_GROUP" {
  source             = "./modules/EKS_NODE_GROUP"
  for_each           =  { for ng in var.eks_node_group : ng.node_group_name => ng if var.node_group_required == true }
  cluster_name       = var.eks_cluster_config.cluster_name
  node_group_name    = each.value.node_group_name
  node_role_arn      = module.IAM.node_group_role_arn
  subnet_ids         = var.vpc_required ? (var.nat_required ? module.NETWORK[0].private_subnet_ids : module.NETWORK[0].public_subnet_ids) : var.subnet_ids
  instance_types     = each.value.instance_types
  ami_type           = each.value.ami_type
  capacity_type      = each.value.capacity_type
  disk_size          = each.value.disk_size
  desired_size       = each.value.scaling_config.desired_size
  max_size           = each.value.scaling_config.max_size
  min_size           = each.value.scaling_config.min_size
  max_unavailable    = each.value.update_config.max_unavailable
  node_labels        = each.value.node_labels
  node_group_tags    = each.value.node_group_tags
  depends_on = [
    module.EKS_CLUSTER
  ]
}


## EKS fargate profile not supported on public subnets
### EKS fargate profile ###
module "EKS_FARGATE_PROFILE" {
  source                  = "./modules/EKS_FARGATE_PROFILE"
  for_each                =  { for fg in var.eks_fargate_profile : fg.fargate_profile_name => fg if var.fargate_profile_required == true && var.nat_required == true }
  cluster_name            = var.eks_cluster_config.cluster_name
  fargate_profile_name    = each.value.fargate_profile_name
  subnet_ids              = var.vpc_required ? (var.nat_required ? module.NETWORK[0].private_subnet_ids : module.NETWORK[0].public_subnet_ids) : var.subnet_ids
  pod_execution_role_arn  = module.IAM.fargate_profile_role_arn
  namespace               = each.value.namespace
  pod_labels              = each.value.pod_labels
  fargate_profile_tags    = each.value.fargate_profile_tags
  depends_on = [
    module.EKS_CLUSTER
  ]
}


## EKS node group requires subnets with internet access
### EKS custom node group ###
module "EKS_CUSTOM_NG" {
  source             = "./modules/EKS_CUSTOM_NG"
  for_each           =  { for cng in var.eks_custom_ng : cng.node_group_name => cng if var.custom_ng_required == true }
  ami_id             = each.value.ami_id
  instance_types     = each.value.instance_types
  volume_size        = each.value.volume_size
  volume_type        = each.value.volume_type
  security_group_id  = module.EKS_CLUSTER.eks_default_sg
  ##########################################
  cluster_name       = var.eks_cluster_config.cluster_name
  node_group_name    = each.value.node_group_name
  node_role_arn      = module.IAM.node_group_role_arn
  subnet_ids         = var.vpc_required ? (var.nat_required ? module.NETWORK[0].private_subnet_ids : module.NETWORK[0].public_subnet_ids) : var.subnet_ids
  capacity_type      = each.value.capacity_type
  desired_size       = each.value.scaling_config.desired_size
  max_size           = each.value.scaling_config.max_size
  min_size           = each.value.scaling_config.min_size
  max_unavailable    = each.value.update_config.max_unavailable
  node_labels        = each.value.node_labels
  node_group_tags    = each.value.node_group_tags
  depends_on = [
    module.EKS_CLUSTER
  ]
}


### EKS cluster addon ###
module "EKS_ADDONS" {
  source            = "./modules/EKS_ADDONS"
  #for_each          =  { for addon in var.addons : addon.name => addon if addon.required == true }
  for_each          =  { for addon in var.addons : addon.name => addon }
  cluster_name      = var.eks_cluster_config.cluster_name
  addon_name        = each.value.name
  addon_version     = each.value.version
  resolve_conflicts = each.value.resolve_conflicts
  depends_on = [
    module.EKS_CLUSTER,
    module.EKS_NODE_GROUP,
    module.EKS_CUSTOM_NG
  ]
}


### EBS CSI driver ###
module "EKS_EBS_CSI" {
  source            = "./modules/EKS_EBS_CSI"
  count             = var.ebs_csi_addon.required ? 1 : 0
  cluster_name      = var.eks_cluster_config.cluster_name
  addon_name        = var.ebs_csi_addon.name
  addon_version     = var.ebs_csi_addon.version
  resolve_conflicts = var.ebs_csi_addon.resolve_conflicts
  depends_on = [
    module.EKS_CLUSTER,
    module.EKS_NODE_GROUP,
    module.EKS_CUSTOM_NG
  ]
}


### EBS CSI driver ###
module "EKS_EFS_CSI" {
  source            = "./modules/EKS_EFS_CSI"
  count             = var.efs_csi_addon.required ? 1 : 0
  cluster_name      = var.eks_cluster_config.cluster_name
  addon_name        = var.efs_csi_addon.name
  addon_version     = var.efs_csi_addon.version
  resolve_conflicts = var.efs_csi_addon.resolve_conflicts
  depends_on = [
    module.EKS_CLUSTER,
    module.EKS_NODE_GROUP,
    module.EKS_CUSTOM_NG
  ]
}