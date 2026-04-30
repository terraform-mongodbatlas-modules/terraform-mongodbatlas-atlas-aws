<!-- @generated
WARNING: This file is auto-generated. Do not edit directly.
Changes will be overwritten when documentation is regenerated.
Run 'just gen-examples' to regenerate.
-->
# AWS KMS Integration

The AWS KMS Integration example configures Atlas encryption at rest with a module-managed AWS KMS key, including automatic key rotation.

<!-- BEGIN_GETTING_STARTED -->
## Prerequisites

If you are familiar with Terraform and already have a project configured in MongoDB Atlas, go to [commands](#commands).

To deploy MongoDB Atlas in AWS with Terraform:

1. Install [Terraform](https://developer.hashicorp.com/terraform/install) to be able to run `terraform` [commands](#commands).
2. [Sign in](https://account.mongodb.com/account/login) to or [create](https://account.mongodb.com/account/register) your MongoDB Atlas Account.
3. Configure your [authentication](https://registry.terraform.io/providers/mongodb/mongodbatlas/latest/docs#authentication) method.

   **NOTE**: Service Accounts (SA) are the preferred authentication method. See [Grant Programmatic Access to an Organization](https://www.mongodb.com/docs/atlas/configure-api-access/#grant-programmatic-access-to-an-organization) in the MongoDB Atlas documentation for detailed instructions on configuring SA access to your project.

4. Use an existing [MongoDB Atlas project](https://registry.terraform.io/providers/mongodb/mongodbatlas/latest/docs/resources/project) or [create a new Atlas project resource](#optional-create-a-new-atlas-project-resource).
5. Configure your AWS credentials. See the [IAM Permissions Reference](https://github.com/terraform-mongodbatlas-modules/terraform-mongodbatlas-atlas-aws/blob/v0.3.0/docs/iam-permissions.md) for the required permissions per feature.

## Commands

```sh
terraform init # this will download the required providers and create a `terraform.lock.hcl` file.
# configure authentication env-vars (MONGODB_ATLAS_XXX, AWS_XXX)
# configure your `vars.tfvars` with required variables
terraform apply -var-file vars.tfvars
# cleanup
terraform destroy -var-file vars.tfvars
```

## (Optional) Create a New Atlas Project Resource

```hcl
variable "org_id" {
  type    = string
  default = "{ORG_ID}" # REPLACE with your organization id, for example `65def6ce0f722a1507105aa5`.
}

resource "mongodbatlas_project" "this" {
  name   = "atlas-aws"
  org_id = var.org_id
}
```

- Replace the `var.project_id` with `mongodbatlas_project.this.project_id` in the [main.tf](https://github.com/terraform-mongodbatlas-modules/terraform-mongodbatlas-atlas-aws/blob/v0.3.0/examples/encryption/main.tf) file.
<!-- END_GETTING_STARTED -->

## Code Snippet

Copy and use this code to get started quickly:

**main.tf**
```hcl
module "atlas_aws" {
  source  = "terraform-mongodbatlas-modules/atlas-aws/mongodbatlas"
  version = "v0.3.0"
  project_id = var.project_id

  encryption = {
    enabled = true
    create_kms_key = {
      enabled             = true
      alias               = "alias/atlas-encryption"
      enable_key_rotation = true
    }
  }

  aws_tags = var.aws_tags
}

output "encryption" {
  value = module.atlas_aws.encryption
}
```

**Additional files needed:**
- [variables.tf](https://github.com/terraform-mongodbatlas-modules/terraform-mongodbatlas-atlas-aws/blob/v0.3.0/examples/encryption/variables.tf)
- [versions.tf](https://github.com/terraform-mongodbatlas-modules/terraform-mongodbatlas-atlas-aws/blob/v0.3.0/examples/encryption/versions.tf)



## Feedback or Help

- If you have any feedback or trouble, please open a GitHub issue.
