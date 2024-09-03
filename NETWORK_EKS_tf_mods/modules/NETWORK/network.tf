
##########################
##Creating a VPC!
resource "aws_vpc" "vpc" {
  cidr_block = var.vpc_cidr
  enable_dns_hostnames = true
  tags = {
    Name = var.vpc_name
  }
}

##Creating Public subnet/s
resource "aws_subnet" "public_subnet" {
  for_each    = { for pub_sub in var.pub_sub_details : pub_sub.name => pub_sub if var.pub_sub_required }
  vpc_id      = aws_vpc.vpc.id
  cidr_block  = each.value.cidr
  availability_zone = each.value.az
  map_public_ip_on_launch = true
  tags = {
    Name = each.value.name
  }
  depends_on = [
    aws_vpc.vpc
  ]
}

##Creating an Internet Gateway for the VPC --> will be used for public subnets to access Internet
resource "aws_internet_gateway" "igw" {
  count  = var.pub_sub_required ? 1 : 0
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = var.igw_name
  }
  depends_on = [
    aws_vpc.vpc
  ]
}

##Creating an Route Table for the public subnet/s
resource "aws_route_table" "pub_sub_rt" {
  count  = var.pub_sub_required ? 1 : 0
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw[0].id
  }
  tags = {
    Name = var.pub_sub_rt_name
  }
  depends_on = [
    aws_vpc.vpc,
    aws_internet_gateway.igw
  ]
}

##Public Route Table Association to public_subnets
resource "aws_route_table_association" "pub_rt_association" {
  #for_each       = aws_subnet.public_subnet
  for_each       = { for key, value in aws_subnet.public_subnet : key => value if var.pub_sub_required }
  subnet_id      = each.value.id
  route_table_id = aws_route_table.pub_sub_rt[0].id
  depends_on = [
    aws_vpc.vpc,
    aws_route_table.pub_sub_rt,
    aws_subnet.public_subnet,
  ]
}



##Creating Private subnet/s
resource "aws_subnet" "private_subnet" {
  for_each    = { for prv_sub in var.prv_sub_details : prv_sub.name => prv_sub if var.prv_sub_required }
  vpc_id      = aws_vpc.vpc.id
  cidr_block  = each.value.cidr
  availability_zone = each.value.az
  tags = {
    Name = each.value.name
  }
  depends_on = [
    aws_vpc.vpc,
  ]
}


## Main route table association to private subnets
resource "aws_route_table_association" "prv_rt_association" {
  #for_each       = aws_subnet.private_subnet
  for_each       = { for key, value in aws_subnet.private_subnet : key => value if var.prv_sub_required && var.nat_required == false }
  subnet_id      = each.value.id
  route_table_id = aws_vpc.vpc.main_route_table_id
  depends_on = [
    aws_subnet.private_subnet
  ]
}