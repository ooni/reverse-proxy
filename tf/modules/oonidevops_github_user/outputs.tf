output "oonidevops_github_user_arn" {
  value = aws_iam_user.oonidevops_github.arn
}

output "oonidevops_github_user_secrets_id" {
  value = aws_secretsmanager_secret.oonidevops_github.id
}
