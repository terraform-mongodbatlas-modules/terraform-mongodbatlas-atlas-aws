mock_provider "mongodbatlas" {}
mock_provider "aws" {}

variables {
  project_id = "000000000000000000000000"
}

run "skip_iam_policy_attachments_all_features" {
  command = plan
  variables {
    project_id = var.project_id
    cloud_provider_access = {
      create                      = false
      skip_iam_policy_attachments = true
      existing = {
        role_id      = "role123"
        iam_role_arn = "arn:aws:iam::123456789012:role/atlas-role"
      }
    }
    encryption = {
      enabled     = true
      kms_key_arn = "arn:aws:kms:us-east-1:358363220050:key/7fa78c27-a2c5-4926-8d11-a0d4a405cd6f"
    }
    backup_export = {
      enabled     = true
      bucket_name = "my-backup-bucket"
    }
    log_integration = {
      enabled      = true
      bucket_name  = "my-log-bucket"
      integrations = [{ log_types = ["MONGOD"], prefix_path = "test" }]
    }
  }
  assert {
    condition     = length(module.encryption) == 1
    error_message = "Expected encryption module"
  }
  assert {
    condition     = length(module.backup_export) == 1
    error_message = "Expected backup_export module"
  }
  assert {
    condition     = length(module.log_integration) == 1
    error_message = "Expected log_integration module"
  }
  assert {
    condition     = output.resource_ids.iam_role_name == "atlas-role"
    error_message = "Expected iam_role_name derived from ARN even when skip_iam_policy_attachments = true"
  }
}

run "missing_existing_when_create_false" {
  command = plan
  variables {
    project_id            = var.project_id
    cloud_provider_access = { create = false }
  }
  expect_failures = [var.cloud_provider_access]
}

run "valid_default_config" {
  command = plan
  variables {
    project_id = var.project_id
  }
  assert {
    condition     = length(module.cloud_provider_access) == 1
    error_message = "Expected cloud_provider_access module"
  }
}

run "valid_existing_config" {
  command = plan
  variables {
    project_id = var.project_id
    cloud_provider_access = {
      create = false
      existing = {
        role_id      = "role123"
        iam_role_arn = "arn:aws:iam::123456789012:role/atlas-role"
      }
    }
  }
  assert {
    condition     = length(module.cloud_provider_access) == 0
    error_message = "Expected no cloud_provider_access module with existing"
  }
  assert {
    condition     = output.role_id == "role123"
    error_message = "Expected role_id from existing"
  }
  assert {
    condition     = output.resource_ids.iam_role_name == "atlas-role"
    error_message = "Expected iam_role_name derived from simple ARN"
  }
}

run "skip_cloud_provider_access_privatelink_only" {
  command = plan
  variables {
    project_id = var.project_id
    privatelink_endpoints = [
      { region = "us-east-1", subnet_ids = ["subnet-abc"], security_group = { inbound_cidr_blocks = ["10.0.0.0/8"] } }
    ]
  }
  assert {
    condition     = length(module.cloud_provider_access) == 0
    error_message = "Expected no cloud_provider_access with privatelink-only"
  }
  assert {
    condition     = output.role_id == null
    error_message = "Expected null role_id"
  }
}

run "enable_cloud_provider_access_encryption" {
  command = plan
  variables {
    project_id = var.project_id
    encryption = {
      enabled        = true
      create_kms_key = { enabled = true }
    }
    privatelink_endpoints = [
      { region = "us-east-1", subnet_ids = ["subnet-abc"], security_group = { inbound_cidr_blocks = ["10.0.0.0/8"] } }
    ]
  }
  assert {
    condition     = length(module.cloud_provider_access) == 1
    error_message = "Expected cloud_provider_access with encryption"
  }
}

run "enable_cloud_provider_access_backup_export" {
  command = plan
  variables {
    project_id = var.project_id
    backup_export = {
      enabled          = true
      create_s3_bucket = { enabled = true }
    }
    privatelink_endpoints = [
      { region = "us-east-1", subnet_ids = ["subnet-abc"], security_group = { inbound_cidr_blocks = ["10.0.0.0/8"] } }
    ]
  }
  assert {
    condition     = length(module.cloud_provider_access) == 1
    error_message = "Expected cloud_provider_access with backup_export"
  }
}

run "encryption_validation_byo_and_create_conflict" {
  command = plan
  variables {
    project_id = var.project_id
    encryption = {
      enabled        = true
      kms_key_arn    = "arn:aws:kms:us-east-1:123456789012:key/abc"
      create_kms_key = { enabled = true }
    }
  }
  expect_failures = [var.encryption]
}

