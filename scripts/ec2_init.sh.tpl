#!/bin/bash

# Basic logging
exec > /var/log/ec2_user_data.log 2>&1
set -eux

# Update system & install dependencies
sudo yum update -y
sudo yum install -y git golang wget

# Install RabbitMQ + Erlang
sudo tee /etc/yum.repos.d/rabbitmq_erlang.repo <<EOF
[rabbitmq_erlang]
name=rabbitmq_erlang
baseurl=https://dl.cloudsmith.io/public/rabbitmq/rabbitmq-erlang/rpm/el/7/\$basearch
gpgcheck=1
gpgkey=https://dl.cloudsmith.io/public/rabbitmq/rabbitmq-erlang/gpg.34B1F9E5.key
enabled=1
EOF

sudo yum install -y erlang

sudo tee /etc/yum.repos.d/rabbitmq.repo <<EOF
[rabbitmq_rabbitmq-server]
name=rabbitmq_rabbitmq-server
baseurl=https://dl.cloudsmith.io/public/rabbitmq/rabbitmq-server/rpm/el/7/\$basearch
gpgcheck=1
gpgkey=https://dl.cloudsmith.io/public/rabbitmq/rabbitmq-server/gpg.B8A7C9F4.key
enabled=1
EOF

sudo yum install -y rabbitmq-server

# Start and enable RabbitMQ
sudo systemctl enable rabbitmq-server
sudo systemctl start rabbitmq-server
sudo rabbitmq-plugins enable rabbitmq_management

# Clone your project repo (replace with your actual Git repo)
cd /home/ec2-user
git clone https://github.com/claireyyu/asynchronous-review-platform.git️
cd asynchronous-review-platform

# Create .env file from Terraform (or use your own)
cat > .env <<EOF
DB_DSN=${db_username}:${db_password}@tcp(${rds_endpoint}):3306/reviews
RABBIT_URL=amqp://guest:guest@localhost:5672/
ASYNC_MODE=true
CONSUMER_COUNT=3
PORT=8080
EOF

# Build and run Go server
cd src/server/go-server/
go run main.go &

# Optional: start monitor script (if it exists)
cd /home/ec2-user/asynchronous-review-platform/scripts
chmod +x monitor.sh
./monitor.sh &

# Done
echo "✅ EC2 server is set up and running"
