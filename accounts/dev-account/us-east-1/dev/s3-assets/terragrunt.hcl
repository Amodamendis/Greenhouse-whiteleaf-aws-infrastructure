include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "tfr:///terraform-aws-modules/s3-bucket/aws//?version=5.14.0"
}

inputs = {
  bucket = "greenhouse-static-assets-${get_aws_account_id()}"

  # Allow public access policies
  control_object_ownership = true
  object_ownership         = "BucketOwnerPreferred"
  
  # Remove all strict public blocks
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false

  # Attach a policy that makes every file inside readable by the internet
  attach_public_policy = true
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicReadGetObject",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::greenhouse-static-assets-${get_aws_account_id()}/*"
    }
  ]
}
POLICY

  tags = {
    Tier = "Storage"
  }
}