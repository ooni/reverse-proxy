# Local variable definitions
locals {
  environment = "prod"
  name        = "oonidevops-${local.environment}"

  dns_zone_ooni_nu = "Z05790852M4U3UIVKYQ2N" # prod.ooni.nu hosted zone
  dns_zone_ooni_io = "Z04499311AMTU66QF54HY" # prod.ooni.io hosted zone

  dns_root_zone_ooni_org = "Z0902716K7OR8NEDGPCF"  # ooni.org hosted zone
  dns_root_zone_ooni_io  = "Z03735033JOHK3ID0YPTW" # ooni.io hosted zone
  dns_root_zone_ooni_nu  = "Z0562931LCY2YTJ8MEJ4"  # ooni.nu hosted zone


  ooni_main_org_id = "082866812839" # account ID for the admin@openobservatory.org account
  ooni_prod_org_id = "471112720364" # account ID for the admin+prod@ooni.org account

  tags = {
    Name        = local.name
    Environment = local.environment
    Repository  = "https://github.com/ooni/devops"
  }
}

## AWS Setup

provider "aws" {
  profile = "oonidevops_user_prod"
  region  = var.aws_region

  # You will have to setup your own credentials in ~/.aws/credentials like this:
  #
  # [oonidevops_user]
  # aws_access_key_id = YYYY
  # aws_secret_access_key = ZZZ
  # [oonidevops_user_dev]
  # role_arn = arn:aws:iam::905418398257:role/oonidevops
  # source_profile = oonidevops_user
  # [oonidevops_user_prod]
  # role_arn = arn:aws:iam::471112720364:role/oonidevops
  # source_profile = oonidevops_user
}

data "aws_availability_zones" "available" {}

data "aws_secretsmanager_secret" "do_token" {
  name = "oonidevops/digitalocean_access_token"
}

data "aws_secretsmanager_secret_version" "do_token_version" {
  secret_id = data.aws_secretsmanager_secret.do_token.id
}

provider "digitalocean" {
  token = data.aws_secretsmanager_secret_version.do_token_version.secret_string
}

### !!! IMPORTANT !!!
# The first time you run terraform for a new environment you have to setup the
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
    "arn:aws:iam::${local.ooni_main_org_id}:user/art",
    "arn:aws:iam::${local.ooni_main_org_id}:user/luis",
    "arn:aws:iam::${local.ooni_main_org_id}:user/mehul",
    "arn:aws:iam::${local.ooni_main_org_id}:user/tony"
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
  stage      = local.environment
  name       = "terraform"
  attributes = ["state"]

  # Comment this out on first start
  # terraform_backend_config_file_path = "."
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

  environment = local.environment
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

  enable_codesign_network = true

  depends_on = [module.adm_iam_roles]
}


## OONI Modules

module "oonidevops_github_user" {
  source = "../../modules/oonidevops_github_user"

  tags = local.tags
}


### OONI Tier0 PostgreSQL Instance

module "oonipg" {
  source = "../../modules/postgresql"

  name                     = "ooni-tier0-postgres"
  aws_region               = var.aws_region
  vpc_id                   = module.network.vpc_id
  subnet_ids               = module.network.vpc_subnet_public[*].id
  db_instance_class        = "db.t3.micro"
  db_storage_type          = "gp3"
  db_allocated_storage     = "50"
  db_max_allocated_storage = null
  tags = merge(
    local.tags,
    { Name = "ooni-tier0-postgres" }
  )

  depends_on = [module.adm_iam_roles]
}

resource "aws_route53_record" "postgres_dns" {
  zone_id = local.dns_zone_ooni_nu
  name    = "postgres.${local.environment}.ooni.nu"
  type    = "CNAME"
  ttl     = "300"
  records = [module.oonipg.pg_address]
}

## OONI Services

module "ooniapi_user" {
  source = "../../modules/ooniapi_user"

  email_address = "admin@ooni.org"
  tags          = local.tags
}


### Configuration common to all services

resource "random_password" "jwt_secret" {
  length  = 32
  special = false
}

resource "aws_secretsmanager_secret" "jwt_secret" {
  name = "oonidevops/ooni_services/jwt_secret"
  tags = local.tags
}

resource "aws_secretsmanager_secret_version" "jwt_secret" {
  secret_id     = aws_secretsmanager_secret.jwt_secret.id
  secret_string = random_password.jwt_secret.result
}

