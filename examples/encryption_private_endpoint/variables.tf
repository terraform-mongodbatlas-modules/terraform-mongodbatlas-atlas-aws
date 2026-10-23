variable "project_id" {
  type        = string
  description = "MongoDB Atlas project ID"
}

variable "aws_region" {
  type        = string
  description = "AWS region"
}

variable "aws_tags" {
  type        = map(string)
  description = "Tags to apply to AWS resources"
  default     = {}
}
