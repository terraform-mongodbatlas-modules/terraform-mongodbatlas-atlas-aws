variable "project_id" {
  type        = string
  description = "MongoDB Atlas project ID"
}

variable "aws_region" {
  type        = string
  description = "AWS region"
  default     = ""
}

variable "subnet_ids_us_east_1" {
  type        = list(string)
  description = "Subnet IDs in us-east-1"
}

variable "subnet_ids_us_west_2" {
  type        = list(string)
  description = "Subnet IDs in us-west-2"
}

variable "aws_tags" {
  type        = map(string)
  description = "Tags to apply to AWS resources"
  default     = {}
}