resource "random_password" "prometheus_metrics_password" {
  length  = 32
  special = false
}

resource "aws_secretsmanager_secret" "prometheus_metrics_password" {
  name = "oonidevops/ooni_services/prometheus_metrics_password"
  tags = local.tags
}

resource "aws_secretsmanager_secret_version" "prometheus_metrics_password" {
  secret_id     = aws_secretsmanager_secret.prometheus_metrics_password.id
  secret_string = random_password.prometheus_metrics_password.result
}

data "aws_secretsmanager_secret_version" "prometheus_metrics_password" {
  secret_id = aws_secretsmanager_secret.prometheus_metrics_password.id
}

resource "aws_secretsmanager_secret" "oonipg_url" {
  name = "oonidevops/ooni-tier0-postgres/postgresql_url"
  tags = local.tags
}

resource "aws_secretsmanager_secret_version" "oonipg_url" {
  secret_id = aws_secretsmanager_secret.oonipg_url.id
  secret_string = format("postgresql://%s:%s@%s/%s",
    module.oonipg.pg_username,
    module.oonipg.pg_password,
    module.oonipg.pg_endpoint,
    module.oonipg.pg_db_name
  )
}

resource "random_id" "artifact_id" {
  byte_length = 4
}

resource "aws_s3_bucket" "ooniapi_codepipeline_bucket" {
  bucket = "codepipeline-ooniapi-${var.aws_region}-${random_id.artifact_id.hex}"
}

resource "aws_s3_bucket" "oonith_codepipeline_bucket" {
  bucket = "codepipeline-oonith-${var.aws_region}-${random_id.artifact_id.hex}"
}

data "aws_secretsmanager_secret_version" "deploy_key" {
  secret_id  = module.adm_iam_roles.oonidevops_deploy_key_arn
  depends_on = [module.adm_iam_roles]
}

# The aws_codestarconnections_connection resource is created in the state
# PENDING. Authentication with the connection provider must be completed in the
# AWS Console.
# See: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codestarconnections_connection 
resource "aws_codestarconnections_connection" "oonidevops" {
  name          = "ooniapi"
  provider_type = "GitHub"

  depends_on = [module.adm_iam_roles]
}

moved {
  from = aws_codestarconnections_connection.ooniapi
  to   = aws_codestarconnections_connection.oonidevops
}

### OONI Tier0 Backend Proxy

module "ooni_th_droplet" {
  source = "../../modules/ooni_th_droplet"

  stage             = local.environment
  instance_location = "fra1"
  instance_size     = "s-1vcpu-1gb"
  droplet_count     = 3
  deployer_key      = jsondecode(data.aws_secretsmanager_secret_version.deploy_key.secret_string)["public_key"]
  metrics_password  = data.aws_secretsmanager_secret_version.prometheus_metrics_password.secret_string
  ssh_keys = [
    "3d:81:99:17:b5:d1:20:a5:fe:2b:14:96:67:93:d6:34",
    "f6:4b:8b:e2:0e:d2:97:c5:45:5c:07:a6:fe:54:60:0e"
  ]

  dns_zone_ooni_io = local.dns_zone_ooni_io
}

module "ooni_backendproxy" {
  source = "../../modules/ooni_backendproxy"

  stage = local.environment

  vpc_id              = module.network.vpc_id
  subnet_id           = module.network.vpc_subnet_public[0].id
  private_subnet_cidr = module.network.vpc_subnet_private[*].cidr_block
  dns_zone_ooni_io    = local.dns_zone_ooni_io

  key_name      = module.adm_iam_roles.oonidevops_key_name
  instance_type = "t3.micro"

  backend_url        = "https://backend-fsn.ooni.org/"
  wcth_addresses     = module.ooni_th_droplet.droplet_ipv4_address
  wcth_domain_suffix = "th.ooni.org"
  clickhouse_url     = "backend-fsn.ooni.org"
  clickhouse_port    = "9000"

  tags = merge(
    local.tags,
    { Name = "ooni-tier0-backendproxy" }
  )
}

module "ooniapi_reverseproxy_deployer" {
  source = "../../modules/ooniapi_service_deployer"

  service_name            = "reverseproxy"
  repo                    = "ooni/backend"
  branch_name             = "master"
  buildspec_path          = "ooniapi/services/reverseproxy/buildspec.yml"
  codestar_connection_arn = aws_codestarconnections_connection.oonidevops.arn

