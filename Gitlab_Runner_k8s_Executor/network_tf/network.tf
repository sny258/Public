terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
#  backend "s3" {
#    bucket = "terraform-statefile-gitlabrunner"
#    key    = "state/gitlabrunner.tfstate"
#    region = "eu-west-1"
#    encrypt = true
#    #dynamodb_table = "gitlabrunner-ddbt"					#for locking execution
#  }
}

# Configure the AWS Provider
provider "aws" {
  region = var.location
#  access_key = "my-access-key"
#  secret_key = "my-secret-key"
}




######### Region & Network Vars #########
variable "location" {
  description = "The location/region where resources/infrastructure will be created."
  default     = "eu-west-1"
}

variable "vpc_cidr" {
  type        = string
  default     = "10.34.0.0/23"
}

variable "subnet_cidr" {
  type = list(object({
    cidr    = string
    name    = string
    az      = string
  }))
  default = [
    {
      cidr  = "10.34.0.0/25"
      name  = "gwl-gitlab-runners-public-subnet1"
      az    = "eu-west-1a"
    },
    {
      cidr  = "10.34.1.0/25"
      name  = "gwl-gitlab-runners-private-subnet1"
      az    = "eu-west-1a"
    },
    {
      cidr  = "10.34.0.128/25"
      name  = "gwl-gitlab-runners-public-subnet2"
      az    = "eu-west-1b"
    },
    {
      cidr  = "10.34.1.128/25"
      name  = "gwl-gitlab-runners-private-subnet2"
      az    = "eu-west-1b"
    }
  ]
}

# variable "elastic_ip" {
#   type        = string
#   default     = "10.39.132.82/32"
# }



##########################
##Creating a VPC!
resource "aws_vpc" "vpc" {
  cidr_block = var.vpc_cidr           # IP Range for the VPC
  tags = {
    Name = "gwl-gitlab-runners-vpc"
  }
}

##Creating Public subnet!
resource "aws_subnet" "subnet" {
  for_each    = { for subnet_cidr in var.subnet_cidr : subnet_cidr.name => subnet_cidr }
  vpc_id = aws_vpc.vpc.id
  cidr_block = each.value.cidr
  availability_zone = each.value.az
  tags = {
    Name = each.value.name
  }
  depends_on = [
    aws_vpc.vpc
  ]
}

##Creating an Internet Gateway for the VPC
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "gwl-gitlab-runners-vpc-igw"
  }
  depends_on = [
    aws_vpc.vpc,
    aws_subnet.subnet
  ]
}

##Creating an Route Table for the public subnet!
resource "aws_route_table" "pub_sub_rt" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "gwl-gitlab-runners-pub_sub-rt"
  }
  depends_on = [
    aws_vpc.vpc,
    aws_internet_gateway.igw
  ]
}


##Getting Public subnets only for RT association
locals {
  public_subnet_a = join(",", [for name, sub in aws_subnet.subnet : sub.id if lookup(sub.tags, "Name", "") == "gwl-gitlab-runners-public-subnet1"])
  public_subnet_b = join(",", [for name, sub in aws_subnet.subnet : sub.id if lookup(sub.tags, "Name", "") == "gwl-gitlab-runners-public-subnet2"])
  private_subnet_a = join(",", [for name, sub in aws_subnet.subnet : sub.id if lookup(sub.tags, "Name", "") == "gwl-gitlab-runners-private-subnet1"])
  private_subnet_b = join(",", [for name, sub in aws_subnet.subnet : sub.id if lookup(sub.tags, "Name", "") == "gwl-gitlab-runners-private-subnet2"])
}


##Public Route Table Association to public_subnet_a (AZ "eu-west-1a)"
resource "aws_route_table_association" "rt_association_a" {
  #for_each = { for id in local.public_subnets : id => id }
  subnet_id      = local.public_subnet_a
  route_table_id = aws_route_table.pub_sub_rt.id
  depends_on = [
    aws_vpc.vpc,
    aws_route_table.pub_sub_rt,
    aws_subnet.subnet,
  ]
}

