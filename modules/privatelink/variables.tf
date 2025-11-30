variable "project_id" {
  type        = string
  description = "MongoDB Atlas project ID"
}

variable "atlas_region" {
  type        = string
  description = "Atlas region (e.g., US_EAST_1)"
  validation {
    condition     = length(var.atlas_region) > 0
    error_message = "atlas_region must be provided"
  }
}

variable "aws_region" {
  type        = string
  default     = null
  nullable    = true
  description = "AWS region override. Defaults to the AWS provider's region if not specified."
}

#------------------------------------------------------------------------------
# VPC Endpoint Configuration
#------------------------------------------------------------------------------

variable "create_vpc_endpoint" {
  type        = bool
  default     = false
  description = "Whether to create a new VPC endpoint or use an existing one"
}

variable "existing_vpc_endpoint_id" {
  type        = string
  default     = null
  nullable    = true
  description = "ID of existing VPC endpoint (required when create_vpc_endpoint = false)"
}

variable "subnet_ids" {
  type        = set(string)
  default     = null
  nullable    = true
  description = "Subnet IDs for the VPC endpoint (required when create_vpc_endpoint = true)"
}

#------------------------------------------------------------------------------
# Security Group Configuration
#------------------------------------------------------------------------------

variable "security_group_ids" {
  type        = set(string)
  default     = []
  description = "Security group IDs to attach to VPC endpoint"
}

variable "create_security_group" {
  type        = bool
  default     = false
  description = "Whether to create a security group for the VPC endpoint"
}

variable "security_group_inbound_cidr_blocks" {
  type        = list(string)
  default     = null
  nullable    = true
  description = "CIDR blocks for inbound rules. null = use VPC CIDR (default), [] = no CIDR rule"
}

variable "security_group_inbound_source_sgs" {
  type        = set(string)
  default     = []
  description = "Source security group IDs for inbound rules. Creates one rule per security group."
}

variable "security_group_name_prefix" {
  type        = string
  default     = "mongodb-privatelink-"
  description = "Name prefix for the created security group"
}

#------------------------------------------------------------------------------
# Common Configuration
#------------------------------------------------------------------------------

variable "aws_tags" {
  type        = map(string)
  default     = {}
  description = "AWS tags to apply to created resources"
}
