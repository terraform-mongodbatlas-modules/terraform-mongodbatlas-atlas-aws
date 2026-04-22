## (Unreleased)

BREAKING CHANGES:

* module: Normalizes `for_each` keys to lowercase AWS region format (`us-east-1`). Users who deployed with Atlas-format regions (`US_EAST_1`) must add `moved` blocks or run `terraform state mv` before upgrading, see [v0.3.0 Upgrade Guide](https://github.com/terraform-mongodbatlas-modules/terraform-mongodbatlas-atlas-aws/blob/main/docs/v0.3.0-upgrade-guide.md) ([#33](https://github.com/terraform-mongodbatlas-modules/terraform-mongodbatlas-atlas-aws/pull/33))
* variable/backup_export,log_integration: Changes `versioning_enabled` default from `true` to `false`. With versioning enabled, `expiration.days` only adds a delete marker and noncurrent versions remain indefinitely. Atlas writes timestamp-based object keys with no overwrite risk, so versioning is unnecessary. Set `versioning_enabled = true` to preserve previous behavior ([#38](https://github.com/terraform-mongodbatlas-modules/terraform-mongodbatlas-atlas-aws/pull/38))
* variable/backup_export: Adds `expiration_days` to `create_s3_bucket` (default 365 days). Module-managed backup S3 buckets now create an `aws_s3_bucket_lifecycle_configuration` resource. Existing users see a non-empty plan adding the lifecycle rule. Set `expiration_days = 0` to opt out and preserve previous behavior ([#38](https://github.com/terraform-mongodbatlas-modules/terraform-mongodbatlas-atlas-aws/pull/38))
* variable/backup_export: Adds validation to disallow dot (.) characters in create_s3_bucket.name and create_s3_bucket.name_prefix for Data Exfil Prevention compatibility. Users with dotted module-managed bucket names must rename before upgrading ([#43](https://github.com/terraform-mongodbatlas-modules/terraform-mongodbatlas-atlas-aws/pull/43))
* variable/log_integration: Adds validation to disallow dot (.) characters in create_s3_bucket.name and create_s3_bucket.name_prefix for Data Exfil Prevention compatibility. Users with dotted module-managed bucket names must rename before upgrading ([#43](https://github.com/terraform-mongodbatlas-modules/terraform-mongodbatlas-atlas-aws/pull/43))
* variable/privatelink_byo_endpoint: Changes type from `map(string)` to `map(object({ region, supported_remote_regions }))` to support cross-region BYOE PrivateLink ([#46](https://github.com/terraform-mongodbatlas-modules/terraform-mongodbatlas-atlas-aws/pull/46))
* variable/privatelink_byo_endpoint: Renames `privatelink_byoe_regions` to `privatelink_byo_endpoint` to represent the resource managed ([#47](https://github.com/terraform-mongodbatlas-modules/terraform-mongodbatlas-atlas-aws/pull/47))
* variable/privatelink_byo_service: Renames `privatelink_byoe` to `privatelink_byo_service` to represent the resource managed ([#47](https://github.com/terraform-mongodbatlas-modules/terraform-mongodbatlas-atlas-aws/pull/47))
* variable/timeouts: Adds configurable timeout defaults (30m) for all Atlas and AWS resources. Existing deployments will see plan diffs from new timeout blocks. Set `timeouts = null` for zero-diff upgrade, see [v0.3.0 Upgrade Guide](https://github.com/terraform-mongodbatlas-modules/terraform-mongodbatlas-atlas-aws/blob/main/docs/v0.3.0-upgrade-guide.md) ([#37](https://github.com/terraform-mongodbatlas-modules/terraform-mongodbatlas-atlas-aws/pull/37))

NOTES:

* provider/mongodbatlas: Requires minimum version 2.11.0 for `service_region` field for cross-region PrivateLink support ([#46](https://github.com/terraform-mongodbatlas-modules/terraform-mongodbatlas-atlas-aws/pull/46))
* provider/mongodbatlas: Requires minimum version 2.8.0 for mongodbatlas_log_integration resource support ([#34](https://github.com/terraform-mongodbatlas-modules/terraform-mongodbatlas-atlas-aws/pull/34))

ENHANCEMENTS:

* module: Adds IAM least-privilege permissions reference at docs/iam-permissions.md documenting CPA role permissions, Terraform caller permissions, and BYO role requirements per feature ([#38](https://github.com/terraform-mongodbatlas-modules/terraform-mongodbatlas-atlas-aws/pull/38))
* module: Derives `iam_role_name` from `existing.iam_role_arn` through regex when using BYO Cloud Provider Access, fixing null `iam_role_name` when `create = false` with shared role ([#39](https://github.com/terraform-mongodbatlas-modules/terraform-mongodbatlas-atlas-aws/pull/39))
* output/backup_export: Adds `expiration_days` to `backup_export` output (365 default, 0 = disabled, null = BYO bucket) ([#38](https://github.com/terraform-mongodbatlas-modules/terraform-mongodbatlas-atlas-aws/pull/38))
* output/log_integration: Adds `expiration_days` to `log_integration` output (90 default, 0 = disabled, null = BYO bucket) ([#38](https://github.com/terraform-mongodbatlas-modules/terraform-mongodbatlas-atlas-aws/pull/38))
* submodule/log_integration: Adds log integration submodule for exporting Atlas logs to S3 via mongodbatlas_log_integration ([#34](https://github.com/terraform-mongodbatlas-modules/terraform-mongodbatlas-atlas-aws/pull/34))
* variable/cloud_provider_access: Adds `skip_iam_policy_attachments` flag (default false) to skip all `aws_iam_role_policy` resources when using a BYO role. Enables read-only AWS access when IAM policies are pre-attached to the role externally ([#39](https://github.com/terraform-mongodbatlas-modules/terraform-mongodbatlas-atlas-aws/pull/39))
* variable/log_integration: Adds log_integration variable with S3 bucket management, per-integration BYO bucket overrides, KMS encryption, and dedicated IAM role support ([#34](https://github.com/terraform-mongodbatlas-modules/terraform-mongodbatlas-atlas-aws/pull/34))
* variable/privatelink_byo_service: Adds optional `region` and `service_region_key` fields for cross-region BYOE. A VPC endpoint in one AWS region can reference an Atlas endpoint service in another via `service_region_key` ([#46](https://github.com/terraform-mongodbatlas-modules/terraform-mongodbatlas-atlas-aws/pull/46))
* variable/privatelink_endpoints: Adds optional `service_region` field for cross-region PrivateLink. A VPC endpoint in one AWS region can connect to an Atlas endpoint in another via AWS cross-region PrivateLink. Cross-region entries reuse the primary Atlas endpoint and only create the AWS-side VPC endpoint and Atlas endpoint service ([#44](https://github.com/terraform-mongodbatlas-modules/terraform-mongodbatlas-atlas-aws/pull/44))

## 0.2.0 (February 25, 2026)

BREAKING CHANGES:

* submodule/encryption: Exposes `enabled_for_search_nodes` with secure default (`true`) to control BYOK encryption for dedicated search nodes. Existing deployments with `encryption.enabled = true` and dedicated search nodes will see `enabled_for_search_nodes` flip from `false` to `true` on upgrade. This triggers search node reprovisioning and index rebuild. Set `enabled_for_search_nodes = false` explicitly to preserve current behavior ([#26](https://github.com/terraform-mongodbatlas-modules/terraform-mongodbatlas-aws/pull/26))

## 0.1.1 (February 11, 2026)

BUG FIXES:

* output/export_bucket_id: Uses correct `export_bucket_id` instead of internal `id` field ([#23](https://github.com/terraform-mongodbatlas-modules/terraform-mongodbatlas-aws/pull/23))

## 0.1.0 (February 04, 2026)
* Initial release