run "encryption_validation_enabled_without_key" {
  command = plan
  variables {
    project_id = var.project_id
    encryption = { enabled = true }
  }
  expect_failures = [var.encryption]
}

run "encryption_private_endpoints_without_encryption_fails" {
  command = plan
  variables {
    project_id = var.project_id
    encryption = {
      enabled                  = false
      private_endpoint_regions = ["us-east-1"]
    }
  }
  expect_failures = [var.encryption]
}

run "encryption_with_dedicated_iam_role" {
  command = plan
  variables {
    project_id = var.project_id
    encryption = {
      enabled        = true
      create_kms_key = { enabled = true }
      iam_role       = { create = true }
    }
  }
  assert {
    condition     = length(module.encryption_cloud_provider_access) == 1
    error_message = "Expected dedicated encryption IAM role"
  }
  assert {
    condition     = length(module.encryption) == 1
    error_message = "Expected encryption module"
  }
}

run "encryption_with_private_endpoints" {
  command = plan
  variables {
    project_id = var.project_id
    encryption = {
      enabled                  = true
      kms_key_arn              = "arn:aws:kms:us-east-1:123456789012:key/abc"
      private_endpoint_regions = ["us-east-1", "us-west-2"]
    }
  }
  assert {
    condition     = length(module.encryption_private_endpoint) == 2
    error_message = "Expected 2 private endpoints"
  }
}

run "encryption_enabled_for_search_nodes_default_true" {
  command = plan
  variables {
    project_id = var.project_id
    encryption = {
      enabled     = true
      kms_key_arn = "arn:aws:kms:us-east-1:123456789012:key/abc"
    }
  }
  assert {
    condition     = output.encryption.enabled_for_search_nodes == true
    error_message = "Expected enabled_for_search_nodes to default to true"
  }
}

run "encryption_enabled_for_search_nodes_explicit_false" {
  command = plan
  variables {
    project_id = var.project_id
    encryption = {
      enabled                  = true
      kms_key_arn              = "arn:aws:kms:us-east-1:123456789012:key/abc"
      enabled_for_search_nodes = false
    }
  }
  assert {
    condition     = output.encryption.enabled_for_search_nodes == false
    error_message = "Expected enabled_for_search_nodes to be false when explicitly set"
  }
}

run "encryption_no_private_endpoints_by_default" {
  command = plan
  variables {
    project_id = var.project_id
    encryption = {
      enabled     = true
      kms_key_arn = "arn:aws:kms:us-east-1:123456789012:key/abc"
    }
  }
  assert {
    condition     = length(module.encryption_private_endpoint) == 0
    error_message = "Expected no private endpoints when private_endpoint_regions not set"
  }
}

run "backup_export_validation_byo_and_create_conflict" {
  command = plan
  variables {
    project_id = var.project_id
    backup_export = {
      enabled          = true
      bucket_name      = "my-bucket"
      create_s3_bucket = { enabled = true }
    }
  }
  expect_failures = [var.backup_export]
}

run "backup_export_validation_enabled_without_bucket" {
  command = plan
  variables {
    project_id    = var.project_id
    backup_export = { enabled = true }
  }
  expect_failures = [var.backup_export]
}

run "backup_export_with_dedicated_iam_role" {
  command = plan
  variables {
    project_id = var.project_id
    backup_export = {
      enabled          = true
      create_s3_bucket = { enabled = true }
      iam_role         = { create = true }
    }
  }
  assert {
    condition     = length(module.backup_export_cloud_provider_access) == 1
    error_message = "Expected dedicated backup export IAM role"
  }
  assert {
    condition     = length(module.backup_export) == 1
    error_message = "Expected backup_export module"
  }
}

run "backup_export_with_byo_bucket" {
  command = plan
  variables {
    project_id = var.project_id
    backup_export = {
      enabled     = true
      bucket_name = "my-existing-bucket"
    }
  }
  assert {
    condition     = length(module.backup_export) == 1
    error_message = "Expected backup_export module"
  }
  assert {
    condition     = output.backup_export.expiration_days == null
    error_message = "Expected expiration_days = null for BYO bucket"
  }
}

run "backup_export_with_name_prefix" {
  command = plan
  variables {
    project_id = var.project_id
    backup_export = {
      enabled = true
      create_s3_bucket = {
        enabled     = true
        name_prefix = "my-custom-prefix-"
      }
    }
  }
  assert {
    condition     = length(module.backup_export) == 1
    error_message = "Expected backup_export module"
  }
}

