
resource "aws_iam_role" "this" {
  count = local.needs_shared_cloud_provider_access && !local.has_existing_aws_iam_role ? 1 : 0

  lifecycle {
    precondition {
      condition     = var.aws_iam_role_name != null
      error_message = "aws_iam_role_name must be set when existing_aws_iam_role_arn is null"
    }
  }

  name = var.aws_iam_role_name

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "${mongodbatlas_cloud_provider_access_setup.this[0].aws_config[0].atlas_aws_account_arn}"
      },
      "Action": "sts:AssumeRole",
      "Condition": {
        "StringEquals": {
          "sts:ExternalId": "${mongodbatlas_cloud_provider_access_setup.this[0].aws_config[0].atlas_assumed_role_external_id}"
        }
      }
    }
  ]
}
EOF
}
