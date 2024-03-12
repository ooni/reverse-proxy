# Store terraform state in s3
terraform {
  backend "s3" {
    region  = "eu-central-1"
    bucket  = "ooni-production-terraform-state"
    key     = "terraform.tfstate"
    profile = ""
    encrypt = "true"

    dynamodb_table = "ooni-production-terraform-state-lock"
  }
}

## AWS Setup

provider "aws" {
  region     = var.aws_region
}

# You cannot create a new backend by simply defining this and then
# immediately proceeding to "terraform apply". The S3 backend must
# be bootstrapped according to the simple yet essential procedure in
# https://github.com/cloudposse/terraform-aws-tfstate-backend#usage
module "terraform_state_backend" {
  source     = "cloudposse/tfstate-backend/aws"
  version    = "1.4.0"
  namespace  = "ooni"
  stage      = "production"
  name       = "terraform"
  attributes = ["state"]

  #terraform_backend_config_file_path = "."
  terraform_backend_config_file_name = "backend.tf"
  force_destroy                      = false
}

### Everything in here has been destroyed