run "backup_export_with_auto_name_prefix" {
  command = plan
  variables {
    project_id = var.project_id
    backup_export = {
      enabled          = true
      create_s3_bucket = { enabled = true }
    }
  }
  assert {
    condition     = length(module.backup_export) == 1
    error_message = "Expected backup_export module"
  }
  assert {
    condition     = output.backup_export.expiration_days == 365
    error_message = "Expected default expiration_days = 365"
  }
}

run "backup_export_lifecycle_disabled" {
  command = plan
  variables {
    project_id = var.project_id
    backup_export = {
      enabled = true
      create_s3_bucket = {
        enabled         = true
        expiration_days = 0
      }
    }
  }
  assert {
    condition     = length(module.backup_export) == 1
    error_message = "Expected backup_export module"
  }
  assert {
    condition     = output.backup_export.expiration_days == 0
    error_message = "Expected expiration_days = 0 (disabled)"
  }
}

run "backup_export_lifecycle_custom_days" {
  command = plan
  variables {
    project_id = var.project_id
    backup_export = {
      enabled = true
      create_s3_bucket = {
        enabled         = true
        expiration_days = 30
      }
    }
  }
  assert {
    condition     = length(module.backup_export) == 1
    error_message = "Expected backup_export module"
  }
  assert {
    condition     = output.backup_export.expiration_days == 30
    error_message = "Expected expiration_days = 30"
  }
}

run "log_integration_lifecycle_disabled" {
  command = plan
  variables {
    project_id = var.project_id
    log_integration = {
      enabled = true
      create_s3_bucket = {
        enabled         = true
        expiration_days = 0
      }
      integrations = [{ log_types = ["MONGOD"], prefix_path = "test" }]
    }
  }
  assert {
    condition     = length(module.log_integration) == 1
    error_message = "Expected log_integration module"
  }
  assert {
    condition     = output.log_integration.expiration_days == 0
    error_message = "Expected expiration_days = 0 (disabled)"
  }
}

run "log_integration_lifecycle_custom_days" {
  command = plan
  variables {
    project_id = var.project_id
    log_integration = {
      enabled = true
      create_s3_bucket = {
        enabled         = true
        expiration_days = 30
      }
      integrations = [{ log_types = ["MONGOD"], prefix_path = "test" }]
    }
  }
  assert {
    condition     = length(module.log_integration) == 1
    error_message = "Expected log_integration module"
  }
  assert {
    condition     = output.log_integration.expiration_days == 30
    error_message = "Expected expiration_days = 30"
  }
}

run "backup_export_name_and_prefix_conflict" {
  command = plan
  variables {
    project_id = var.project_id
    backup_export = {
      enabled = true
      create_s3_bucket = {
        enabled     = true
        name        = "my-bucket"
        name_prefix = "my-prefix-"
      }
    }
  }
  expect_failures = [var.backup_export]
}

run "backup_export_name_contains_dot" {
  command = plan
  variables {
    project_id = var.project_id
    backup_export = {
      enabled          = true
      create_s3_bucket = { enabled = true, name = "my.dotted.bucket" }
    }
  }
  expect_failures = [var.backup_export]
}

run "backup_export_name_prefix_contains_dot" {
  command = plan
  variables {
    project_id = var.project_id
    backup_export = {
      enabled          = true
      create_s3_bucket = { enabled = true, name_prefix = "my.prefix." }
    }
  }
  expect_failures = [var.backup_export]
}

run "backup_export_negative_expiration_days" {
  command = plan
  variables {
    project_id = var.project_id
    backup_export = {
      enabled = true
      create_s3_bucket = {
        enabled         = true
        expiration_days = -1
      }
    }
  }
  expect_failures = [var.backup_export]
}

run "backup_export_fractional_expiration_days" {
  command = plan
  variables {
    project_id = var.project_id
    backup_export = {
      enabled = true
      create_s3_bucket = {
        enabled         = true
        expiration_days = 1.5
      }
    }
  }
  expect_failures = [var.backup_export]
}

run "privatelink_byo_endpoint_key_overlap_validation" {
  command = plan
  variables {
    project_id = var.project_id
    privatelink_endpoints = [
      { region = "us-east-1", subnet_ids = ["subnet-abc"] }
    ]
    privatelink_byo_endpoint = {
      primary = { region = "us-east-1" }
    }
  }
  expect_failures = [var.privatelink_byo_endpoint]
}

