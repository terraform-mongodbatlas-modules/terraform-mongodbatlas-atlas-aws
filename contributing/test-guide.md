# Testing Guide

Guide for running tests on the terraform-mongodbatlas-atlas-aws module.

## Authentication Setup

```bash
# MongoDB Atlas
export MONGODB_ATLAS_CLIENT_ID=your_sa_client_id
export MONGODB_ATLAS_CLIENT_SECRET=your_sa_client_secret
export MONGODB_ATLAS_ORG_ID=your_org_id
export MONGODB_ATLAS_BASE_URL=https://cloud.mongodb.com/  # optional

# AWS
export AWS_ACCESS_KEY_ID=your_aws_access_key_id
export AWS_SECRET_ACCESS_KEY=your_aws_secret_access_key
export AWS_REGION=us-east-1
```

See [MongoDB Atlas Provider Authentication](https://registry.terraform.io/providers/mongodb/mongodbatlas/latest/docs#authentication) and [AWS Provider Authentication](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#authentication-and-configuration) for details.

## Test Commands

```bash
# Plan-only tests (no resources created)
just unit-plan-tests
```

## Version Compatibility Testing

```bash
just test-compat
```

Runs `terraform init` and `terraform validate` across all supported Terraform versions. Requires [mise](https://mise.jdx.dev/).

## Plan Snapshot Tests

Plan snapshot tests verify `terraform plan` output consistency. They use workspace directories under `tests/workspace_aws_examples/`.

### Generating dev.tfvars

The `dev-vars-aws` command reads from environment variables (see Authentication Setup above):

```bash
# Generate dev.tfvars from environment variables
just dev-vars-aws
```

Optional env vars:
- `MONGODB_ATLAS_PROJECT_ID` - Use same project ID for all examples (plan snapshot tests)

### Running Tests

```bash
# Run plan snapshot tests (requires full path to var file)
just plan-snapshot-test --var-file $(pwd)/tests/workspace_aws_examples/dev.tfvars

# Apply examples (creates real resources)
just apply-examples --var-file $(pwd)/tests/workspace_aws_examples/dev.tfvars --auto-approve

# Destroy resources after testing
just destroy-examples --auto-approve
```

### Snapshot Configuration

Configure examples in `tests/workspace_aws_examples/workspace_test_config.yaml`:

```yaml
examples:
  - name: encryption          # folder name (no number prefix needed)
    var_groups: [encryption]
    plan_regressions:
      - address: module.atlas_aws.module.encryption[0].mongodbatlas_encryption_at_rest.this
```

## Provider Dev Branch Testing

```bash
git clone https://github.com/mongodb/terraform-provider-mongodbatlas ../provider
just setup-provider-dev ../provider
export TF_CLI_CONFIG_FILE=$(pwd)/dev.tfrc
just unit-plan-tests
```

## CI Required Secrets

| Secret | Description |
|--------|-------------|
| `MONGODB_ATLAS_ORG_ID` | Atlas organization ID |
| `MONGODB_ATLAS_CLIENT_ID` | Service account client ID |
| `MONGODB_ATLAS_CLIENT_SECRET` | Service account client secret |
| `AWS_ACCESS_KEY_ID` | AWS access key ID |
| `AWS_SECRET_ACCESS_KEY` | AWS secret access key |
| `AWS_REGION` | AWS region |
