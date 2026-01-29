terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
  required_version = ">= 1.9"
}

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "subnet_cidr" {
  type    = string
  default = "10.0.1.0/24"
}

variable "name_prefix" {
  type    = string
  default = "atlas-workspace-"
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.name_prefix}vpc"
  }
}

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.subnet_cidr
  availability_zone = "${var.region}a"

  tags = {
    Name = "${var.name_prefix}subnet"
    Tier = "Private"
  }
}

resource "aws_security_group" "this" {
  name_prefix = var.name_prefix
  description = "Security group for Atlas PrivateLink"
  vpc_id      = aws_vpc.this.id

  ingress {
    from_port   = 1024
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "MongoDB Atlas PrivateLink"
  }

  tags = {
    Name = "${var.name_prefix}sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

output "vpc_id" {
  value = aws_vpc.this.id
}

output "subnet_id" {
  value = aws_subnet.private.id
}

output "subnet_ids" {
  value = [aws_subnet.private.id]
}

output "security_group_id" {
  value = aws_security_group.this.id
}
