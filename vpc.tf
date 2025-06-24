resource "aws_vpc" "nb-chatgpt-vpc" {
  cidr_block = var.vpc_cidr
  tags = {
    "Name" = "nb-chatgpt-vpc"
  }
}

resource "aws_subnet" "nb-subnet" {
  depends_on = [aws_vpc.nb-chatgpt-vpc]
  vpc_id     = aws_vpc.nb-chatgpt-vpc.id
  for_each   = var.subnet

  cidr_block              = each.value.subnet_range
  availability_zone       = each.value.availability_zone
  map_public_ip_on_launch = each.key == "public-net" ? true : false
  tags = {
    "Name" = each.key
    "Type" = each.value.type
  }
}

resource "aws_internet_gateway" "nb-inet-gw" {
  depends_on = [aws_vpc.nb-chatgpt-vpc]
  vpc_id     = aws_vpc.nb-chatgpt-vpc.id

  tags = {
    Name = "nb-inet-gw"
  }
}

resource "aws_eip" "nb-eip-nat-gw" {
  depends_on = [aws_internet_gateway.nb-inet-gw]
  tags = {
    "Name" = "nb-eip-nat-gw"
  }
}


resource "aws_nat_gateway" "nb-nat-gw" {
  depends_on        = [aws_eip.nb-eip-nat-gw]
  allocation_id     = aws_eip.nb-eip-nat-gw.id
  subnet_id         = aws_subnet.nb-subnet["public-net"].id
  connectivity_type = "public"
  tags = {
    "Name" : var.natgw_name
  }
}


resource "aws_route_table" "public" {
  vpc_id = aws_vpc.nb-chatgpt-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.nb-inet-gw.id
  }

  tags = {
    Name = "public-rt"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.nb-subnet["public-net"].id
  route_table_id = aws_route_table.public.id
}


resource "aws_route_table" "private" {
  vpc_id = aws_vpc.nb-chatgpt-vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nb-nat-gw.id
  }

  tags = {
    Name = "private-rt"
  }
}

resource "aws_route_table_association" "private" {
  for_each = {
    for key, subnet in var.subnet :
    key => subnet
    if subnet.type == "private"
  }

  subnet_id      = aws_subnet.nb-subnet[each.key].id
  route_table_id = aws_route_table.private.id
}

resource "aws_security_group" "web-sg" {
  depends_on = [aws_subnet.nb-subnet]

  name        = "web-sg"
  description = "Security group to allow access port 22"
  vpc_id      = aws_vpc.nb-chatgpt-vpc.id

  tags = {
    "Name" : "web-server-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow-access-ssh" {
  depends_on = [aws_security_group.web-sg]

  security_group_id = aws_security_group.web-sg.id
  cidr_ipv4         = "0.0.0.0/0"
  to_port           = 22
  from_port         = 22
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "allow-access-public" {
  depends_on        = [aws_security_group.web-sg]
  security_group_id = aws_security_group.web-sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # -1 means all protocols
}