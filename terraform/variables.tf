variable "aws_region" {
  default = "us-west-2"
}

variable "public_key_path" {
  description = "Path to your local .pub file"
  type        = string
}

variable "ami_id" {
  description = "Amazon Linux 2 AMI ID for your region"
  type        = string
}

variable "db_username" {
  default = "admin"
}

variable "db_password" {
  default = "AsyncStrongPassword123"
}
