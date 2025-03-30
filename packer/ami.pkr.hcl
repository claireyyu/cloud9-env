packer {
  required_plugins {
    amazon = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

source "amazon-ebs" "hw8-go-server" {
  region                 = "us-west-2"
  instance_type          = "t3.micro"
  ssh_username           = "ec2-user"
  ami_name               = "hw8-go-ami-{{timestamp}}"
  source_ami_filter {
    filters = {
      name                = "amzn2-ami-hvm-2.0.*-x86_64-gp2"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    owners      = ["amazon"]
    most_recent = true
  }
}

build {
  name    = "build-go-ami"
  sources = ["source.amazon-ebs.hw8-go-server"]

  provisioner "shell" {
    inline = [
      "sudo yum update -y",
      "sudo yum install -y git",
      "curl -OL https://go.dev/dl/go1.21.0.linux-amd64.tar.gz",
      "sudo tar -C /usr/local -xzf go1.21.0.linux-amd64.tar.gz",
      "echo 'export PATH=$PATH:/usr/local/go/bin' | sudo tee /etc/profile.d/go.sh",
      "sudo chmod 644 /etc/profile.d/go.sh"
    ]
  }
}
