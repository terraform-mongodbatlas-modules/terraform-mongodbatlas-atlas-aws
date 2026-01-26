variable "project_id" {
  type        = string
  description = "MongoDB Atlas project ID"
}

variable "aws_region" {
  type        = string
  description = "AWS region for the PrivateLink endpoint"
}

variable "vpc_id" {
  type        = string
  description = "AWS VPC ID for the private endpoint"
}

variable "subnet_ids" {
  type        = list(string)
  description = "AWS subnet IDs for the VPC endpoint"
}

variable "security_group_ids" {
  type        = list(string)
  description = "Security group IDs for the VPC endpoint"
}
