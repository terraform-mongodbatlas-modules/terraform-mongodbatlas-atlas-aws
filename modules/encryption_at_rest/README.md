# MongoDB Atlas Encryption at Rest Module

Configures MongoDB Atlas encryption at rest using AWS KMS.

## Usage

```hcl
module "encryption_at_rest" {
  source = "./modules/encryption_at_rest"

  project_id   = "your-atlas-project-id"
  atlas_region = "US_EAST_1"

  # Create new KMS key and IAM role
  create_kms_key      = true
  create_kms_iam_role = true

  # Optional: customize KMS key
  kms_key_alias       = "mongodb-atlas-encryption"
  kms_key_description = "Customer managed key for MongoDB Atlas encryption at rest"
  aws_iam_role_name   = "atlas-kms-role"

  # Private networking configuration
  private_networking = {
    require_private_networking    = true
    create_atlas_private_endpoint = true
    create_kms_vpc_endpoint       = true
    vpc_endpoint_subnet_ids       = ["subnet-xxx", "subnet-yyy"]
  }
}
```

## Use Cases

The module supports four configurations via boolean flags:

| `create_kms_key` | `create_kms_iam_role` | Description |
|------------------|-----------------------|-------------|
| `true` | `true` | Create new KMS key and dedicated IAM role |
| `true` | `false` | Create new KMS key, use shared IAM role |
| `false` | `true` | Use existing KMS key, create dedicated IAM role |
| `false` | `false` | Use existing KMS key and shared IAM role |

## Future Considerations

### Mode-based Pattern

The current boolean flag approach works but creates a combinatorial explosion of valid/invalid states. A future improvement could replace boolean flags with a mode enum:

```hcl
variable "mode" {
  type = string
  validation {
    condition     = contains(["create_all", "create_kms_only", "use_existing"], var.mode)
    error_message = "mode must be one of: create_all, create_kms_only, use_existing"
  }
}
```

This would make the intent clearer and eliminate invalid combinations.

### Variable Grouping

Related inputs could be grouped into logical objects for a cleaner interface:

```hcl
variable "kms_key" {
  type = object({
    create               = optional(bool, false)
    existing_arn         = optional(string)
    alias                = optional(string, "mongodb-atlas-encryption")
    description          = optional(string)
    deletion_window_days = optional(number, 30)
  })
}

variable "iam_role" {
  type = object({
    create           = optional(bool, false)
    existing_arn     = optional(string)
    existing_role_id = optional(string)
    name             = optional(string, "atlas-kms-role")
    policy_name      = optional(string, "AtlasEncryptionAtRestPolicy")
  })
}
```

This reduces the number of top-level variables and makes the module interface easier to understand.
