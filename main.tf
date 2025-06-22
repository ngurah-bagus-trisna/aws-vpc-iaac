terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "ap-southeast-1"
}

resource "aws_vpc" "nb-chatgpt-vpc" {
  cidr_block = var.vpc_cidr
  tags = {
    "Name" = "nb-chatgpt-vpc"
  }
}

resource "aws_subnet" "nb-subnet" {
  vpc_id   = aws_vpc.nb-chatgpt-vpc.id
  for_each = var.subnet

  cidr_block        = each.value.subnet_range
  availability_zone = each.value.availability_zone
  tags = {
    "Name" = each.key
    "Type" = each.value.type
  }
}

resource "aws_internet_gateway" "nb-inet-gw" {
  vpc_id = aws_vpc.nb-chatgpt-vpc.id

  tags = {
    Name = "nb-inet-gw"
  }
}

resource "aws_eip" "nb-eip-nat-gw" {
  tags = {
    "Name" = "nb-eip-nat-gw"
  }
}

locals {
  public_subnet_ids = [
    for key, subnet in var.subnet : aws_subnet.nb-subnet[key].id
    if subnet.type == "public"
  ]
  private_subnet_ids = [
    for key, subnet in var.subnet : aws_subnet.nb-subnet[key].id
    if subnet.type == "private"
  ]
}

resource "aws_nat_gateway" "nb-nat-gw" {
  depends_on        = [aws_eip.nb-eip-nat-gw]
  allocation_id     = aws_eip.nb-eip-nat-gw.id
  subnet_id         = local.public_subnet_ids[0]
  connectivity_type = "public"
  tags = {
    "Name" : var.natgw_name
  }
}

resource "aws_route_table" "net-public" {
  for_each = var.route_tables
  vpc_id   = aws_vpc.nb-chatgpt-vpc.id

  route {
    cidr_block     = each.value.cidr_source
    gateway_id     = each.value.route_destination == "igw" ? aws_internet_gateway.nb-inet-gw.id : null
    nat_gateway_id = each.value.route_destination == "nat" ? aws_nat_gateway.nb-nat-gw.id : null
  }
}

output "vpc_id" {
  value = aws_vpc.nb-chatgpt-vpc.id
}

output "public_subnet_id" {
  value = local.public_subnet_ids
}

output "private_subnet_id" {
  value = local.private_subnet_ids
}

output "nat_gateway_public_ip" {
  value = aws_nat_gateway.nb-nat-gw.public_ip
}