run "privatelink_byo_endpoint_key_collides_with_module_managed_key" {
  command = plan
  variables {
    project_id = var.project_id
    privatelink_endpoints = [
      { region = "us-east-1", subnet_ids = ["subnet-abc"] }
    ]
    privatelink_byo_endpoint = {
      "us-east-1" = { region = "eu-west-1" }
    }
  }
  expect_failures = [var.privatelink_byo_endpoint]
}

run "privatelink_byo_service_missing_key" {
  command = plan
  variables {
    project_id = var.project_id
    privatelink_byo_endpoint = {
      primary = { region = "us-east-1" }
    }
    privatelink_byo_service = {
      secondary = { vpc_endpoint_id = "vpce-abc" }
    }
  }
  expect_failures = [var.privatelink_byo_service]
}

run "privatelink_duplicate_regions_validation" {
  command = plan
  variables {
    project_id = var.project_id
    privatelink_endpoints = [
      { region = "us-east-1", subnet_ids = ["subnet-abc"] },
      { region = "us-east-1", subnet_ids = ["subnet-def"] }
    ]
  }
  expect_failures = [var.privatelink_endpoints]
}

run "privatelink_single_region_must_match" {
  command = plan
  variables {
    project_id = var.project_id
    privatelink_endpoints_single_region = [
      { region = "us-east-1", subnet_ids = ["subnet-abc"] },
      { region = "us-west-2", subnet_ids = ["subnet-def"] }
    ]
  }
  expect_failures = [var.privatelink_endpoints_single_region]
}

run "privatelink_valid_single_region_pattern" {
  command = plan
  variables {
    project_id = var.project_id
    privatelink_endpoints_single_region = [
      { region = "us-east-1", subnet_ids = ["subnet-abc"], security_group = { inbound_cidr_blocks = ["10.0.0.0/8"] } },
      { region = "us-east-1", subnet_ids = ["subnet-def"], security_group = { inbound_cidr_blocks = ["10.0.0.0/8"] } }
    ]
  }
  assert {
    condition     = output.regional_mode_enabled == false
    error_message = "Expected regional mode disabled for single-region pattern"
  }
  assert {
    condition     = length(mongodbatlas_privatelink_endpoint.this) == 2
    error_message = "Expected 2 Atlas endpoints (one per single-region entry)"
  }
  assert {
    condition     = length(module.privatelink) == 2
    error_message = "Expected 2 privatelink modules"
  }
}

run "privatelink_cannot_mix_patterns" {
  command = plan
  variables {
    project_id = var.project_id
    privatelink_endpoints = [
      { region = "us-east-1", subnet_ids = ["subnet-abc"] }
    ]
    privatelink_endpoints_single_region = [
      { region = "us-west-2", subnet_ids = ["subnet-def"] }
    ]
  }
  expect_failures = [var.privatelink_endpoints_single_region]
}

run "privatelink_valid_multi_region" {
  command = plan
  variables {
    project_id = var.project_id
    privatelink_endpoints = [
      { region = "us-east-1", subnet_ids = ["subnet-abc"], security_group = { inbound_cidr_blocks = ["10.0.0.0/8"] } },
      { region = "us-west-2", subnet_ids = ["subnet-def"], security_group = { inbound_cidr_blocks = ["10.0.0.0/8"] } }
    ]
  }
  assert {
    condition     = output.regional_mode_enabled == true
    error_message = "Expected regional mode enabled for multi-region"
  }
}

run "privatelink_valid_single_region" {
  command = plan
  variables {
    project_id = var.project_id
    privatelink_endpoints = [
      { region = "us-east-1", subnet_ids = ["subnet-abc"], security_group = { inbound_cidr_blocks = ["10.0.0.0/8"] } }
    ]
  }
  assert {
    condition     = output.regional_mode_enabled == false
    error_message = "Expected regional mode disabled for single region"
  }
}

