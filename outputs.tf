output "aep_user" {
  description = "Adobe Analytics IAM user details"
  value = {
    user_arn    = aws_iam_user.aep_user.arn
    policy_arn  = aws_iam_policy.adobe_analytics_policy.arn
    access_key  = aws_iam_access_key.aep_user_access_key.id
    secret_key  = aws_iam_access_key.aep_user_access_key.secret
  }
  sensitive = true
}