  codepipeline_bucket = aws_s3_bucket.ooniapi_codepipeline_bucket.bucket

  ecs_service_name = module.ooniapi_reverseproxy.ecs_service_name
  ecs_cluster_name = module.ooniapi_cluster.cluster_name
}

module "ooniapi_reverseproxy" {
  source = "../../modules/ooniapi_service"

  task_memory = 64

  # First run should be set on first run to bootstrap the task definition
  # first_run = true

  vpc_id             = module.network.vpc_id
  public_subnet_ids  = module.network.vpc_subnet_public[*].id
  private_subnet_ids = module.network.vpc_subnet_private[*].id

  service_name             = "reverseproxy"
  default_docker_image_url = "ooni/api-reverseproxy:latest"
  stage                    = local.environment
  dns_zone_ooni_io         = local.dns_zone_ooni_io
  key_name                 = module.adm_iam_roles.oonidevops_key_name
  ecs_cluster_id           = module.ooniapi_cluster.cluster_id

  task_secrets = {
    PROMETHEUS_METRICS_PASSWORD = aws_secretsmanager_secret_version.prometheus_metrics_password.arn
  }

  task_environment = {
    TARGET_URL               = "https://backend-fsn.ooni.org/"
  }

  ooniapi_service_security_groups = [
    module.ooniapi_cluster.web_security_group_id
  ]

  tags = merge(
    local.tags,
    { Name = "ooni-tier0-reverseproxy" }
  )
}

### OONI Services Clusters

module "ooniapi_cluster" {
  source = "../../modules/ecs_cluster"

  name       = "ooniapi-ecs-cluster"
  key_name   = module.adm_iam_roles.oonidevops_key_name
  vpc_id     = module.network.vpc_id
  subnet_ids = module.network.vpc_subnet_public[*].id

  # You need be careful how these are tweaked.
  asg_min     = 2
  asg_max     = 8
  asg_desired = 2

  instance_type = "t3a.medium"

  tags = merge(
    local.tags,
    { Name = "ooni-tier0-api-ecs-cluster" }
  )
}

#### OONI Tier0

#### OONI Probe service

module "ooniapi_ooniprobe_deployer" {
  source = "../../modules/ooniapi_service_deployer"

  service_name            = "ooniprobe"
  repo                    = "ooni/backend"
  branch_name             = "master"
  buildspec_path          = "ooniapi/services/ooniprobe/buildspec.yml"
  codestar_connection_arn = aws_codestarconnections_connection.oonidevops.arn

  codepipeline_bucket = aws_s3_bucket.ooniapi_codepipeline_bucket.bucket

  ecs_service_name = module.ooniapi_ooniprobe.ecs_service_name
  ecs_cluster_name = module.ooniapi_cluster.cluster_name
}

module "ooniapi_ooniprobe" {
  source = "../../modules/ooniapi_service"

  # First run should be set on first run to bootstrap the task definition
  #first_run = true

  vpc_id             = module.network.vpc_id
  private_subnet_ids = module.network.vpc_subnet_private[*].id
  public_subnet_ids  = module.network.vpc_subnet_public[*].id

  service_name             = "ooniprobe"
  default_docker_image_url = "ooni/api-ooniprobe:latest"
  stage                    = local.environment
  dns_zone_ooni_io         = local.dns_zone_ooni_io
  key_name                 = module.adm_iam_roles.oonidevops_key_name
  ecs_cluster_id           = module.ooniapi_cluster.cluster_id

  service_desired_count = 2

  task_secrets = {
    POSTGRESQL_URL              = aws_secretsmanager_secret_version.oonipg_url.arn
    JWT_ENCRYPTION_KEY          = aws_secretsmanager_secret_version.jwt_secret.arn
    PROMETHEUS_METRICS_PASSWORD = aws_secretsmanager_secret_version.prometheus_metrics_password.arn
  }

  ooniapi_service_security_groups = [
    module.ooniapi_cluster.web_security_group_id
  ]

  tags = merge(
    local.tags,
    { Name = "ooni-tier0-ooniprobe" }
  )
}


#### OONI Run service

module "ooniapi_oonirun_deployer" {
  source = "../../modules/ooniapi_service_deployer"

  service_name            = "oonirun"
  repo                    = "ooni/backend"
  branch_name             = "master"
  buildspec_path          = "ooniapi/services/oonirun/buildspec.yml"
  codestar_connection_arn = aws_codestarconnections_connection.oonidevops.arn

