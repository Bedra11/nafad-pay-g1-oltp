variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "eu-west-3"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium"
}

variable "ami_id" {
  description = "AMI ID for Ubuntu 22.04 LTS in eu-west-3"
  type        = string
  default     = "ami-08461dc8cd9e834e0"
  # Ubuntu 22.04 LTS — eu-west-3 (Paris)
  # Update if needed: https://cloud-images.ubuntu.com/locator/ec2/
}

variable "key_name" {
  description = "Name of the existing AWS key pair for SSH access"
  type        = string
  # Set in terraform.tfvars — never hardcode here
}

variable "instance_name" {
  description = "Name tag for the EC2 instance"
  type        = string
  default     = "nafadpay-g1-oltp"
}

variable "security_group_name" {
  description = "Name of the security group"
  type        = string
  default     = "nafadpay-sg"
}
