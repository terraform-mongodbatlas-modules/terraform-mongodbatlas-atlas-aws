variable "project_id" {
  type = string
}
# Atlas Region
variable "atlas_region" {
  type = string
  validation {
    condition     = length(var.atlas_region) > 0
    error_message = "atlas_region must be provided"
  }
}

variable "existing_vpc_endpoint_id" {
  type     = string
  nullable = false
  default  = ""
}

variable "add_vpc_cidr_block_project_access" {
  type    = bool
  default = false
}

variable "aws_private_endpoint" {
  type = object({
    vpc_id             = string
    subnet_ids         = set(string)
    security_group_ids = set(string)
  })
  default  = null
  nullable = true
}

variable "aws_tags" {
  type        = map(string)
  description = "aws tags"
  default     = {}
}

variable "create_security_group" {
  type        = bool
  default     = false
  description = "Whether to create a security group for the MongoDB Atlas private endpoint"
}

variable "security_group_inbound_cidr_blocks" {
  type        = list(string)
  default     = null
  description = "CIDR blocks for inbound rules. Defaults to VPC CIDR if not specified."
}

variable "security_group_name_prefix" {
  type        = string
  default     = "mongodb-privatelink-"
  description = "Name prefix for the created security group"
}
