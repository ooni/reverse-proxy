# Terraform

Terraform is used for managing the OONI infrastructure as code.

## Quickstart

1. Install [terraform](https://developer.hashicorp.com/terraform/install)
2. Setup AWS credentials by making your ~/.aws/credentials look like this:

```
[oonidevops_user]
aws_access_key_id = XXXX
aws_secret_access_key = YYYY
role_arn = arn:aws:iam::OONI_ORG_ID:role/oonidevops
```

Where you replace OONI_ORG_ID with the ID of the ORG you are deploying to (dev,
test or prod).

3. Run `terrafrom plan` to check the plan
4. Run `terraform apply` to apply the plan

Once you have applied a plan the changes to the terraform config should be
pushed to the `main` branch immediately so that we minimize the change of other
people applying stale configurations.

### Notes

https://www.terraform-best-practices.com/naming

Sometimes it's useful to specify a target like this:

```
terraform apply -target=module.ooniapi_frontend.aws_lb_listener_rule.oonidataapi_rule
```
