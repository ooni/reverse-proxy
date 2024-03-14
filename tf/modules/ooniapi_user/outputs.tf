output "arn" {
  value = aws_iam_user.ooniapi.arn
}

output "aws_access_key_id_arn" {
  value = aws_secretsmanager_secret.aws_access_key_id.id
}

output "aws_secret_access_key_arn" {
  value = aws_secretsmanager_secret.aws_secret_access_key.id
}

output "email_address" {
  value = aws_ses_email_identity.ooniapi.email
}