  codepipeline_bucket = aws_s3_bucket.ooniapi_codepipeline_bucket.bucket

  ecs_service_name = module.ooniapi_oonirun.ecs_service_name
  ecs_cluster_name = module.ooniapi_cluster.cluster_name
}

module "ooniapi_oonirun" {
  source = "../../modules/ooniapi_service"
  #first_run = true

  vpc_id             = module.network.vpc_id
  private_subnet_ids = module.network.vpc_subnet_private[*].id
  public_subnet_ids  = module.network.vpc_subnet_public[*].id

  service_name             = "oonirun"
  default_docker_image_url = "ooni/api-oonirun:latest"
  stage                    = local.environment
  dns_zone_ooni_io         = local.dns_zone_ooni_io
  key_name                 = module.adm_iam_roles.oonidevops_key_name
  ecs_cluster_id           = module.ooniapi_cluster.cluster_id

  service_desired_count = 2

  task_secrets = {
    POSTGRESQL_URL              = aws_secretsmanager_secret_version.oonipg_url.arn
    JWT_ENCRYPTION_KEY          = aws_secretsmanager_secret_version.jwt_secret.arn
    PROMETHEUS_METRICS_PASSWORD = aws_secretsmanager_secret_version.prometheus_metrics_password.arn
  }

  ooniapi_service_security_groups = [
    module.ooniapi_cluster.web_security_group_id
  ]

  tags = merge(
    local.tags,
    { Name = "ooni-tier0-oonirun" }
  )
}

#### OONI Findings service

module "ooniapi_oonifindings_deployer" {
  source = "../../modules/ooniapi_service_deployer"

  service_name            = "oonifindings"
  repo                    = "ooni/backend"
  branch_name             = "master"
  buildspec_path          = "ooniapi/services/oonifindings/buildspec.yml"
  codestar_connection_arn = aws_codestarconnections_connection.oonidevops.arn

  codepipeline_bucket = aws_s3_bucket.ooniapi_codepipeline_bucket.bucket

  ecs_service_name = module.ooniapi_oonifindings.ecs_service_name
  ecs_cluster_name = module.ooniapi_cluster.cluster_name
}

module "ooniapi_oonifindings" {
  source = "../../modules/ooniapi_service"

  # first_run          = true
  vpc_id             = module.network.vpc_id
  public_subnet_ids  = module.network.vpc_subnet_public[*].id
  private_subnet_ids = module.network.vpc_subnet_private[*].id

  service_name             = "oonifindings"
  default_docker_image_url = "ooni/api-oonifindings:latest"
  stage                    = local.environment
  dns_zone_ooni_io         = local.dns_zone_ooni_io
  key_name                 = module.adm_iam_roles.oonidevops_key_name
  ecs_cluster_id           = module.ooniapi_cluster.cluster_id

  task_secrets = {
    POSTGRESQL_URL              = aws_secretsmanager_secret_version.oonipg_url.arn
    JWT_ENCRYPTION_KEY          = aws_secretsmanager_secret_version.jwt_secret.arn
    PROMETHEUS_METRICS_PASSWORD = aws_secretsmanager_secret_version.prometheus_metrics_password.arn
  }

  ooniapi_service_security_groups = [
    module.ooniapi_cluster.web_security_group_id
  ]

  tags = merge(
    local.tags,
    { Name = "ooni-tier0-oonifindings" }
  )
}


#### OONI Auth service

module "ooniapi_ooniauth_deployer" {
  source = "../../modules/ooniapi_service_deployer"

  service_name            = "ooniauth"
  repo                    = "ooni/backend"
  branch_name             = "master"
  buildspec_path          = "ooniapi/services/ooniauth/buildspec.yml"
  codestar_connection_arn = aws_codestarconnections_connection.oonidevops.arn

  codepipeline_bucket = aws_s3_bucket.ooniapi_codepipeline_bucket.bucket

  ecs_service_name = module.ooniapi_ooniauth.ecs_service_name
  ecs_cluster_name = module.ooniapi_cluster.cluster_name
}

module "ooniapi_ooniauth" {
  source = "../../modules/ooniapi_service"
  # first_run = true

  vpc_id             = module.network.vpc_id
  private_subnet_ids = module.network.vpc_subnet_private[*].id
  public_subnet_ids  = module.network.vpc_subnet_public[*].id

