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

resource "aws_secretsmanager_secret" "aws_secret_access_key" {
  name = "oonidevops/ooniapi_user/aws_secret_access_key"

  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "aws_secret_access_key" {
  secret_id     = aws_secretsmanager_secret.aws_secret_access_key.id
  secret_string = aws_iam_access_key.ooniapi.secret
}

resource "aws_secretsmanager_secret" "aws_access_key_id" {
  name = "oonidevops/ooniapi_user/aws_access_key_id"

  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "aws_access_key_id" {
  secret_id     = aws_secretsmanager_secret.aws_access_key_id.id
  secret_string = aws_iam_access_key.ooniapi.id
}


resource "aws_ses_email_identity" "ooniapi" {
  email = var.email_address
}
