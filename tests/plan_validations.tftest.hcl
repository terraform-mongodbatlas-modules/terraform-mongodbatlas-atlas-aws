mock_provider "mongodbatlas" {}
mock_provider "aws" {}

variables {
  project_id = "000000000000000000000000"
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

run "privatelink_byoe_key_overlap_validation" {
  command = plan
  variables {
    project_id = var.project_id
    privatelink_endpoints = [
      { region = "us-east-1", subnet_ids = ["subnet-abc"] }
    ]
    privatelink_byoe_regions = {
      "us-east-1" = "us-east-1"
    }
  }
  expect_failures = [var.privatelink_byoe_regions]
}

run "privatelink_byoe_missing_region" {
  command = plan
  variables {
    project_id = var.project_id
    privatelink_byoe_regions = {
      primary = "us-east-1"
    }
    privatelink_byoe = {
      secondary = { vpc_endpoint_id = "vpce-abc" }
    }
  }
  expect_failures = [var.privatelink_byoe]
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

run "privatelink_byoe_phase1_atlas_endpoint_created" {
  command = plan
  variables {
    project_id = var.project_id
    # Phase 1: Only declare BYOE regions, no endpoint IDs yet
    privatelink_byoe_regions = {
      primary = "us-east-1"
    }
    # privatelink_byoe is NOT provided - waiting for endpoint_service_name
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

run "privatelink_byoe_phase2_with_endpoint" {
  command = plan
  variables {
    project_id = var.project_id
    # Phase 2: Provide both regions and endpoint IDs
    privatelink_byoe_regions = {
      primary = "us-east-1"
    }
    privatelink_byoe = {
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

run "privatelink_byoe_multi_region_phase2" {
  command = plan
  variables {
    project_id = var.project_id
    privatelink_byoe_regions = {
      primary   = "us-east-1"
      secondary = "eu-west-1"
    }
    privatelink_byoe = {
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
