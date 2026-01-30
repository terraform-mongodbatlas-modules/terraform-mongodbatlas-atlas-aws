output "id" {
  description = "Atlas encryption private endpoint ID"
  value       = mongodbatlas_encryption_at_rest_private_endpoint.this.id
}

output "status" {
  description = "Atlas encryption private endpoint status"
  value       = data.mongodbatlas_encryption_at_rest_private_endpoint.this.status
}

output "error_message" {
  description = "Error message if private endpoint creation failed"
  value       = data.mongodbatlas_encryption_at_rest_private_endpoint.this.error_message
}

output "atlas_region" {
  description = "Normalized Atlas region format"
  value       = local.atlas_region
}

output "aws_region" {
  description = "AWS region format"
  value       = local.aws_region
}
