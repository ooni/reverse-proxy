# Local variable definitions
locals {
  stage = "dev"
  name  = "oonidevops-${local.stage}"

  dns_zone_ooni_nu = "Z091407123AEJO90Z3H6D" # dev.ooni.nu hosted zone
  dns_zone_ooni_io = "Z055356431RGCLK3JXZDL" # dev.ooni.io hosted zone

  tags = {
    Name       = local.name
    Stage      = local.stage
    Repository = "https://github.com/ooni/devops"
  }
}

## AWS Setup

provider "aws" {
  profile = "oonidevops_user"
  region  = var.aws_region
  assume_role {
    role_arn = "arn:aws:iam::905418398257:role/oonidevops"
  }
}

data "aws_availability_zones" "available" {}

### !!! IMPORTANT !!!
# The first time you run terraform for a new stage you have to setup the
# required roles in AWS.
# This is a one time operation.
# Follow these steps:
# 1. go into the AWS console for the root user and create an access key for it
# 2. place the root access key and secret inside of ~/.aws/credentials under the
#    profile "oonidevops_root".
# 3. Comment out the provider line for profile "oonidevops_user" and uncomment
#    the "oonidevops_root" provider line.
# 4. Run terraform apply, ideally with everything else in this module commented
#    out. The admin_iam_roles module will create the IAM role for oonidevops_user and
#    grant assume_role permission to the user account which is connected to the
#    main oonidevops account.
#    TODO(art): maybe it's cleaner to have this all be a separate environment
# 5. Login to the root account and delete the access key for the root user!
# 6. Switch the commented lines around and edit the assume_role line to include
#    the newly created role_arn.
#
# Once this is done, new accounts can be added/removed by just adding their arn
# to the authorized accounts below.

#provider "aws" {
#  profile = "oonidevops_root"
#  region  = var.aws_region
#}

module "adm_iam_roles" {
  source = "../../modules/adm_iam_roles"

  authorized_accounts = [
    "arn:aws:iam::082866812839:user/art"
  ]
}

# You cannot create a new backend by simply defining this and then
# immediately proceeding to "terraform apply". The S3 backend must
# be bootstrapped according to the simple yet essential procedure in
# https://github.com/cloudposse/terraform-aws-tfstate-backend#usage
module "terraform_state_backend" {
  source     = "cloudposse/tfstate-backend/aws"
  version    = "1.4.0"
  namespace  = "oonidevops"
  stage      = local.stage
  name       = "terraform"
  attributes = ["state"]

  # Comment this out on first start
  #terraform_backend_config_file_path = "."
  terraform_backend_config_file_name = "backend.tf"
  force_destroy                      = false
  depends_on                         = [module.adm_iam_roles]
}

## Ansible inventory

module "ansible_inventory" {
  source = "../../modules/ansible_inventory"

  server_groups = {
    ## "all" has special meaning and is reserved
    "mygroup" = []
  }
}

module "network" {
  source = "../../modules/network"

  az_count            = var.az_count
  vpc_main_cidr_block = "10.0.0.0/16"
  tags = merge(
    local.tags,
    { Name = "ooni-main-vpc" }
  )

  aws_availability_zones_available = data.aws_availability_zones.available

  depends_on = [module.adm_iam_roles]
}


### OONI Modules

#### OONI Tier0 PostgreSQL Instance

module "oonipg" {
  source = "../../modules/postgresql"

  name                     = "ooni-tier0-postgres"
  aws_region               = var.aws_region
  vpc_id                   = module.network.vpc_id
  subnet_ids               = module.network.vpc_subnet[*].id
  db_instance_class        = "db.t3.micro"
  db_storage_type          = "standard"
  db_allocated_storage     = "5"
  db_max_allocated_storage = null
  tags = merge(
    local.tags,
    { Name = "ooni-tier0-postgres" }
  )

  depends_on = [module.adm_iam_roles]
}

moved {
  from = module.postgresql
  to   = module.oonipg
}

### OONI Tier0 Backend Proxy

