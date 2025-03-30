#!/bin/bash

# 输出日志
exec > /var/log/user-data.log 2>&1
set -eux

# 安装 Docker（预防你用 Docker 启动 MQ）
sudo yum update -y
sudo yum install -y docker git
sudo systemctl enable docker
sudo systemctl start docker

# 安装 Go（如果 AMI 里没有你也可以留着）
curl -OL https://go.dev/dl/go1.21.0.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.21.0.linux-amd64.tar.gz
echo 'export PATH=$PATH:/usr/local/go/bin' | tee -a ~/.bashrc
source ~/.bashrc

# 拉取你的 Go 服务代码（替换成你自己的 repo）
cd /home/ec2-user
git clone https://github.com/your-username/asynchronous-review-platform.git
cd asynchronous-review-platform

# 设置环境变量
cat > .env <<EOF
DB_DSN=${db_username}:${db_password}@tcp(${db_endpoint}):3306/reviews
RABBIT_URL=amqp://guest:guest@localhost:5672/
ASYNC_MODE=true
CONSUMER_COUNT=3
PORT=8080
EOF

export $(cat .env | xargs)

# 运行你的 Go 服务（假设 main.go 在根目录）
go run main.go > server.log 2>&1 &
