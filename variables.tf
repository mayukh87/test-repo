variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "brightline-mdf"
}

variable "data_lake_bucket_name" {
  description = "Name of the S3 data lake bucket"
  type        = string
  default     = "dev-brightline-mdf-data-lake"
}