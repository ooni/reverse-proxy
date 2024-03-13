resource "aws_iam_user" "oonidevops_github" {
  name = "oonidevops-github"
  path = "/"

  tags = var.tags
}

resource "aws_iam_policy" "oonidevops_github" {
  name        = "oonidevops-github-policy"
  description = "A test policy"
  policy      = file("${path.module}/templates/oonidevops_github_policy.json")
}

resource "aws_iam_user_policy_attachment" "oonidevops_github" {
  user       = aws_iam_user.oonidevops_github.name
  policy_arn = aws_iam_policy.oonidevops_github.arn
}

resource "aws_iam_access_key" "oonidevops_github" {
  user = aws_iam_user.oonidevops_github.name
}

resource "aws_secretsmanager_secret" "oonidevops_github" {
  name = "oonidevops/github_user/access_key_json"

  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "oonidevops_github" {
  secret_id = aws_secretsmanager_secret.oonidevops_github.id
  secret_string = jsonencode({
    "AccessKey"       = aws_iam_access_key.oonidevops_github.id,
    "SecretAccessKey" = aws_iam_access_key.oonidevops_github.secret
  })
}
