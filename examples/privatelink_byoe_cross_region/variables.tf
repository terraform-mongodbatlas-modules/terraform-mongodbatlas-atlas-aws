variable "project_id" {
  type        = string
  description = "MongoDB Atlas project ID"
}

variable "atlas_service_region" {
  type        = string
  description = "AWS region where the Atlas PrivateLink endpoint service lives (AWS format, e.g. us-east-1). Used in aws_vpc_endpoint.service_region."
  default     = "us-east-1"
}

variable "aws_region" {
  type        = string
  description = "AWS region where the application VPC and cross-region endpoint live (AWS format, e.g. us-west-2). Used in the AWS provider and aws_vpc_endpoint."
  default     = "us-west-2"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID in the application region"
}

variable "subnet_ids" {
  type        = list(string)
  description = "Subnet IDs in the application region"
}

variable "security_group_ids" {
  type        = list(string)
  description = "Security group IDs for the VPC endpoint in the application region"
}
