##########
output "nat_rt_id" {
  value = aws_route_table.nat_rt.id
}

output "nat_gateway_eip" {
  value = var.create_eip ? aws_eip.eip_nat[0].public_ip : ""
}

