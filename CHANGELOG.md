## (Unreleased)

BREAKING CHANGES:

* module: Normalizes `for_each` keys to lowercase AWS region format (`us-east-1`). Users who deployed with Atlas-format regions (`US_EAST_1`) must add `moved` blocks or run `terraform state mv` before upgrading, see [v0.3.0 Upgrade Guide](https://github.com/terraform-mongodbatlas-modules/terraform-mongodbatlas-atlas-aws/blob/main/docs/v0.3.0-upgrade-guide.md) ([#33](https://github.com/terraform-mongodbatlas-modules/terraform-mongodbatlas-atlas-aws/pull/33))

NOTES:

* provider/mongodbatlas: Requires minimum version 2.8.0 for mongodbatlas_log_integration resource support ([#34](https://github.com/terraform-mongodbatlas-modules/terraform-mongodbatlas-atlas-aws/pull/34))

ENHANCEMENTS:

* submodule/log_integration: Adds log integration submodule for exporting Atlas logs to S3 via mongodbatlas_log_integration ([#34](https://github.com/terraform-mongodbatlas-modules/terraform-mongodbatlas-atlas-aws/pull/34))
* variable/log_integration: Adds log_integration variable with S3 bucket management, per-integration BYO bucket overrides, KMS encryption, and dedicated IAM role support ([#34](https://github.com/terraform-mongodbatlas-modules/terraform-mongodbatlas-atlas-aws/pull/34))
* variable/timeouts: Adds configurable timeout overrides for Atlas resources (cloud_provider_access, encryption_private_endpoint, privatelink_endpoint, privatelink_endpoint_service, privatelink_regional_mode) ([#32](https://github.com/terraform-mongodbatlas-modules/terraform-mongodbatlas-atlas-aws/pull/32))

## 0.2.0 (February 25, 2026)

BREAKING CHANGES:

* submodule/encryption: Exposes `enabled_for_search_nodes` with secure default (`true`) to control BYOK encryption for dedicated search nodes. Existing deployments with `encryption.enabled = true` and dedicated search nodes will see `enabled_for_search_nodes` flip from `false` to `true` on upgrade. This triggers search node reprovisioning and index rebuild. Set `enabled_for_search_nodes = false` explicitly to preserve current behavior ([#26](https://github.com/terraform-mongodbatlas-modules/terraform-mongodbatlas-aws/pull/26))

## 0.1.1 (February 11, 2026)

BUG FIXES:

* output/export_bucket_id: Uses correct `export_bucket_id` instead of internal `id` field ([#23](https://github.com/terraform-mongodbatlas-modules/terraform-mongodbatlas-aws/pull/23))

## 0.1.0 (February 04, 2026)
* Initial release
