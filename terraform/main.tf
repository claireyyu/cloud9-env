provider "aws" {
  region = "us-west-2"
}

####################
# VPC & Subnet
####################
resource "aws_vpc" "main_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = { Name = "hw8-vpc" }
}

resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main_vpc.id
}

resource "aws_subnet" "main_subnet" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-west-2a"
}

resource "aws_route_table" "main_rt" {
  vpc_id = aws_vpc.main_vpc.id
}

resource "aws_route" "default" {
  route_table_id         = aws_route_table.main_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main_igw.id
}

resource "aws_route_table_association" "main_assoc" {
  subnet_id      = aws_subnet.main_subnet.id
  route_table_id = aws_route_table.main_rt.id
}

####################
# Security Groups
####################
resource "aws_security_group" "ec2_sg" {
  name        = "hw8-ec2-sg"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "rds_sg" {
  name        = "hw8-rds-sg"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

####################
# RDS
####################
resource "aws_db_subnet_group" "main" {
  name       = "hw8-db-subnet"
  subnet_ids = [aws_subnet.main_subnet.id]
}

resource "aws_db_instance" "mysql" {
  identifier             = "hw8-mysql"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  skip_final_snapshot    = true
  publicly_accessible    = true
}

####################
# EC2
####################
data "template_file" "user_data" {
  template = file("${path.module}/../scripts/ec2_init.sh.tpl")
  vars = {
    db_username  = var.db_username
    db_password  = var.db_password
    db_endpoint  = aws_db_instance.mysql.address
  }
}

resource "aws_instance" "go_server" {
  ami                         = var.ami_id
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.main_subnet.id
  vpc_security_group_ids      = [aws_security_group.ec2_sg.id]
  associate_public_ip_address = true
  user_data                   = data.template_file.user_data.rendered
  tags = {
    Name = "hw8-go-server"
  }
}

####################
# Outputs
####################
output "ec2_ip" {
  value = aws_instance.go_server.public_ip
}

output "rds_endpoint" {
  value = aws_db_instance.mysql.address
}
