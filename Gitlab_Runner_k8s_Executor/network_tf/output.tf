# output "eip_a" {
#   value = aws_eip.eip_nat_a.id
# }

# output "eip_b" {
#   value = aws_eip.eip_nat_b.id
# }

output "vpc_id" {
  value = aws_vpc.vpc.id
}

# output "private_subnet_a_id" {
#   value = local.private_subnet_a
# }

# output "private_subnet_b_id" {
#   value = local.private_subnet_b
# }

# output "security_group_id" {
#   value = aws_security_group.gr_sg.id
# }

output "private_subnet_ids" {
  value = values(aws_subnet.private_subnet)[*].id
}