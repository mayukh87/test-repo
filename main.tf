terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Data source for Adobe Analytics IAM policy document
data "aws_iam_policy_document" "adobe_analytics_policy" {
  statement {
    effect = "Allow"
    actions = [
      "s3:ListBucket"
    ]
    resources = [
      "arn:aws:s3:::${var.data_lake_bucket_name}"
    ]
    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["adobe_analytics/*"]
    }
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:ReplicateObject",
      "s3:PutObjectTagging",
      "s3:PutObjectAcl",
      "s3:PutObject",
      "s3:GetObjectTagging",
      "s3:GetObjectAcl",
      "s3:GetObject",
      "s3:DeleteObjectVersion",
      "s3:DeleteObjectTagging",
      "s3:DeleteObject"
    ]
    resources = [
      "arn:aws:s3:::${var.data_lake_bucket_name}/adobe_analytics/*"
    ]
  }
}

# IAM policy for Adobe Analytics
resource "aws_iam_policy" "adobe_analytics_policy" {
  name        = "${var.environment}-${var.project_name}-aep-user-policy"
  description = "Policy for Adobe Analytics data access"
  policy      = data.aws_iam_policy_document.adobe_analytics_policy.json
}

# IAM user for Adobe Analytics
resource "aws_iam_user" "aep_user" {
  name = "${var.environment}-${var.project_name}-aep-user"
  path = "/"
}

# Attach policy to user
resource "aws_iam_user_policy_attachment" "aep_user_policy_attachment" {
  user       = aws_iam_user.aep_user.name
  policy_arn = aws_iam_policy.adobe_analytics_policy.arn
}

# Access key for the user
resource "aws_iam_access_key" "aep_user_access_key" {
  user = aws_iam_user.aep_user.name
}