terraform {
  required_version = ">= 1.0.0"

  backend "s3" {
    region  = "eu-central-1"
    bucket  = "oonidevops-dev-terraform-state"
    key     = "terraform.tfstate"
    profile = ""
    encrypt = "true"

    dynamodb_table = "oonidevops-dev-terraform-state-lock"
  }
}
