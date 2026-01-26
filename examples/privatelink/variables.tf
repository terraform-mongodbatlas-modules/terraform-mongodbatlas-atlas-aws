variable "project_id" {
  type        = string
  description = "MongoDB Atlas project ID"
}

variable "aws_region" {
  type        = string
  description = "AWS region"
  default     = ""
}

variable "vpc_id" {
  type        = string
  description = "AWS VPC ID"
}
