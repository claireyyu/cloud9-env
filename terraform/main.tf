provider "aws" {
  region = var.aws_region
}

# 1️⃣ 生成 SSH Key Pair（用于连接 EC2）
resource "aws_key_pair" "default" {
  key_name   = "hw8-key"
  public_key = file(var.public_key_path)
}

# 2️⃣ 创建 Security Group（开放 SSH, HTTP, MySQL）
resource "aws_security_group" "hw8_sg" {
  name        = "hw8-sg"
  description = "Allow SSH, HTTP (8080) and MySQL (3306)"

  ingress {
    description = "Allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTP"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow MySQL"
    from_port   = 3306
    to_port     = 3306
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

# 3️⃣ 创建 RDS（MySQL）
resource "aws_db_instance" "review_db" {
  identifier         = "hw8-review-db"
  allocated_storage  = 20
  engine             = "mysql"
  engine_version     = "8.0"
  instance_class     = "db.t3.micro"
  name               = "reviews"
  username           = var.db_username
  password           = var.db_password
  publicly_accessible = true
  skip_final_snapshot = true

  vpc_security_group_ids = [aws_security_group.hw8_sg.id]
}

# 4️⃣ 渲染 EC2 启动脚本（填入 RDS 地址）
data "template_file" "ec2_user_data" {
  template = file("${path.module}/../scripts/ec2_init.sh.tpl")
  vars = {
    db_username  = var.db_username
    db_password  = var.db_password
    rds_endpoint = aws_db_instance.review_db.endpoint
  }
}

# 5️⃣ 创建 EC2 实例（应用 + RabbitMQ）
resource "aws_instance" "go_server" {
  ami                         = var.ami_id
  instance_type               = "t3.micro"
  key_name                    = aws_key_pair.default.key_name
  vpc_security_group_ids      = [aws_security_group.hw8_sg.id]
  associate_public_ip_address = true

  user_data = data.template_file.ec2_user_data.rendered

  tags = {
    Name = "hw8-go-server"
  }
}

# 6️⃣ 输出：连接信息
output "ec2_public_ip" {
  value = aws_instance.go_server.public_ip
}

output "rds_endpoint" {
  value = aws_db_instance.review_db.endpoint
}
