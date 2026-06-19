include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "tfr:///terraform-aws-modules/iam/aws//modules/iam-assumable-role?version=5.33.0"
}

inputs = {
  trusted_role_services = [
    "ec2.amazonaws.com"
  ]

  create_role           = true
  role_name             = "greenhouse-ec2-ecr-reader-role"
  role_requires_mfa     = false
  custom_role_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    "arn:aws:iam::aws:policy/AmazonS3FullAccess"
  ]

  create_instance_profile = true
}