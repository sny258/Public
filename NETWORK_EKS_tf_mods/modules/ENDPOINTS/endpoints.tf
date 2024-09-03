
##########################

resource "aws_vpc_endpoint" "interface" {
  for_each    = { for vpc_endp in var.vpc_private_endpoints : vpc_endp.endpoint_name => vpc_endp if vpc_endp.endpoint_type == "Interface" }
  vpc_id              = var.vpc_id
  service_name        = each.value.service_name
  vpc_endpoint_type   = each.value.endpoint_type
  subnet_ids          = var.subnet_ids
  security_group_ids  = [
    var.security_group_id
  ]
  private_dns_enabled = true
  #ip_address_type     = "ipv4"
  tags = {
    Name = each.value.endpoint_name
  }
}


data "aws_route_tables" "vpc_route_tables" {
  vpc_id = var.vpc_id
}

locals {
  route_table_ids_concatenated = join(",", data.aws_route_tables.vpc_route_tables.ids)
}

resource "aws_vpc_endpoint" "gateway" {
  for_each    = { for vpc_endp in var.vpc_private_endpoints : vpc_endp.endpoint_name => vpc_endp if vpc_endp.endpoint_type == "Gateway" }
  vpc_id            = var.vpc_id
  service_name      = each.value.service_name
  vpc_endpoint_type = each.value.endpoint_type
  route_table_ids   = data.aws_route_tables.vpc_route_tables.ids
  tags = {
    Name = each.value.endpoint_name
  }
}


locals {
  required_endpoint_count = length([for endpoint in var.vpc_private_endpoints : endpoint.endpoint_name])   
}

#Add 443 inbound from VPC CIDR to default SG of VPC for Endpoints
resource "aws_default_security_group" "vpc_default_sg" {
  count = local.required_endpoint_count > 1 ? 1 : 0
  vpc_id = var.vpc_id
  ingress {
    protocol  = -1
    self      = true
    from_port = 0
    to_port   = 0
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}