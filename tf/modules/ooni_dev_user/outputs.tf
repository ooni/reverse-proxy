output "ooni_dev_user_arn" {
  value = aws_iam_user.ooni_dev_user.arn
}

output "ooni_dev_user_access_key" {
    value = aws_iam_access_key.ooni_dev_user.encrypted_secret
}

output "secretsmanager_id" {
    value = aws_secretsmanager_secret.ooni_dev_user_secrets.id
}
