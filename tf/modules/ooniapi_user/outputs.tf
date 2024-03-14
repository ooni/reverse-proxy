output "ooniapi_user_arn" {
  value = aws_iam_user.ooniapi.arn
}

output "ooniapi_user_secrets_id" {
  value = aws_secretsmanager_secret.ooniapi.id
}
