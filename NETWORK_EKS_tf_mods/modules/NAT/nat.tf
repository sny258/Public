
##########################

#Check if EIP needs to be created or not
resource "aws_eip" "eip_nat" {
  count = var.create_eip ? 1 : 0
  vpc   = true
}

##Creating a NAT Gateway for private subnets
resource "aws_nat_gateway" "nat" {
  allocation_id = var.create_eip ? aws_eip.eip_nat[0].id : var.eip_allocation_id
  subnet_id     = var.public_subnet_details[var.nat_pub_subnet].id
  tags = {
    Name = var.nat_name
  }
}


##Creating a Route Table for the Nat Gateway!
resource "aws_route_table" "nat_rt" {
  vpc_id = var.vpc_id
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
  tags = {
    Name = var.nat_rt_name
  }
  depends_on = [
    aws_nat_gateway.nat
  ]
}


## NAT route table association to private subnets
resource "aws_route_table_association" "nat_rt_association" {
  for_each       = { for idx, value in var.nat_prv_subnet : idx => value }
  subnet_id      = var.private_subnet_details[each.value].id
  route_table_id = aws_route_table.nat_rt.id
  depends_on = [
    aws_route_table.nat_rt
  ]
}