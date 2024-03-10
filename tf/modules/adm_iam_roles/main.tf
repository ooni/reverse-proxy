data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "AWS"
      identifiers = var.authorized_accounts
    }
  }
}

resource "aws_iam_policy" "oonidevops" {
  name        = "OONIDevopsPolicy"
  path        = "/"
  description = "Policy used by the oonidevops role to perform all terraform and CI/CD related tasks."

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:*",
        "ecs:*",
        "ecr:*",
        "ecr-public:*",
        "rds:*",
        "vpc:*",
        "appmesh:*",
        "autoscaling:*",
        "application-autoscaling:*",
        "elasticloadbalancing:*",
        "acm:*",
        "cloudformation:*",
        "cloudtrail:*",
        "cloudwatch:*",
        "codebuild:*",
        "codedeploy:*",
        "codepipeline:*",
        "codestar-notifications:*",
        "route53:*",
        "servicediscovery:*",
        "s3:*",
        "ssm:*",
        "logs:*",
        "iam:*",
        "dynamodb:*",
        "states:*",
        "organizations:*",
        "secretsmanager:*"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role" "oonidevops" {
  name                = "oonidevops"
  assume_role_policy  = data.aws_iam_policy_document.assume_role.json
  managed_policy_arns = [aws_iam_policy.oonidevops.arn]
}
