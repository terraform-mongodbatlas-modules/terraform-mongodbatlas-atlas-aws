output "aws_vpc_endpoint_id" {
  value = local.vpc_endpoint_id
}

output "aws_region" {
  value = local.aws_region
}

output "aws_vpc_cidr_block" {
  value = local.vpc_cidr_block
}

output "atlas_private_endpoint_status" {
  value = mongodbatlas_privatelink_endpoint.mongodb_endpoint.status
}

output "atlas_private_link_service_name" {
  value = mongodbatlas_privatelink_endpoint.mongodb_endpoint.private_link_service_name
}

output "atlas_private_link_service_resource_id" {
  value = mongodbatlas_privatelink_endpoint.mongodb_endpoint.private_link_service_resource_id
}

output "security_group_id" {
  value       = var.create_security_group ? aws_security_group.mongodb_privatelink[0].id : null
  description = "ID of the created security group (null if not created)"
}
