resource "aws_db_subnet_group" "nb-db-subnet" {
  depends_on = [aws_subnet.nb-subnet]
  name       = "nb-db-subnet"
  subnet_ids = [
    for key, subnet in var.subnet : aws_subnet.nb-subnet[key].id
    if subnet.type == "private"
  ]

  tags = {
    "Name" = "Private DB Subnet Group"
  }
}


resource "aws_security_group" "rds-sg" {
  depends_on  = [aws_subnet.nb-subnet]
  name        = "rds-sg"
  description = "Security group to allow access rds-subnet from public subnets"
  vpc_id      = aws_vpc.nb-chatgpt-vpc.id

  tags = {
    Name = "rds-server-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow-access-rds" {
  depends_on        = [aws_security_group.rds-sg]
  security_group_id = aws_security_group.rds-sg.id
  cidr_ipv4         = var.vpc_cidr
  from_port         = 3306
  to_port           = 3306
  ip_protocol       = "tcp"
}


resource "aws_db_instance" "nb-db" {
  depends_on                  = [aws_security_group.rds-sg, aws_vpc_security_group_ingress_rule.allow-access-rds]
  allocated_storage           = 10
  db_name                     = "nbdb"
  engine                      = "mysql"
  instance_class              = "db.t3.micro"
  username                    = var.db_credentials.username
  manage_master_user_password = true
  publicly_accessible         = false
  vpc_security_group_ids      = [aws_security_group.rds-sg.id]
  db_subnet_group_name        = aws_db_subnet_group.nb-db-subnet.name
  skip_final_snapshot         = true
}