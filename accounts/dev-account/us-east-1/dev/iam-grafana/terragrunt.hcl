terraform {
  # Using the official AWS IAM module
  source = "tfr:///terraform-aws-modules/iam/aws//modules/iam-user?version=5.34.0"
}

include "root" {
  path = find_in_parent_folders()
}

inputs = {
  name                          = "grafana-cloudwatch-reader"
  create_iam_access_key         = true
  create_iam_user_login_profile = false
  force_destroy                 = true

  # This is the principle of least privilege. Grafana can ONLY read metrics, nothing else.
  policy_arns = [
    "arn:aws:iam::aws:policy/CloudWatchReadOnlyAccess"
  ]
}