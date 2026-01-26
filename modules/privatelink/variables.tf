variable "project_id" {
  type        = string
  description = "MongoDB Atlas project ID"
}

variable "region" {
  type        = string
  description = "AWS region (e.g., us-east-1)"
}

variable "private_link_id" {
  type        = string
  description = "Atlas PrivateLink endpoint ID (from root module)"
}

variable "endpoint_service_name" {
  type        = string
  description = "Atlas endpoint service name (from root module)"
}

variable "create_vpc_endpoint" {
  type        = bool
  default     = true
  description = "Create AWS VPC endpoint. Set false for BYOE."
}

variable "subnet_ids" {
  type        = list(string)
  default     = []
  description = "Subnet IDs for the VPC endpoint"
}

variable "security_group_ids" {
  type        = list(string)
  default     = null
  description = "Security group IDs. When null, create_security_group controls SG creation."
}

variable "create_security_group" {
  type        = bool
  default     = true
  description = "Create a security group. Ignored if security_group_ids is provided."
}

variable "security_group_name_prefix" {
  type        = string
  default     = "atlas-privatelink-"
  description = "Name prefix for the auto-created security group"
}

variable "security_group_inbound_cidr_blocks" {
  type        = list(string)
  default     = null
  description = "CIDR blocks for inbound rules. null = VPC CIDR, [] = no CIDR rule."
}

variable "security_group_inbound_source_sgs" {
  type        = set(string)
  default     = []
  description = "Source security group IDs for inbound rules"
}

variable "security_group_from_port" {
  type        = number
  default     = 1024
  description = "Start of port range"
}

variable "security_group_to_port" {
  type        = number
  default     = 65535
  description = "End of port range"
}

variable "existing_vpc_endpoint_id" {
  type        = string
  default     = null
  description = "Existing VPC endpoint ID for BYOE"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags for AWS resources"
}
