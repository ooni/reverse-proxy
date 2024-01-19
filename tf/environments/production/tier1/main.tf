provider "aws" {
  region = local.region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_access_key
}

data "aws_availability_zones" "available" {}

locals {
  region = "eu-central-1"
  environment = "production"
  name   = "ooni-tier1-${local.environment}"

  vpc_cidr = "10.0.0.0/16"
  azs      = slice(data.aws_availability_zones.available.names, 0, 3)

  tags = {
    Name       = local.name
    Repository = "https://github.com/ooni/devops"
  }
}

################################################################################
# Cluster
################################################################################

module "ecs_cluster" {
  source = "terraform-aws-modules/ecs/aws//modules/cluster"

  cluster_name = local.name

  # Capacity provider - autoscaling groups
  default_capacity_provider_use_fargate = false
  autoscaling_capacity_providers = {
    # On-demand instances
    small = {
      auto_scaling_group_arn         = module.autoscaling["small"].autoscaling_group_arn
      managed_termination_protection = "ENABLED"

      managed_scaling = {
        maximum_scaling_step_size = 3
        minimum_scaling_step_size = 1
        status                    = "ENABLED"
        target_capacity           = 60
      }

      default_capacity_provider_strategy = {
        weight = 60
        base   = 20
      }
    }
    # Spot instances
    micro = {
      auto_scaling_group_arn         = module.autoscaling["micro"].autoscaling_group_arn
      managed_termination_protection = "ENABLED"

      managed_scaling = {
        maximum_scaling_step_size = 3
        minimum_scaling_step_size = 1
        status                    = "ENABLED"
        target_capacity           = 90
      }

      default_capacity_provider_strategy = {
        weight = 40
      }
    }
  }

  tags = local.tags
}

################################################################################
# Service
################################################################################

locals {
  container_image = "ooni/dataapi:latest"
  container_name = "ooni_dataapi"
  container_port = 80
}

# TODO(art): Look into the destruction of the capacity_provider as there seems
# to be a logic issue in how this works in terraform:
# https://github.com/hashicorp/terraform-provider-aws/issues/18849
# https://github.com/hashicorp/terraform-provider-aws/issues/4852
# https://github.com/hashicorp/terraform-provider-aws/issues/11409
module "ecs_service" {

  source = "terraform-aws-modules/ecs/aws//modules/service"

  # Service
  name        = local.name
  cluster_arn = module.ecs_cluster.arn

  # Task Definition
  requires_compatibilities = ["EC2"]
  capacity_provider_strategy = {
    # On-demand instances
    small = {
      capacity_provider = module.ecs_cluster.autoscaling_capacity_providers["small"].name
      weight            = 1
      base              = 1
    }
  }

  volume = {
    my-vol = {}
  }

  # Container definition(s)
  container_definitions = {
    (local.container_name) = {
      image = local.container_image,
      port_mappings = [
        {
          name          =   local.container_name,
          containerPort = 80,
          protocol      = "tcp"
        }
      ]
    }
  }

  load_balancer = {
    service = {
      target_group_arn = module.alb.target_groups["backend_ecs"].arn
      container_name   = local.container_name
      container_port   = local.container_port
    }
  }

  subnet_ids = module.vpc.private_subnets
  security_group_rules = {
    alb_http_ingress = {
      type                     = "ingress"
      from_port                = local.container_port
      to_port                  = local.container_port
      protocol                 = "tcp"
      description              = "Service port"
      source_security_group_id = module.alb.security_group_id
    }
  }

  tags = local.tags
}

################################################################################
# Supporting Resources
################################################################################

# https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-optimized_AMI.html#ecs-optimized-ami-linux
data "aws_ssm_parameter" "ecs_optimized_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended"
}

