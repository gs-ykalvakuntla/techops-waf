output "github_actions_role_arn" {
  description = "Add this as US2_WAF_AWS_ROLE_ARN in GitHub Secrets"
  value       = aws_iam_role.github_actions_waf.arn
}

output "state_bucket_name" {
  description = "S3 bucket used for Terraform state in US2"
  value       = aws_s3_bucket.tfstate.bucket
}
