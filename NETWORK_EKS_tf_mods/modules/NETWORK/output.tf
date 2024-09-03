output "vpc_id" {
  value = aws_vpc.vpc.id
}

# output "vpc_default_rt_id" {
#   value = aws_vpc.vpc.default_route_table_id
# }

output "vpc_main_rt_id" {
  value = aws_vpc.vpc.main_route_table_id             #subnets chose main rt by default
}

output "vpc_default_sg_id" {
  value = aws_vpc.vpc.default_security_group_id
}

output "public_subnets" {
  value = var.pub_sub_required ? aws_subnet.public_subnet : {}
}

output "public_subnet_ids" {
  value = var.pub_sub_required ? values(aws_subnet.public_subnet)[*].id : []
}

output "public_subnet_ids_map" {
  value = { for subnet in aws_subnet.public_subnet : subnet.tags.Name => subnet.id }
}


output "pub_sub_rt_id" {
  value = var.pub_sub_required ? aws_route_table.pub_sub_rt[0].id : ""
}

output "private_subnets" {
  value = var.prv_sub_required ? aws_subnet.private_subnet : {}
}


output "private_subnet_ids" {
  value = var.prv_sub_required ? values(aws_subnet.private_subnet)[*].id : []
}

output "private_subnet_ids_map" {
  value = { for subnet in aws_subnet.private_subnet : subnet.tags.Name => subnet.id }
}


