mock_provider "mongodbatlas" {}
mock_provider "aws" {}
mock_provider "time" {}

variables {
  project_id = "000000000000000000000000"
}

run "infer_empty_single_pl" {
  command = plan
  variables {
    project_id = var.project_id
    encryption = {
      enabled        = true
      region         = "us-east-1"
      create_kms_key = { enabled = true }
    }
    privatelink_endpoints = [
      { region = "us-east-1", subnet_ids = ["subnet-abc"], security_group = { inbound_cidr_blocks = ["10.0.0.0/8"] } }
    ]
  }
  assert {
    condition     = length(keys(module.encryption[0].kms_replica_key_arns)) == 0
    error_message = "Expected no replica keys when the only PrivateLink region is the primary"
  }
}

run "infer_from_pl" {
  command = plan
  variables {
    project_id = var.project_id
    encryption = {
      enabled        = true
      region         = "us-east-1"
      create_kms_key = { enabled = true }
    }
    privatelink_endpoints = [
      { region = "us-east-1", subnet_ids = ["subnet-abc"], security_group = { inbound_cidr_blocks = ["10.0.0.0/8"] } },
      { region = "us-west-2", subnet_ids = ["subnet-def"], security_group = { inbound_cidr_blocks = ["10.0.0.0/8"] } },
    ]
  }
  assert {
    condition     = toset(keys(module.encryption[0].kms_replica_key_arns)) == toset(["us-west-2"])
    error_message = "Expected replica key in us-west-2 inferred from PrivateLink"
  }
}

run "infer_pe_wins_over_pl" {
  command = plan
  variables {
    project_id = var.project_id
    encryption = {
      enabled                  = true
      region                   = "us-east-1"
      create_kms_key           = { enabled = true }
      private_endpoint_regions = ["us-west-2"]
    }
    privatelink_endpoints = [
      { region = "us-east-1", subnet_ids = ["subnet-abc"], security_group = { inbound_cidr_blocks = ["10.0.0.0/8"] } },
      { region = "eu-west-1", subnet_ids = ["subnet-def"], security_group = { inbound_cidr_blocks = ["10.0.0.0/8"] } },
    ]
  }
  assert {
    condition     = toset(keys(module.encryption[0].kms_replica_key_arns)) == toset(["us-west-2"])
    error_message = "Expected replica keys from private_endpoint_regions only, not PrivateLink"
  }
}

run "explicit_empty_skips_pl" {
  command = plan
  variables {
    project_id = var.project_id
    encryption = {
      enabled = true
      region  = "us-east-1"
      create_kms_key = {
        enabled         = true
        replica_regions = []
      }
    }
    privatelink_endpoints = [
      { region = "us-east-1", subnet_ids = ["subnet-abc"], security_group = { inbound_cidr_blocks = ["10.0.0.0/8"] } },
      { region = "us-west-2", subnet_ids = ["subnet-def"], security_group = { inbound_cidr_blocks = ["10.0.0.0/8"] } },
    ]
  }
  assert {
    condition     = length(keys(module.encryption[0].kms_replica_key_arns)) == 0
    error_message = "Expected replica_regions = [] to skip PrivateLink inference"
  }
}

run "explicit_set_wins_over_pe" {
  command = plan
  variables {
    project_id = var.project_id
    encryption = {
      enabled = true
      region  = "us-east-1"
      create_kms_key = {
        enabled         = true
        replica_regions = ["eu-west-1"]
      }
      private_endpoint_regions = ["us-west-2"]
    }
  }
  assert {
    condition     = toset(keys(module.encryption[0].kms_replica_key_arns)) == toset(["eu-west-1"])
    error_message = "Expected explicit replica_regions to win over private_endpoint_regions"
  }
}

run "pin_skips_infer" {
  command = plan
  variables {
    project_id = var.project_id
    encryption = {
      enabled = true
      region  = "us-east-1"
      create_kms_key = {
        enabled      = true
        multi_region = false
      }
    }
    privatelink_endpoints = [
      { region = "us-east-1", subnet_ids = ["subnet-abc"], security_group = { inbound_cidr_blocks = ["10.0.0.0/8"] } },
      { region = "us-west-2", subnet_ids = ["subnet-def"], security_group = { inbound_cidr_blocks = ["10.0.0.0/8"] } },
    ]
  }
  assert {
    condition     = length(keys(module.encryption[0].kms_replica_key_arns)) == 0
    error_message = "Expected multi_region = false to skip replica inference"
  }
}

run "cross_region_pl_ignored" {
  command = plan
  variables {
    project_id = var.project_id
    encryption = {
      enabled        = true
      region         = "us-east-1"
      create_kms_key = { enabled = true }
    }
    privatelink_endpoints = [
      { region = "us-east-1", subnet_ids = ["subnet-abc"], security_group = { inbound_cidr_blocks = ["10.0.0.0/8"] } },
      { region = "us-west-2", subnet_ids = ["subnet-def"], service_region = "us-east-1", security_group = { inbound_cidr_blocks = ["10.0.0.0/8"] } },
    ]
  }
  assert {
    condition     = length(keys(module.encryption[0].kms_replica_key_arns)) == 0
    error_message = "Expected cross-region PrivateLink VPC rows not to infer replica keys"
  }
}

run "byo_no_replicas" {
  command = plan
  variables {
    project_id = var.project_id
    encryption = {
      enabled     = true
      region      = "us-east-1"
      kms_key_arn = "arn:aws:kms:us-east-1:123456789012:key/abc"
    }
    privatelink_endpoints = [
      { region = "us-east-1", subnet_ids = ["subnet-abc"], security_group = { inbound_cidr_blocks = ["10.0.0.0/8"] } },
      { region = "us-west-2", subnet_ids = ["subnet-def"], security_group = { inbound_cidr_blocks = ["10.0.0.0/8"] } },
    ]
  }
  assert {
    condition     = length(keys(module.encryption[0].kms_replica_key_arns)) == 0
    error_message = "Expected no replica keys for BYO kms_key_arn"
  }
}
