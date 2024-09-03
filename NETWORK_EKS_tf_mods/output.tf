##### Network #######
output "vpc_id" {
  value = var.vpc_required ? module.NETWORK[0].vpc_id : ""
}

output "public_subnet_ids" {
  value = var.vpc_required ? module.NETWORK[0].public_subnet_ids_map : {}
}

output "private_subnet_ids" {
  value = var.vpc_required ? module.NETWORK[0].private_subnet_ids_map : {}
}

output "nat_gateway_eip" {
  value = { for key, nat in module.NAT : key => nat.nat_gateway_eip if var.vpc_required}
}



# ### EKS cluster ###
# output "eks_cluster_endpoint" {
#   value = module.EKS_CLUSTER.cluster_endpoint
# }

# output "eks_cluster_arn" {
#   value = module.EKS_CLUSTER.cluster_arn
# }

# output "eks_cluster_version" {
#   value = module.EKS_CLUSTER.cluster_version
# }