module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 9.0"

  name = local.name

  load_balancer_type = "application"

  vpc_id  = module.vpc.vpc_id
  subnets = module.vpc.public_subnets

  # For example only
  enable_deletion_protection = false

  # Security Group
  security_group_ingress_rules = {
    all_http = {
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }
  security_group_egress_rules = {
    all = {
      ip_protocol = "-1"
      cidr_ipv4   = module.vpc.vpc_cidr_block
    }
  }

  listeners = {
    ex_http = {
      port     = 80
      protocol = "HTTP"

      forward = {
        target_group_key = "backend_ecs"
      }
    }
  }

  target_groups = {
    backend_ecs = {
      backend_protocol                  = "HTTP"
      backend_port                      = 80
      target_type                       = "ip"
      deregistration_delay              = 5
      load_balancing_cross_zone_enabled = true

      health_check = {
        enabled             = true
        healthy_threshold   = 5
        interval            = 30
        matcher             = "200"
        path                = "/"
        port                = "traffic-port"
        protocol            = "HTTP"
        timeout             = 5
        unhealthy_threshold = 2
      }

      # Theres nothing to attach here in this definition. Instead,
      # ECS will attach the IPs of the tasks to this target group
      create_attachment = false
    }
  }

  tags = local.tags
}

module "autoscaling" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "~> 6.5"

  for_each = {
    # On-demand instances
    small = {
      instance_type              = "t3.small"
      use_mixed_instances_policy = false
      mixed_instances_policy     = {}
      user_data                  = templatefile("${path.module}/templates/ecs-setup.sh.tftpl", {
        ecs_cluster_name = local.name,
        ecs_cluster_tags = local.tags,
        datadog_api_key  = var.datadog_api_key,
      })
    }
    # Spot instances
    micro = {
      instance_type              = "t3.micro"
      use_mixed_instances_policy = true
      mixed_instances_policy = {
        instances_distribution = {
          on_demand_base_capacity                  = 0
          on_demand_percentage_above_base_capacity = 0
          spot_allocation_strategy                 = "price-capacity-optimized"
        }
      }
      user_data                  = templatefile("${path.module}/templates/ecs-setup.sh.tftpl", {
        ecs_cluster_name = local.name,
        ecs_cluster_tags = local.tags,
        datadog_api_key  = var.datadog_api_key,
      })
    }
  }

  name = "${local.name}-${each.key}"

  image_id      = jsondecode(data.aws_ssm_parameter.ecs_optimized_ami.value)["image_id"]
  instance_type = each.value.instance_type

  security_groups                 = [module.autoscaling_sg.security_group_id]
  user_data                       = base64encode(each.value.user_data)
  ignore_desired_capacity_changes = true

  create_iam_instance_profile = true
  iam_role_name               = local.name
  iam_role_description        = "ECS role for ${local.name}"
  iam_role_policies = {
    AmazonEC2ContainerServiceforEC2Role = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
    AmazonSSMManagedInstanceCore        = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }

  vpc_zone_identifier = module.vpc.private_subnets
  health_check_type   = "EC2"
  min_size            = 1
  max_size            = 2
  desired_capacity    = 1

  # https://github.com/hashicorp/terraform-provider-aws/issues/12582
  autoscaling_group_tags = {
    AmazonECSManaged = true
  }

  # Required for  managed_termination_protection = "ENABLED"
  protect_from_scale_in = true

  # Spot instances
  use_mixed_instances_policy = each.value.use_mixed_instances_policy
  mixed_instances_policy     = each.value.mixed_instances_policy

  tags = local.tags
}

module "autoscaling_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = local.name
  description = "Autoscaling group security group"
  vpc_id      = module.vpc.vpc_id

  computed_ingress_with_source_security_group_id = [
    {
      rule                     = "http-80-tcp"
      source_security_group_id = module.alb.security_group_id
    }
  ]
  number_of_computed_ingress_with_source_security_group_id = 1

  egress_rules = ["all-all"]

  tags = local.tags
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = local.name
  cidr = local.vpc_cidr

  azs             = local.azs
  private_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 4, k)]
  public_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 48)]

  enable_nat_gateway = true
  single_nat_gateway = true

  tags = local.tags
}
