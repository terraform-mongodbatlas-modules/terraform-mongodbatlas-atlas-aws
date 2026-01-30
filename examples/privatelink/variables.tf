variable "project_id" {
  type        = string
  description = "MongoDB Atlas project ID"
}

variable "aws_region" {
  type        = string
  description = "AWS region"
}

variable "subnet_ids" {
  type        = list(string)
  description = "Subnet IDs for PrivateLink endpoint"
}
