output "vpc_id" {
  value = aws_vpc.nb-chatgpt-vpc.id
}

output "public_subnet_id" {
  value = aws_subnet.nb-subnet["public-net"].id
}

output "private_subnet_id" {
  value = aws_subnet.nb-subnet["private-net-1"].id
}


output "nat_gateway_public_ip" {
  value = aws_nat_gateway.nb-nat-gw.public_ip
}


output "acces_instance" {
  value = aws_instance.nb-instance["web-public"].public_ip
}