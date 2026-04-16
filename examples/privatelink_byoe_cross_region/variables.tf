variable "project_id" {
  type        = string
  description = "MongoDB Atlas project ID"
}

variable "atlas_service_region" {
  type        = string
  description = "AWS region where the Atlas PrivateLink endpoint service lives"
  default     = "us-east-1"
}

variable "remote_region" {
  type        = string
  description = "AWS region where the VPC endpoint is created (cross-region)"
  default     = "us-west-2"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID in the remote region"
}

variable "subnet_ids" {
  type        = list(string)
  description = "Subnet IDs in the remote region"
}

variable "security_group_ids" {
  type        = list(string)
  description = "Security group IDs for the VPC endpoint in the remote region"
}
