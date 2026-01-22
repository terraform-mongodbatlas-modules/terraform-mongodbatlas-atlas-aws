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
    privatelink_endpoints = {
      us-east-1 = { subnet_ids = ["subnet-abc"] }
    }
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
    privatelink_endpoints = {
      us-east-1 = { subnet_ids = ["subnet-abc"] }
    }
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
    privatelink_endpoints = {
      us-east-1 = { subnet_ids = ["subnet-abc"] }
    }
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

run "encryption_validation_private_networking_without_regions" {
  command = plan
  variables {
    project_id = var.project_id
    encryption = {
      enabled                    = true
      kms_key_arn                = "arn:aws:kms:us-east-1:123456789012:key/abc"
      require_private_networking = true
    }
  }
  expect_failures = [var.encryption]
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

run "privatelink_byoe_key_overlap_validation" {
  command = plan
  variables {
    project_id = var.project_id
    privatelink_endpoints = {
      us-east-1 = { subnet_ids = ["subnet-abc"] }
    }
    privatelink_byoe_regions = {
      us-east-1 = "us-east-1"
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
      secondary = {
        vpc_endpoint_id             = "vpce-abc"
        private_endpoint_ip_address = "10.0.0.1"
      }
    }
  }
  expect_failures = [var.privatelink_byoe]
}