  service_name             = "ooniauth"
  default_docker_image_url = "ooni/api-ooniauth:latest"
  stage                    = local.environment
  dns_zone_ooni_io         = local.dns_zone_ooni_io
  key_name                 = module.adm_iam_roles.oonidevops_key_name
  ecs_cluster_id           = module.ooniapi_cluster.cluster_id

  service_desired_count = 2

  task_secrets = {
    POSTGRESQL_URL              = aws_secretsmanager_secret_version.oonipg_url.arn
    JWT_ENCRYPTION_KEY          = aws_secretsmanager_secret_version.jwt_secret.arn
    PROMETHEUS_METRICS_PASSWORD = aws_secretsmanager_secret_version.prometheus_metrics_password.arn

    AWS_SECRET_ACCESS_KEY = module.ooniapi_user.aws_secret_access_key_arn
    AWS_ACCESS_KEY_ID     = module.ooniapi_user.aws_access_key_id_arn
  }
  task_environment = {
    AWS_REGION           = var.aws_region
    EMAIL_SOURCE_ADDRESS = module.ooniapi_user.email_address
    SESSION_EXPIRY_DAYS  = 180
    LOGIN_EXPIRY_DAYS    = 365
    ADMIN_EMAILS = jsonencode([
      "maja@ooni.org",
      "arturo@ooni.org",
      "jessie@ooni.org",
      "mehul@ooni.org",
      "norbel@ooni.org",
      "maria@ooni.org",
      "elizaveta@ooni.org",
      "admin+dev@ooni.org",
    ])
  }

  ooniapi_service_security_groups = [
    module.ooniapi_cluster.web_security_group_id
  ]

  tags = merge(
    local.tags,
    { Name = "ooni-tier0-ooniauth" }
  )
}

#### OONI Probe service

module "ooniapi_ooniprobe_deployer" {
  source = "../../modules/ooniapi_service_deployer"

  service_name            = "ooniprobe"
  repo                    = "ooni/backend"
  branch_name             = "master"
  buildspec_path          = "ooniprobe/services/ooniprobe/buildspec.yml"
  codestar_connection_arn = aws_codestarconnections_connection.oonidevops.arn

  codepipeline_bucket = aws_s3_bucket.ooniapi_codepipeline_bucket.bucket

  ecs_service_name = module.ooniapi_ooniprobe.ecs_service_name
  ecs_cluster_name = module.ooniapi_cluster.cluster_name
}

module "ooniapi_ooniprobe" {
  source = "../../modules/ooniapi_service"
 
  # First run should be set on first run to bootstrap the task definition
  first_run = true

  vpc_id             = module.network.vpc_id
  private_subnet_ids = module.network.vpc_subnet_private[*].id
  public_subnet_ids  = module.network.vpc_subnet_public[*].id

  service_name             = "ooniprobe"
  default_docker_image_url = "ooni/api-ooniprobe:latest"
  stage                    = local.environment
  dns_zone_ooni_io         = local.dns_zone_ooni_io
  key_name                 = module.adm_iam_roles.oonidevops_key_name
  ecs_cluster_id           = module.ooniapi_cluster.cluster_id

  service_desired_count = 2

  task_secrets = {
    POSTGRESQL_URL              = aws_secretsmanager_secret_version.oonipg_url.arn
    JWT_ENCRYPTION_KEY          = aws_secretsmanager_secret_version.jwt_secret.arn
    PROMETHEUS_METRICS_PASSWORD = aws_secretsmanager_secret_version.prometheus_metrics_password.arn
  }

  ooniapi_service_security_groups = [
    module.ooniapi_cluster.web_security_group_id
  ]

  tags = merge(
    local.tags,
    { Name = "ooni-tier0-ooniprobe" }
  )
}
#### OONI Tier0 API Frontend

module "ooniapi_frontend" {
  source = "../../modules/ooniapi_frontend"

  vpc_id     = module.network.vpc_id
  subnet_ids = module.network.vpc_subnet_public[*].id

  oonibackend_proxy_target_group_arn    = module.ooniapi_reverseproxy.alb_target_group_id
  ooniapi_oonirun_target_group_arn      = module.ooniapi_oonirun.alb_target_group_id
  ooniapi_ooniauth_target_group_arn     = module.ooniapi_ooniauth.alb_target_group_id
  ooniapi_ooniprobe_target_group_arn    = module.ooniapi_ooniprobe.alb_target_group_id
  ooniapi_oonifindings_target_group_arn = module.ooniapi_oonifindings.alb_target_group_id