run "custom_iam_role_name" {
  command = plan
  variables {
    project_id = var.project_id
    cloud_provider_access = {
      iam_role_name = "my-custom-atlas-role"
    }
  }
  assert {
    condition     = length(module.cloud_provider_access) == 1
    error_message = "Expected cloud_provider_access module with custom name"
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# BYOE (Bring Your Own Endpoint) Pattern Tests
# ─────────────────────────────────────────────────────────────────────────────

run "privatelink_byo_service_phase1_atlas_endpoint_created" {
  command = plan
  variables {
    project_id = var.project_id
    privatelink_byo_endpoint = {
      primary = { region = "us-east-1" }
    }
  }
  assert {
    condition     = length(mongodbatlas_privatelink_endpoint.this) == 1
    error_message = "Expected Atlas privatelink endpoint in Phase 1 (for endpoint_service_name)"
  }
  assert {
    condition     = length(module.privatelink) == 0
    error_message = "Expected no privatelink module in Phase 1 (no endpoint IDs provided)"
  }
  assert {
    condition     = contains(keys(output.privatelink_service_info), "primary")
    error_message = "Expected privatelink_service_info to include 'primary' key for BYOE Phase 1"
  }
}

run "privatelink_byo_service_phase2_with_endpoint" {
  command = plan
  variables {
    project_id = var.project_id
    privatelink_byo_endpoint = {
      primary = { region = "us-east-1" }
    }
    privatelink_byo_service = {
      primary = { vpc_endpoint_id = "vpce-0123456789abcdef0" }
    }
  }
  assert {
    condition     = length(module.privatelink) == 1
    error_message = "Expected privatelink module in Phase 2"
  }
  assert {
    condition     = length(mongodbatlas_privatelink_endpoint.this) == 1
    error_message = "Expected Atlas privatelink endpoint in Phase 2"
  }
  assert {
    condition     = contains(keys(output.privatelink_service_info), "primary")
    error_message = "Expected privatelink_service_info to include 'primary' key"
  }
}

run "privatelink_byo_service_multi_region_phase2" {
  command = plan
  variables {
    project_id = var.project_id
    privatelink_byo_endpoint = {
      primary   = { region = "us-east-1" }
      secondary = { region = "eu-west-1" }
    }
    privatelink_byo_service = {
      primary   = { vpc_endpoint_id = "vpce-0123456789abcdef0" }
      secondary = { vpc_endpoint_id = "vpce-fedcba9876543210f" }
    }
  }
  assert {
    condition     = length(module.privatelink) == 2
    error_message = "Expected 2 privatelink modules for multi-region BYOE"
  }
  assert {
    condition     = output.regional_mode_enabled == true
    error_message = "Expected regional mode enabled for multi-region BYOE"
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Region Format Normalization Tests
# ─────────────────────────────────────────────────────────────────────────────

run "region_format_atlas_style_privatelink" {
  command = plan
  variables {
    project_id = var.project_id
    privatelink_endpoints = [
      { region = "US_EAST_1", subnet_ids = ["subnet-abc"], security_group = { inbound_cidr_blocks = ["10.0.0.0/8"] } }
    ]
  }
  assert {
    condition     = length(module.privatelink) == 1
    error_message = "Expected privatelink module with Atlas region format"
  }
  assert {
    condition     = contains(keys(output.privatelink_service_info), "us-east-1")
    error_message = "Expected normalized key us-east-1 in privatelink_service_info"
  }
  assert {
    condition     = contains(keys(output.privatelink), "us-east-1")
    error_message = "Expected normalized key us-east-1 in privatelink output"
  }
}

run "region_format_atlas_style_encryption" {
  command = plan
  variables {
    project_id = var.project_id
    encryption = {
      enabled        = true
      region         = "US_EAST_1"
      create_kms_key = { enabled = true }
    }
  }
  assert {
    condition     = length(module.encryption) == 1
    error_message = "Expected encryption module with Atlas region format"
  }
}

run "region_format_atlas_style_encryption_private_endpoints" {
  command = plan
  variables {
    project_id = var.project_id
    encryption = {
      enabled                  = true
      kms_key_arn              = "arn:aws:kms:us-east-1:123456789012:key/abc"
      private_endpoint_regions = ["US_EAST_1", "US_WEST_2"]
    }
  }
  assert {
    condition     = length(module.encryption_private_endpoint) == 2
    error_message = "Expected 2 private endpoints with Atlas region format"
  }
  assert {
    condition     = contains(keys(output.encryption.private_endpoints), "us-east-1")
    error_message = "Expected normalized key us-east-1 in encryption private_endpoints"
  }
  assert {
    condition     = contains(keys(output.encryption.private_endpoints), "us-west-2")
    error_message = "Expected normalized key us-west-2 in encryption private_endpoints"
  }
}

run "privatelink_duplicate_regions_mixed_format" {
  command = plan
  variables {
    project_id = var.project_id
    privatelink_endpoints = [
      { region = "us-east-1", subnet_ids = ["subnet-abc"] },
      { region = "US_EAST_1", subnet_ids = ["subnet-def"] }
    ]
  }
  expect_failures = [var.privatelink_endpoints]
}

run "privatelink_byo_endpoint_key_overlap_normalized" {
  command = plan
  variables {
    project_id = var.project_id
    privatelink_endpoints = [
      { region = "US_EAST_1", subnet_ids = ["subnet-abc"] }
    ]
    privatelink_byo_endpoint = {
      primary = { region = "us-east-1" }
    }
  }
  expect_failures = [var.privatelink_byo_endpoint]
}

run "region_format_mixed_styles_privatelink" {
  command = plan
  variables {
    project_id = var.project_id
    privatelink_endpoints = [
      { region = "us-east-1", subnet_ids = ["subnet-abc"], security_group = { inbound_cidr_blocks = ["10.0.0.0/8"] } },
      { region = "US_WEST_2", subnet_ids = ["subnet-def"], security_group = { inbound_cidr_blocks = ["10.0.0.0/8"] } }
    ]
  }
  assert {
    condition     = length(module.privatelink) == 2
    error_message = "Expected 2 privatelink modules with mixed region formats"
  }
  assert {
    condition     = output.regional_mode_enabled == true
    error_message = "Expected regional mode enabled for multi-region"
  }
  assert {
    condition     = contains(keys(output.privatelink), "us-east-1")
    error_message = "Expected normalized key us-east-1 in privatelink output"
  }
  assert {
    condition     = contains(keys(output.privatelink), "us-west-2")
    error_message = "Expected normalized key us-west-2 in privatelink output"
  }
}

run "aws_tags_propagated" {
  command = plan
  variables {
    project_id = var.project_id
    encryption = {
      enabled        = true
      create_kms_key = { enabled = true }
    }
    aws_tags = {
      Environment = "production"
      Module      = "atlas-aws"
    }
  }
  assert {
    condition     = length(module.encryption) == 1
    error_message = "Expected encryption module"
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Log Integration Validations
# ─────────────────────────────────────────────────────────────────────────────

run "log_integration_validation_enabled_without_integrations" {
  command = plan
  variables {
    project_id      = var.project_id
    log_integration = { enabled = true, create_s3_bucket = { enabled = true } }
  }
  expect_failures = [var.log_integration]
}

run "log_integration_validation_enabled_without_bucket" {
  command = plan
  variables {
    project_id      = var.project_id
    log_integration = { enabled = true, integrations = [{ log_types = ["MONGOD"], prefix_path = "test" }] }
  }
  expect_failures = [var.log_integration]
}

run "log_integration_validation_byo_and_create_conflict" {
  command = plan
  variables {
    project_id = var.project_id
    log_integration = {
      enabled          = true
      bucket_name      = "my-bucket"
      create_s3_bucket = { enabled = true }
      integrations     = [{ log_types = ["MONGOD"], prefix_path = "test" }]
    }
  }
  expect_failures = [var.log_integration]
}

run "log_integration_name_and_prefix_conflict" {
  command = plan
  variables {
    project_id = var.project_id
    log_integration = {
      enabled          = true
      create_s3_bucket = { enabled = true, name = "my-bucket", name_prefix = "my-prefix-" }
      integrations     = [{ log_types = ["MONGOD"], prefix_path = "test" }]
    }
  }
  expect_failures = [var.log_integration]
}

run "log_integration_name_contains_dot" {
  command = plan
  variables {
    project_id = var.project_id
    log_integration = {
      enabled          = true
      create_s3_bucket = { enabled = true, name = "log.bucket.name" }
      integrations     = [{ log_types = ["MONGOD"], prefix_path = "test" }]
    }
  }
  expect_failures = [var.log_integration]
}

run "log_integration_name_prefix_contains_dot" {
  command = plan
  variables {
    project_id = var.project_id
    log_integration = {
      enabled          = true
      create_s3_bucket = { enabled = true, name_prefix = "log.prefix." }
      integrations     = [{ log_types = ["MONGOD"], prefix_path = "test" }]
    }
  }
  expect_failures = [var.log_integration]
}

run "log_integration_name_prefix_too_long" {
  command = plan
  variables {
    project_id = var.project_id
    log_integration = {
      enabled          = true
      create_s3_bucket = { enabled = true, name_prefix = "this-prefix-is-way-too-long-for-s3-bucket-names-" }
      integrations     = [{ log_types = ["MONGOD"], prefix_path = "test" }]
    }
  }
  expect_failures = [var.log_integration]
}

run "log_integration_negative_expiration_days" {
  command = plan
  variables {
    project_id = var.project_id
    log_integration = {
      enabled          = true
      create_s3_bucket = { enabled = true, expiration_days = -1 }
      integrations     = [{ log_types = ["MONGOD"], prefix_path = "test" }]
    }
  }
  expect_failures = [var.log_integration]
}

run "log_integration_fractional_expiration_days" {
  command = plan
  variables {
    project_id = var.project_id
    log_integration = {
      enabled          = true
      create_s3_bucket = { enabled = true, expiration_days = 1.5 }
      integrations     = [{ log_types = ["MONGOD"], prefix_path = "test" }]
    }
  }
  expect_failures = [var.log_integration]
}

run "log_integration_disabled_by_default" {
  command = plan
  variables {
    project_id      = var.project_id
    log_integration = {}
  }
  assert {
    condition     = length(module.log_integration) == 0
    error_message = "Expected no log_integration module when disabled"
  }
  assert {
    condition     = output.log_integration == null
    error_message = "Expected null log_integration output"
  }
}

run "log_integration_with_module_managed_bucket" {
  command = plan
  variables {
    project_id = var.project_id
    log_integration = {
      enabled          = true
      create_s3_bucket = { enabled = true }
      integrations     = [{ log_types = ["MONGOD"], prefix_path = "test" }]
    }
  }
  assert {
    condition     = length(module.log_integration) == 1
    error_message = "Expected log_integration module"
  }
  assert {
    condition     = length(module.cloud_provider_access) == 1
    error_message = "Expected shared CPA created"
  }
  assert {
    condition     = output.log_integration != null
    error_message = "Expected non-null log_integration output"
  }
}

run "log_integration_with_byo_bucket" {
  command = plan
  variables {
    project_id = var.project_id
    log_integration = {
      enabled      = true
      bucket_name  = "existing-bucket"
      integrations = [{ log_types = ["MONGOD"], prefix_path = "test" }]
    }
  }
  assert {
    condition     = length(module.log_integration) == 1
    error_message = "Expected log_integration module"
  }
  assert {
    condition     = output.log_integration.expiration_days == null
    error_message = "Expected expiration_days = null for BYO bucket"
  }
}

run "log_integration_with_dedicated_iam_role" {
  command = plan
  variables {
    project_id = var.project_id
    log_integration = {
      enabled          = true
      create_s3_bucket = { enabled = true }
      integrations     = [{ log_types = ["MONGOD"], prefix_path = "test" }]
      iam_role         = { create = true }
    }
  }
  assert {
    condition     = length(module.log_integration_cloud_provider_access) == 1
    error_message = "Expected dedicated log integration IAM role"
  }
  assert {
    condition     = length(module.log_integration) == 1
    error_message = "Expected log_integration module"
  }
}

run "log_integration_multiple_integrations" {
  command = plan
  variables {
    project_id = var.project_id
    log_integration = {
      enabled          = true
      create_s3_bucket = { enabled = true }
      integrations = [
        { log_types = ["MONGOD"], prefix_path = "operational/" },
        { log_types = ["MONGOD_AUDIT"], prefix_path = "audit/" },
      ]
    }
  }
  assert {
    condition     = length(module.log_integration) == 1
    error_message = "Expected log_integration module"
  }
}

run "log_integration_with_per_integration_byo_bucket" {
  command = plan
  variables {
    project_id = var.project_id
    log_integration = {
      enabled     = true
      bucket_name = "default-bucket"
      integrations = [
        { log_types = ["MONGOD"], prefix_path = "operational" },
        { log_types = ["MONGOD_AUDIT"], prefix_path = "audit", bucket_name = "audit-bucket" },
      ]
    }
  }
  assert {
    condition     = length(module.log_integration) == 1
    error_message = "Expected log_integration module"
  }
}

run "log_integration_with_kms_key" {
  command = plan
  variables {
    project_id = var.project_id
    log_integration = {
      enabled          = true
      create_s3_bucket = { enabled = true }
      integrations     = [{ log_types = ["MONGOD"], prefix_path = "test" }]
      kms_key          = "arn:aws:kms:us-east-1:123456789012:key/log-key"
    }
  }
  assert {
    condition     = length(module.log_integration) == 1
    error_message = "Expected log_integration module"
  }
}

run "skip_iam_policy_attachments_requires_create_false" {
  command = plan
  variables {
    project_id = var.project_id
    cloud_provider_access = {
      create                      = true
      skip_iam_policy_attachments = true
    }
  }
  expect_failures = [var.cloud_provider_access]
}

run "skip_iam_with_create_kms_key_fails" {
  command = plan
  variables {
    project_id = var.project_id
    cloud_provider_access = {
      create                      = false
      skip_iam_policy_attachments = true
      existing = {
        role_id      = "role123"
        iam_role_arn = "arn:aws:iam::123456789012:role/atlas-role"
      }
    }
    encryption = {
      enabled        = true
      create_kms_key = { enabled = true }
    }
  }
  expect_failures = [var.cloud_provider_access]
}

run "skip_iam_with_create_s3_bucket_backup_fails" {
  command = plan
  variables {
    project_id = var.project_id
    cloud_provider_access = {
      create                      = false
      skip_iam_policy_attachments = true
      existing = {
        role_id      = "role123"
        iam_role_arn = "arn:aws:iam::123456789012:role/atlas-role"
      }
    }
    backup_export = {
      enabled          = true
      create_s3_bucket = { enabled = true }
    }
  }
  expect_failures = [var.cloud_provider_access]
}

run "skip_iam_with_create_s3_bucket_log_fails" {
  command = plan
  variables {
    project_id = var.project_id
    cloud_provider_access = {
      create                      = false
      skip_iam_policy_attachments = true
      existing = {
        role_id      = "role123"
        iam_role_arn = "arn:aws:iam::123456789012:role/atlas-role"
      }
    }
    log_integration = {
      enabled          = true
      create_s3_bucket = { enabled = true }
      integrations     = [{ log_types = ["MONGOD"], prefix_path = "test" }]
    }
  }
  expect_failures = [var.cloud_provider_access]
}

run "skip_iam_policy_attachments_with_backup_export" {
  command = plan
  variables {
    project_id = var.project_id
    cloud_provider_access = {
      create                      = false
      skip_iam_policy_attachments = true
      existing = {
        role_id      = "role123"
        iam_role_arn = "arn:aws:iam::123456789012:role/service-roles/atlas-role"
      }
    }
    backup_export = {
      enabled     = true
      bucket_name = "my-backup-bucket"
    }
  }
  assert {
    condition     = length(module.backup_export) == 1
    error_message = "Expected backup_export module"
  }
}

run "skip_iam_policy_attachments_with_log_integration" {
  command = plan
  variables {
    project_id = var.project_id
    cloud_provider_access = {
      create                      = false
      skip_iam_policy_attachments = true
      existing = {
        role_id      = "role123"
        iam_role_arn = "arn:aws:iam::123456789012:role/atlas-role"
      }
    }
    log_integration = {
      enabled      = true
      bucket_name  = "my-log-bucket"
      integrations = [{ log_types = ["MONGOD"], prefix_path = "test" }]
    }
  }
  assert {
    condition     = length(module.log_integration) == 1
    error_message = "Expected log_integration module"
  }
}

run "byo_role_without_skip_derives_iam_role_name" {
  command = plan
  variables {
    project_id = var.project_id
    cloud_provider_access = {
      create = false
      existing = {
        role_id      = "role123"
        iam_role_arn = "arn:aws:iam::123456789012:role/path/my-atlas-role"
      }
    }
  }
  assert {
    condition     = output.resource_ids.iam_role_name == "my-atlas-role"
    error_message = "Expected iam_role_name derived from ARN path"
  }
}

run "enable_cloud_provider_access_log_integration" {
  command = plan
  variables {
    project_id = var.project_id
    log_integration = {
      enabled          = true
      create_s3_bucket = { enabled = true }
      integrations     = [{ log_types = ["MONGOD"], prefix_path = "test" }]
    }
    privatelink_endpoints = [
      { region = "us-east-1", subnet_ids = ["subnet-abc"], security_group = { inbound_cidr_blocks = ["10.0.0.0/8"] } }
    ]
  }
  assert {
    condition     = length(module.cloud_provider_access) == 1
    error_message = "Expected cloud_provider_access with log_integration"
  }
}

run "skip_iam_with_dedicated_encryption_role" {
  command = plan
  variables {
    project_id = var.project_id
    cloud_provider_access = {
      create                      = false
      skip_iam_policy_attachments = true
      existing = {
        role_id      = "role123"
        iam_role_arn = "arn:aws:iam::123456789012:role/atlas-role"
      }
    }
    encryption = {
      enabled        = true
      create_kms_key = { enabled = true }
      iam_role       = { create = true }
    }
  }
  assert {
    condition     = length(module.encryption_cloud_provider_access) == 1
    error_message = "Expected dedicated encryption IAM role"
  }
  assert {
    condition     = length(module.encryption) == 1
    error_message = "Expected encryption module"
  }
  assert {
    condition     = output.resource_ids.iam_role_name == "atlas-role"
    error_message = "Expected iam_role_name derived from ARN even when skip_iam_policy_attachments = true"
  }
}
