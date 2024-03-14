resource "aws_iam_user" "ooniapi" {
  name = "oonidevops-ooniapi"
}

resource "aws_iam_user_policy" "ooniapi" {
  name = "oonidevops-ooniapi-policy"
  user = aws_iam_user.ooniapi.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ses:SendEmail",
          "ses:SendRawEmail",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_access_key" "ooniapi" {
  user = aws_iam_user.ooniapi.name
}

resource "aws_secretsmanager_secret" "ooniapi" {
  name = "oonidevops/ooniapi_user/access_key_json"

  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "ooniapi" {
  secret_id = aws_secretsmanager_secret.ooniapi.id
  secret_string = jsonencode({
    "AccessKeyId"     = aws_iam_access_key.ooniapi.id,
    "SecretAccessKey" = aws_iam_access_key.ooniapi.secret
  })
}

resource "aws_ses_email_identity" "ooniapi" {
  email = var.email_address
}
