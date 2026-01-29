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

variable "subnet_ids" {
  type        = list(string)
  description = "Subnet IDs for PrivateLink endpoint. If not provided, subnets are discovered via data source using Tier=Private tag."
  default     = null
}
