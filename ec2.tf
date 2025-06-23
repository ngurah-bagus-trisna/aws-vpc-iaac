
resource "aws_network_interface" "instance-interface" {
  depends_on      = [aws_subnet.nb-subnet]
  for_each        = var.instance
  subnet_id       = aws_subnet.nb-subnet[each.value.subnet].id
  security_groups = [aws_security_group.web-sg.id]

  tags = {
    "Name" = "interface ${each.key}"
  }
}

resource "aws_instance" "nb-instance" {
  for_each   = var.instance
  depends_on = [aws_network_interface.instance-interface]

  ami           = each.value.ami
  instance_type = each.value.instance_type
  key_name      = "nb-key"

  network_interface {
    network_interface_id = aws_network_interface.instance-interface[each.key].id
    device_index         = 0
  }

  tags = {
    "Name" = "Instance - ${each.key}"
  }
}