# ── S3 State Bucket ──────────────────────────────────────────────────────────
resource "aws_s3_bucket" "tfstate" {
  bucket = "us2-waf-tfstate"

  tags = merge(local.common_tags, {
    Name             = "us2-waf-tfstate"
    CostTagProject   = "us2-waf-tfstate"
    CostResourceType = "s3bucket"
  })
}

resource "aws_s3_bucket_versioning" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  rule {
    apply_server_side_encryption_by_default { sse_algorithm = "AES256" }
  }
}

resource "aws_s3_bucket_public_access_block" "tfstate" {
  bucket                  = aws_s3_bucket.tfstate.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ── GitHub OIDC Provider ─────────────────────────────────────────────────────
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]

  tags = merge(local.common_tags, {
    Name             = "github-actions-oidc"
    CostTagProject   = "github-actions-oidc"
    CostResourceType = "oidcprovider"
  })
}

# ── IAM Role ─────────────────────────────────────────────────────────────────
resource "aws_iam_role" "github_actions_waf" {
  name = "github-actions-waf-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = aws_iam_openid_connect_provider.github.arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        }
        StringLike = {
          "token.actions.githubusercontent.com:sub" = [
            "repo:gs-ykalvakuntla/techops-waf:ref:refs/heads/main",
            "repo:gs-ykalvakuntla/techops-waf:pull_request"
          ]
        }
      }
    }]
  })

  tags = merge(local.common_tags, {
    Name             = "github-actions-waf-role"
    CostTagProject   = "github-actions-waf-role"
    CostResourceType = "iamrole"
  })
}

resource "aws_iam_role_policy" "waf_permissions" {
  name = "waf-terraform-permissions"
  role = aws_iam_role.github_actions_waf.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "WAFFullAccess"
        Effect   = "Allow"
        Action   = ["wafv2:*"]
        Resource = "*"
      },
      {
        Sid    = "TFStateAccess"
        Effect = "Allow"
        Action = [
          "s3:GetObject", "s3:PutObject", "s3:DeleteObject",
          "s3:ListBucket", "s3:GetBucketVersioning"
        ]
        Resource = [
          "arn:aws:s3:::us2-waf-tfstate",
          "arn:aws:s3:::us2-waf-tfstate/*"
        ]
      }
    ]
  })
}