module "ooni_backendproxy" {
  source = "../../modules/ooni_backendproxy"

  vpc_id     = module.network.vpc_id
  subnet_ids = module.network.vpc_subnet[*].id

  key_name      = module.adm_iam_roles.oonidevops_key_name
  instance_type = "t2.micro"

  tags = merge(
    local.tags,
    { Name = "ooni-tier0-backendproxy" }
  )
}

### OONI Tier0 API Frontend

module "ooniapi_frontend" {
  source = "../../modules/ooniapi_frontend"


  vpc_id     = module.network.vpc_id
  subnet_ids = module.network.vpc_subnet[*].id

  oonibackend_proxy_target_group_arn = module.ooni_backendproxy.alb_target_group_id
  stage                              = local.stage
  dns_zone_ooni_io                   = local.dns_zone_ooni_io

  tags = merge(
    local.tags,
    { Name = "ooni-tier0-api-frontend" }
  )
}

# ## ECS

# resource "aws_ecs_cluster" "main" {
#   name = local.ecs_cluster_name
#   tags = local.tags
# }

# module "ooni_dataapi" {
#   source = "../../modules/ooni_dataapi"

#   aws_access_key_id     = var.aws_access_key_id
#   aws_secret_access_key = var.aws_secret_access_key
#   aws_region            = var.aws_region
#   tags                  = local.tags
#   ecs_cluster_name      = local.ecs_cluster_name
#   ecs_cluster_id        = aws_ecs_cluster.main.id
#   vpc_id                = module.network.vpc_id
#   subnet_ids            = module.network.vpc_subnet[*].id
#   certificate_arn       = aws_acm_certificate_validation.oonidataapi.certificate_arn
# }

# ### OONI API ALB


# resource "aws_lb_listener_rule" "rule" {
#   listener_arn = aws_lb_listener.ooniapi_listener_https.arn
#   priority     = 100

#   action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.tg.arn
#   }

#   condition {
#     path_pattern {
#       values = ["/api/v1/*"]
#     }
#   }
# }

# Route53

resource "aws_route53_record" "postgres_dns" {
  zone_id = local.dns_zone_ooni_nu
  name    = "postgres.${local.stage}.ooni.nu"
  type    = "CNAME"
  ttl     = "300"
  records = [module.oonipg.pg_address]
}

# resource "aws_route53_record" "alb_dns" {
#   zone_id = local.dns_zone_ooni_io
#   name    = "dataapi.${local.stage}.ooni.io"
#   type    = "A"

#   alias {
#     name                   = module.ooni_dataapi.alb_dns_name
#     zone_id                = module.ooni_dataapi.alb_zone_id
#     evaluate_target_health = true
#   }
# }



# # ACM TLS

# resource "aws_acm_certificate" "oonidataapi" {
#   domain_name       = "dataapi.prod.ooni.io"
#   validation_method = "DNS"

#   tags = local.tags

#   lifecycle {
#     create_before_destroy = true
#   }
# }

# resource "aws_route53_record" "oonidataapi_cert_validation" {
#   for_each = {
#     for dvo in aws_acm_certificate.oonidataapi.domain_validation_options : dvo.domain_name => {
#       name   = dvo.resource_record_name
#       record = dvo.resource_record_value
#       type   = dvo.resource_record_type
#     }
#   }

#   allow_overwrite = true
#   name            = each.value.name
#   records         = [each.value.record]
#   ttl             = 60
#   type            = each.value.type
#   zone_id         = local.dns_zone_ooni_io
# }

# resource "aws_acm_certificate_validation" "oonidataapi" {
#   certificate_arn         = aws_acm_certificate.oonidataapi.arn
#   validation_record_fqdns = [for record in aws_route53_record.oonidataapi_cert_validation : record.fqdn]
#   depends_on = [
#     aws_route53_record.ooniapi_alb_dns
#   ]
# }


# ## CloudWatch Logs

# resource "aws_cloudwatch_log_group" "ecs" {
#   name = "tf-ecs-group/ecs-agent"
# }