##Public Route Table Association to public_subnet_b (AZ "eu-west-1b)"
resource "aws_route_table_association" "rt_association_b" {
  #for_each = { for id in local.public_subnets : id => id }
  subnet_id      = local.public_subnet_b
  route_table_id = aws_route_table.pub_sub_rt.id
  depends_on = [
    aws_vpc.vpc,
    aws_route_table.pub_sub_rt,
    aws_subnet.subnet,
  ]
}



##Setting up NAT gateway for private subnet in AZ "eu-west-1a"!
##Creating an Elastic IP for the NAT Gateway in AZ "eu-west-1a"!
resource "aws_eip" "eip_nat_a" {
  depends_on = [
    aws_route_table_association.rt_association_a,
    aws_route_table_association.rt_association_b
  ]
  vpc = true
}

##Creating a NAT Gateway for AZ "eu-west-1a"!
resource "aws_nat_gateway" "nat_a" {
  allocation_id = aws_eip.eip_nat_a.id
  subnet_id     = local.public_subnet_a
  tags = {
    Name = "gwl-gitlab-runners-nat-a"
  }
  depends_on = [
    aws_eip.eip_nat_a
  ]
}

##Creating a Route Table for the Nat Gateway!
resource "aws_route_table" "nat_a_rt" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_a.id
  }
  tags = {
    Name = "gwl-gitlab-runners-nat-a-rt"
  }
  depends_on = [
    aws_nat_gateway.nat_a
  ]
}

##Route Table Association of the NAT Gateway route table with the Private Subnet of "eu-west-1a"
resource "aws_route_table_association" "nat_a_association" {
  subnet_id      = local.private_subnet_a
  route_table_id = aws_route_table.nat_a_rt.id
  depends_on = [
    aws_route_table.nat_a_rt
  ]
}




##Setting up NAT gateway for private subnet in AZ "eu-west-1b"!
##Creating an Elastic IP for the NAT Gateway in AZ "eu-west-1b"!
resource "aws_eip" "eip_nat_b" {
  depends_on = [
    aws_route_table_association.rt_association_a,
    aws_route_table_association.rt_association_b
  ]
  vpc = true
}

##Creating a NAT Gateway for AZ "eu-west-1b"!
resource "aws_nat_gateway" "nat_b" {
  allocation_id = aws_eip.eip_nat_b.id
  subnet_id     = local.public_subnet_b
  tags = {
    Name = "gwl-gitlab-runners-nat-b"
  }
  depends_on = [
    aws_eip.eip_nat_b
  ]
}

##Creating a Route Table for the Nat Gateway!
resource "aws_route_table" "nat_b_rt" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_b.id
  }
  tags = {
    Name = "gwl-gitlab-runners-nat-b-rt"
  }
  depends_on = [
    aws_nat_gateway.nat_b
  ]
}

##Route Table Association of the NAT Gateway route table with the Private Subnet of "eu-west-1b"
resource "aws_route_table_association" "nat_b_association" {
  subnet_id      = local.private_subnet_b
  route_table_id = aws_route_table.nat_b_rt.id
  depends_on = [
    aws_route_table.nat_b_rt
  ]
}






##Creating a Security group for Nodes
resource "aws_security_group" "gr_sg" {
  name = "gwl-gitlab-runner-sg"
  vpc_id = aws_vpc.vpc.id
  # Created an inbound rule for webserver access!
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks =["212.247.19.62/32"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks =["212.247.19.62/32"]
  }
  # Outward Network Traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  depends_on = [
    aws_vpc.vpc,
    aws_subnet.subnet
  ]
}




#######################

output "eip_a" {
  value = aws_eip.eip_nat_a.id
}

output "eip_b" {
  value = aws_eip.eip_nat_b.id
}

output "vpc_id" {
  value = aws_vpc.vpc.id
}

output "private_subnet_a_id" {
  value = local.private_subnet_a
}

output "private_subnet_b_id" {
  value = local.private_subnet_b
}

output "security_group_id" {
  value = aws_security_group.gr_sg.id
}

