variable "org_id" {
  type        = string
  description = "MongoDB Atlas Organization ID"
}

variable "project_name" {
  type        = string
  description = "MongoDB Atlas Project name"
}

variable "aws_subnet_ids" {
  type        = list(string)
  description = "AWS Subnet IDs for the private endpoint"
}

variable "atlas_region" {
  type        = string
  description = "Atlas region (e.g., US_EAST_1)"
  default     = "US_EAST_1"
}