  ooniapi_service_security_groups = [
    module.ooniapi_cluster.web_security_group_id
  ]

  ooniapi_acm_certificate_arn = aws_acm_certificate.ooniapi_frontend.arn

  oonith_domains = [
    "*.th.ooni.org",
  ]

  stage            = local.environment
  dns_zone_ooni_io = local.dns_zone_ooni_io

  tags = merge(
    local.tags,
    { Name = "ooni-tier0-api-frontend" }
  )
}


## DNS

locals {
  ooniapi_frontend_alternative_domains = {
    "api.ooni.org" : local.dns_root_zone_ooni_org
    "0.th.ooni.org" : local.dns_root_zone_ooni_org,
    "1.th.ooni.org" : local.dns_root_zone_ooni_org,
    "2.th.ooni.org" : local.dns_root_zone_ooni_org,
    "3.th.ooni.org" : local.dns_root_zone_ooni_org,
    "4.th.ooni.org" : local.dns_root_zone_ooni_org,
    "5.th.ooni.org" : local.dns_root_zone_ooni_org,
    "6.th.ooni.org" : local.dns_root_zone_ooni_org,
    "ooniauth.${local.environment}.ooni.io" : local.dns_zone_ooni_io,
    "ooniprobe.${local.environment}.ooni.io" : local.dns_zone_ooni_io,
    "oonirun.${local.environment}.ooni.io" : local.dns_zone_ooni_io,
    "oonifindings.${local.environment}.ooni.io" : local.dns_zone_ooni_io,
  }
  ooniapi_frontend_main_domain_name         = "api.${local.environment}.ooni.io"
  ooniapi_frontend_main_domain_name_zone_id = local.dns_zone_ooni_io

}

resource "aws_route53_record" "ooniapi_frontend_main" {
  name    = local.ooniapi_frontend_main_domain_name

  zone_id = local.ooniapi_frontend_main_domain_name_zone_id
  type    = "A"

  alias {
    name                   = module.ooniapi_frontend.ooniapi_dns_name
    zone_id                = module.ooniapi_frontend.ooniapi_dns_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "ooniapi_frontend_alt" {
  for_each = local.ooniapi_frontend_alternative_domains

  name    = each.key
  zone_id = each.value
  type    = "A"

  alias {
    name                   = module.ooniapi_frontend.ooniapi_dns_name
    zone_id                = module.ooniapi_frontend.ooniapi_dns_zone_id
    evaluate_target_health = true
  }
}

# TODO: currently the certificate is hardcoded
resource "aws_acm_certificate" "ooniapi_frontend" {
  domain_name       = local.ooniapi_frontend_main_domain_name
  validation_method = "DNS"

  tags = local.tags

  subject_alternative_names = keys(local.ooniapi_frontend_alternative_domains)
}

resource "aws_route53_record" "ooniapi_frontend_cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.ooniapi_frontend.domain_validation_options : dvo.domain_name => {
      name        = dvo.resource_record_name
      record      = dvo.resource_record_value
      type        = dvo.resource_record_type
      domain_name = dvo.domain_name
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = lookup(local.ooniapi_frontend_alternative_domains, each.value.domain_name, local.dns_zone_ooni_io)
}

resource "aws_acm_certificate_validation" "ooniapi_frontend" {
  certificate_arn         = aws_acm_certificate.ooniapi_frontend.arn
  validation_record_fqdns = [for record in aws_route53_record.ooniapi_frontend_cert_validation : record.fqdn]
}


## Code signing setup

module "codesigning" {
  source = "../../modules/cloudhsm"

  vpc_id             = module.network.vpc_id
  subnet_ids         = module.network.vpc_subnet_cloudhsm[*].id
  subnet_cidr_blocks = module.network.vpc_subnet_cloudhsm[*].cidr_block
  key_name           = module.adm_iam_roles.oonidevops_key_name
}

## Ansible controller setup

module "ansible_controller" {
  source = "../../modules/ansible_controller"

  vpc_id    = module.network.vpc_id
  subnet_id = module.network.vpc_subnet_public[0].id
  key_name  = module.adm_iam_roles.oonidevops_key_name

  dns_zone_ooni_io = local.dns_zone_ooni_io
}
