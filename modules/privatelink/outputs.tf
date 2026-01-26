output "private_link_id" {
  description = "Atlas PrivateLink connection ID"
  value       = var.private_link_id
}

output "endpoint_service_name" {
  description = "Atlas endpoint service name"
  value       = var.endpoint_service_name
}

output "vpc_endpoint_id" {
  description = "AWS VPC endpoint ID"
  value       = var.create_vpc_endpoint ? aws_vpc_endpoint.this[0].id : var.existing_vpc_endpoint_id
}

output "status" {
  description = "PrivateLink connection status"
  value       = mongodbatlas_privatelink_endpoint_service.this.aws_connection_status
}

output "error_message" {
  description = "Error message if connection failed"
  value       = mongodbatlas_privatelink_endpoint_service.this.error_message
}

output "security_group_id" {
  description = "Created security group ID"
  value       = local.should_create_sg ? aws_security_group.this[0].id : null
}
