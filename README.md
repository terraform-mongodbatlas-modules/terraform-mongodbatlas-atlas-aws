# MongoDB Atlas AWS Terraform Module

Use this Terraform module to configure MongoDB Atlas integrations with AWS. The module includes recommended defaults based on MongoDB best practices.

<!-- BEGIN_TOC -->
<!-- @generated
WARNING: This section is auto-generated. Do not edit directly.
Changes will be overwritten when documentation is regenerated.
Run 'just gen-readme' to regenerate. -->
- [Public Preview Note](#public-preview-note)
- [Disclaimer](#disclaimer)
- [Getting Started](#getting-started)
- [Examples](#examples)
- [Requirements](#requirements)
- [Providers](#providers)
- [Resources](#resources)
- [Required Variables](#required-variables)
- [AWS Cloud Provider Access](#aws-cloud-provider-access)
- [Encryption at Rest](#encryption-at-rest)
- [Private Link](#private-link)
- [Backup Export](#backup-export)
- [Optional Variables](#optional-variables)
- [Outputs](#outputs)
- [FAQ](#faq)
<!-- END_TOC -->

## Public Preview Note

The MongoDB Atlas AWS Module (Public Preview) simplifies Atlas-AWS integrations and applies MongoDB's best practices as intelligent defaults. This preview validates that these patterns meet the needs of most workloads with minimal maintenance or rework. Share feedback and contribute improvements during the preview phase. MongoDB formally supports this module starting with v1.

<!-- BEGIN_DISCLAIMER -->
## Disclaimer

One of the project's primary objectives is to provide durable modules that support non-breaking migration and upgrade paths. The v0 release (Public Preview) of the MongoDB Atlas AWS Module focuses on gathering feedback and refining the design. Upgrades from v0 to v1 may not be seamless. We plan to deliver a finalized v1 release early next year with long-term upgrade support.

<!-- END_DISCLAIMER -->
## Getting Started

<!-- BEGIN_GETTING_STARTED -->
<!-- @generated
WARNING: This section is auto-generated. Do not edit directly.
Changes will be overwritten when documentation is regenerated.
Run 'just gen-readme' to regenerate. -->
### Prerequisites

If you are familiar with Terraform and already have a project configured in MongoDB Atlas, go to [commands](#commands).

To deploy MongoDB Atlas in AWS with Terraform, ensure you meet the following requirements:

1. Install [Terraform](https://developer.hashicorp.com/terraform/install) to be able to run `terraform` [commands](#commands).
2. [Sign in](https://account.mongodb.com/account/login) or [create](https://account.mongodb.com/account/register) your MongoDB Atlas Account.
3. Configure your [authentication](https://registry.terraform.io/providers/mongodb/mongodbatlas/latest/docs#authentication) method.

   **NOTE**: Service Accounts (SA) are the preferred authentication method. See [Grant Programmatic Access to an Organization](https://www.mongodb.com/docs/atlas/configure-api-access/#grant-programmatic-access-to-an-organization) in the MongoDB Atlas documentation for detailed instructions on configuring SA access to your project.

4. Use an existing [MongoDB Atlas project](https://registry.terraform.io/providers/mongodb/mongodbatlas/latest/docs/resources/project) or [create a new Atlas project resource](#optional-create-a-new-atlas-project-resource).
5. Authenticate your AWS CLI (`aws configure`) or configure your IAM credentials.

### Commands

```sh
terraform init # this will download the required providers and create a `terraform.lock.hcl` file.
# configure authentication env-vars (MONGODB_ATLAS_XXX, AWS_XXX)
# configure your `vars.tfvars` with required variables
terraform apply -var-file vars.tfvars
# cleanup
terraform destroy -var-file vars.tfvars
```

### (Optional) Create a New Atlas Project Resource

```hcl
variable "org_id" {
  type    = string
  default = "{ORG_ID}" # REPLACE with your organization id, for example `65def6ce0f722a1507105aa5`.
}

resource "mongodbatlas_project" "this" {
  name   = "cluster-module"
  org_id = var.org_id
}
```

- Replace the `var.project_id` with `mongodbatlas_project.this.project_id` in the [main.tf](./main.tf) file.

<!-- END_GETTING_STARTED -->

### Set Up Encryption at Rest with AWS KMS

Complete the following steps to configure encryption at rest with AWS KMS:

1. Prepare your terraform files.
  
   You can copy the files directly from the examples provided in this module:

    - [examples/encryption/main.tf](examples/encryption/main.tf)
    - [examples/encryption/variables.tf](examples/encryption/variables.tf)
    - [examples/encryption/versions.tf](examples/encryption/versions.tf)

    The following code example shows a basic example of a `main.tf` file configuration:

    ```hcl
    module "atlas_aws" {
      source     = "terraform-mongodbatlas-modules/atlas-aws/mongodbatlas"
      project_id = var.project_id

      encryption = {
        enabled = true
        create_kms_key = {
          enabled             = true
          alias               = "alias/atlas-encryption"
          enable_key_rotation = true
        }
      }
    
      output "all_outputs" {
        value = module.atlas_aws
      }
    
    }
    ```

2. Prepare your [variables](#required-variables)

    The following example shows a `vars.tfvars` with the variables to provide at `apply` time:

    ```hcl
    project_id = "YOUR_PROJECT_ID"
    aws_region = "YOUR_AWS_REGION"
    ```

3. Ensure your authentication environment variables are configured.

    The best practice is to use an [`AWS_PROFILE`](https://docs.aws.amazon.com/cli/latest/reference/configure/) environment variable.

    ```sh
    export MONGODB_ATLAS_CLIENT_ID="your-client-id-goes-here"
    export MONGODB_ATLAS_CLIENT_SECRET="your-client-secret-goes-here"
    export AWS_PROFILE="your-aws-profile-goes-here"
    ```

    Alternatively, you can use an access key and ID.

    ```sh
    export MONGODB_ATLAS_CLIENT_ID="your-client-id-goes-here"
    export MONGODB_ATLAS_CLIENT_SECRET="your-client-secret-goes-here"
    export AWS_ACCESS_KEY_ID="your-aws-access-key-id"
    export AWS_SECRET_ACCESS_KEY="your-aws-secret-access-key"
    ```

    For more details on authentication methods, see [Prerequisites](#prerequisites).

4. Initialize and apply your Terraform configuration (See [Commands](#commands)).

5. Verify your [outputs](#outputs).

You now have encryption at rest configured with AWS KMS.

See the [Examples](#examples) section for additional configurations.

### Clean up your configuration

Run `terraform destroy -var-file vars.tfvars` to undo all changes that Terraform made to your infrastructure.

<!-- BEGIN_TABLES -->
<!-- @generated
WARNING: This section is auto-generated. Do not edit directly.
Changes will be overwritten when documentation is regenerated.
Run 'just gen-readme' to regenerate. -->
## Examples

Feature | Name
--- | ---
Encryption at Rest | [AWS KMS Integration](./examples/encryption)
Encryption at Rest | [AWS KMS Integration with Private Endpoint](./examples/encryption_private_endpoint)
Private Link | [AWS PrivateLink Endpoint](./examples/privatelink)
Private Link | [AWS PrivateLink Multi-Region](./examples/privatelink_multi_region)
Private Link | [AWS PrivateLink BYOE](./examples/privatelink_byoe)
Backup Export | [S3 Bucket Export](./examples/backup_export)

<!-- END_TABLES -->
<!-- BEGIN_TF_DOCS -->
<!-- @generated
WARNING: This section is auto-generated by terraform-docs. Do not edit directly.
Changes will be overwritten when documentation is regenerated.
Run 'just docs' to regenerate.
-->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](https://developer.hashicorp.com/terraform/install) (>= 1.9)

- <a name="requirement_aws"></a> [aws](https://registry.terraform.io/providers/hashicorp/aws/latest/docs) (>= 6.0)

- <a name="requirement_mongodbatlas"></a> [mongodbatlas](https://registry.terraform.io/providers/mongodb/mongodbatlas/latest/docs) (~> 2.1)

## Providers

The following providers are used by this module:

- <a name="provider_aws"></a> [aws](https://registry.terraform.io/providers/hashicorp/aws/latest/docs) (>= 6.0)

- <a name="provider_mongodbatlas"></a> [mongodbatlas](https://registry.terraform.io/providers/mongodb/mongodbatlas/latest/docs) (~> 2.1)

## Resources

The following resources are used by this module:

- [mongodbatlas_private_endpoint_regional_mode.this](https://registry.terraform.io/providers/mongodb/mongodbatlas/latest/docs/resources/private_endpoint_regional_mode) (resource)
- [mongodbatlas_privatelink_endpoint.this](https://registry.terraform.io/providers/mongodb/mongodbatlas/latest/docs/resources/privatelink_endpoint) (resource)
- [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) (data source)

<!-- BEGIN_TF_INPUTS_RAW -->
<!-- @generated
WARNING: This grouped inputs section is auto-generated. Do not edit directly.
Changes will be overwritten when documentation is regenerated.
Run 'just docs' to regenerate.
-->
## Required Variables

### project_id

MongoDB Atlas project ID

Type: `string`


## AWS Cloud Provider Access

Configure the AWS IAM role used by MongoDB Atlas. See the [AWS cloud provider access documentation](https://www.mongodb.com/docs/atlas/security/set-up-unified-aws-access/) for details.

_No variables in this section yet._

## Encryption at Rest

Configure encryption at rest using AWS KMS. See the [AWS encryption documentation](https://www.mongodb.com/docs/atlas/security-aws-kms/) for details.

### encryption

Encryption at rest configuration with AWS KMS.

Provide EITHER:
- `kms_key_arn` (user-provided KMS key)
- `create_kms_key.enabled = true` (module-managed KMS key)

**IAM Role Strategy:**
- `iam_role.create = false` (default): Uses the shared IAM role from `cloud_provider_access`.
- `iam_role.create = true`: Creates a dedicated IAM role for encryption.

**Search Node Encryption:**
`enabled_for_search_nodes` (default: `true`) controls whether BYOK encryption applies to dedicated search nodes. The module defaults to `true` (provider default is `false`) for a secure-by-default experience. Flipping from `false` to `true` on a deployment with dedicated search nodes triggers reprovisioning and index rebuild.

**Private Networking:**
When `private_endpoint_regions` is non-empty, Atlas creates PrivateLink connections to AWS KMS. Traffic stays on AWS's private network. No user-side VPC endpoint required.

Type:

```hcl
object({
  enabled     = optional(bool, false)
  kms_key_arn = optional(string)
  region      = optional(string)
  create_kms_key = optional(object({
    enabled                 = bool
    alias                   = optional(string, "alias/atlas-encryption")
    deletion_window_in_days = optional(number, 7)
    enable_key_rotation     = optional(bool, true)
    policy_override         = optional(string)
  }))
  enabled_for_search_nodes = optional(bool, true)
  private_endpoint_regions = optional(set(string), [])
  iam_role = optional(object({
    create               = optional(bool, false)
    name                 = optional(string)
    path                 = optional(string, "/")
    permissions_boundary = optional(string)
  }), { create = false })
})
```

Default: `{}`


## Private Link

Configure AWS PrivateLink endpoints for secure connectivity. See the [AWS PrivateLink documentation](https://www.mongodb.com/docs/atlas/security-private-endpoint/) for details.

### privatelink_endpoints

Multi-region PrivateLink endpoints. Region accepts us-east-1 or US_EAST_1 format. All regions must be UNIQUE.
See [Port ranges used for private endpoints](https://www.mongodb.com/docs/atlas/security-private-endpoint/#port-ranges-used-for-private-endpoints) for port range details.

Type:

```hcl
list(object({
  region     = string
  subnet_ids = list(string)
  security_group = optional(object({
    ids                 = optional(list(string))
    create              = optional(bool, true)
    name_prefix         = optional(string, "atlas-privatelink-")
    inbound_cidr_blocks = optional(list(string)) # null = VPC CIDR, [] = no rule
    inbound_source_sgs  = optional(set(string), [])
    from_port           = optional(number, 1024)
    to_port             = optional(number, 65535)
  }), {})
  tags = optional(map(string), {})
}))
```

Default: `[]`

### privatelink_byoe

BYOE Phase 2: Key must exist in `privatelink_byoe_regions`.

Type:

```hcl
map(object({
  vpc_endpoint_id = string
}))
```

Default: `{}`


## Backup Export

Configure backup snapshot export to AWS S3.

### backup_export

Backup snapshot export to S3 configuration.

Provide EITHER:
- `bucket_name` (user-provided S3 bucket)
- `create_s3_bucket.enabled = true` (module-managed S3 bucket)

**Bucket Naming (when module-managed):**
- `create_s3_bucket.name` - Exact bucket name (conflicts with name_prefix)
- `create_s3_bucket.name_prefix` - Prefix with Terraform-generated suffix (max 37 chars)
- Default: `atlas-backup-{project_id_suffix}-` when neither specified

**Security Defaults (when module-managed):**
- Versioning enabled for backup recovery
- SSE with aws:kms for encryption at rest
- All public access blocked

When `iam_role.create = true`, creates a dedicated IAM role for backup export instead of using the shared role.

Type:

```hcl
object({
  enabled     = optional(bool, false)
  bucket_name = optional(string)
  create_s3_bucket = optional(object({
    enabled                 = bool
    region                  = optional(string)
    name                    = optional(string)
    name_prefix             = optional(string)
    force_destroy           = optional(bool, false)
    versioning_enabled      = optional(bool, true)
    server_side_encryption  = optional(string, "aws:kms")
    block_public_acls       = optional(bool, true)
    block_public_policy     = optional(bool, true)
    ignore_public_acls      = optional(bool, true)
    restrict_public_buckets = optional(bool, true)
  }), { enabled = false })
  iam_role = optional(object({
    create               = optional(bool, false)
    name                 = optional(string)
    path                 = optional(string, "/")
    permissions_boundary = optional(string)
  }), { create = false })
})
```

Default: `{}`


## Optional Variables

### aws_tags

Tags to apply to all AWS resources created by this module.

Type: `map(string)`

Default: `{}`

### cloud_provider_access

Cloud provider access configuration for Atlas-AWS integration.

- `create = true` (default): Creates a shared IAM role and Atlas authorization
- `create = false`: Use existing role via `existing.role_id` and `existing.iam_role_arn`
- `iam_role_name`: Custom name for the IAM role (default: atlas-{project_id_suffix}-{purpose})
- `iam_role_path`: IAM role path (default: /)
- `iam_role_permissions_boundary`: ARN of permissions boundary policy

Type:

```hcl
object({
  create = optional(bool, true)
  existing = optional(object({
    role_id      = string
    iam_role_arn = string
  }))
  iam_role_name                 = optional(string)
  iam_role_path                 = optional(string, "/")
  iam_role_permissions_boundary = optional(string)
})
```

Default: `{}`

### privatelink_byoe_regions

BYOE Phase 1: Key is user identifier, value is region (us-east-1 or US_EAST_1).

Type: `map(string)`

Default: `{}`

### privatelink_endpoints_single_region

Single-region multi-endpoint pattern. Region accepts us-east-1 or US_EAST_1 format. All regions must MATCH.
See [Port ranges used for private endpoints](https://www.mongodb.com/docs/atlas/security-private-endpoint/#port-ranges-used-for-private-endpoints) for port range details.

Type:

```hcl
list(object({
  region     = string
  subnet_ids = list(string)
  security_group = optional(object({
    ids                 = optional(list(string))
    create              = optional(bool, true)
    name_prefix         = optional(string, "atlas-privatelink-")
    inbound_cidr_blocks = optional(list(string))
    inbound_source_sgs  = optional(set(string), [])
    from_port           = optional(number, 1024)
    to_port             = optional(number, 65535)
  }), {})
  tags = optional(map(string), {})
}))
```

Default: `[]`

<!-- END_TF_INPUTS_RAW -->

## Outputs

The following outputs are exported:

### <a name="output_backup_export"></a> [backup\_export](#output\_backup\_export)

Description: Backup export configuration

### <a name="output_encryption"></a> [encryption](#output\_encryption)

Description: Encryption at rest status and configuration

### <a name="output_encryption_at_rest_provider"></a> [encryption\_at\_rest\_provider](#output\_encryption\_at\_rest\_provider)

Description: Value for cluster's encryption\_at\_rest\_provider attribute

### <a name="output_export_bucket_id"></a> [export\_bucket\_id](#output\_export\_bucket\_id)

Description: Export bucket ID for backup schedule auto\_export\_enabled

### <a name="output_privatelink"></a> [privatelink](#output\_privatelink)

Description: PrivateLink status per endpoint key

### <a name="output_privatelink_service_info"></a> [privatelink\_service\_info](#output\_privatelink\_service\_info)

Description: Atlas PrivateLink service info for BYOE pattern

### <a name="output_regional_mode_enabled"></a> [regional\_mode\_enabled](#output\_regional\_mode\_enabled)

Description: Whether private endpoint regional mode is enabled

### <a name="output_resource_ids"></a> [resource\_ids](#output\_resource\_ids)

Description: All resource IDs for data source lookups

### <a name="output_role_id"></a> [role\_id](#output\_role\_id)

Description: Atlas role ID for reuse with other Atlas-AWS features
<!-- END_TF_DOCS -->

## FAQ

### What does `provider_meta "mongodbatlas"` do?

This block tracks module usage by updating the User-Agent header of requests to Atlas.

Example:

```text
User-Agent: terraform-provider-mongodbatlas/2.1.0 Terraform/1.13.1 module_name/atlas-aws module_version/0.1.0
```

- The `provider_meta "mongodbatlas"` block does not send configuration-specific data. It sends only the module name and version for feature adoption tracking.
- Use `export TF_LOG=debug` to see API requests with headers and responses.
