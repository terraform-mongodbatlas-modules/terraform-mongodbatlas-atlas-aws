mock_provider "mongodbatlas" {}
mock_provider "aws" {}
mock_provider "time" {}

variables {
  project_id = "000000000000000000000000"
}

run "encryption_waits_for_iam_after_kms_policy" {
  command = plan
  variables {
    project_id = var.project_id
    encryption = {
      enabled        = true
      create_kms_key = { enabled = true }
    }
  }
  assert {
    condition     = module.encryption[0].iam_propagation.create_duration == "30s"
    error_message = "Expected 30s IAM propagation sleep before encryption at rest"
  }
  assert {
    condition     = contains(module.encryption[0].iam_propagation.trigger_keys, "kms_key_id")
    error_message = "Expected sleep trigger kms_key_id so a CMK replace re-runs the wait"
  }
  assert {
    condition     = contains(module.encryption[0].iam_propagation.trigger_keys, "iam_policy")
    error_message = "Expected sleep trigger iam_policy so role policy changes re-run the wait"
  }
}

run "encryption_skips_iam_sleep_when_skip_attachments" {
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
  }
  assert {
    condition     = module.encryption[0].iam_propagation == null
    error_message = "Expected no IAM sleep when skip_iam_policy_attachments is true"
  }
}
