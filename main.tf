provider "aws" {
  alias  = "us-east-1"
  region = "us-east-1"
}

data "aws_s3_bucket_object" "api_key" {
  count = length(var.api_key) == 0 ? 1 : 0

  provider = aws.us-east-1

  bucket = "adroll-secrets"
  key    = "dev-infra/dd_api_key/sre_scripts/secret.b64"
}

data "aws_region" "current" {}

locals {
  # If logging is enabled, then log to cloudwatch, otherwise use the inputted var.log_configuration
  log_configuration = length(var.logging_group_name) > 0 ? {
    logDriver = "awslogs"
    options = {
      awslogs-group         = var.logging_group_name
      awslogs-region        = data.aws_region.current.name
      awslogs-stream-prefix = "ecs"
    }
    secretOptions = null
  } : var.log_configuration

  map_environment = merge({
    ECS_FARGATE              = tostring(var.ecs_fargate)
    DD_PROCESS_AGENT_ENABLED = tostring(var.process_agent_enabled)
    DD_APM_ENABLED           = tostring(var.apm_enabled)
    DD_API_KEY               = length(var.api_key) > 0 ? var.api_key : base64decode(join("", data.aws_s3_bucket_object.api_key.*.body))
    DD_APM_NON_LOCAL_TRAFFIC = tostring(var.apm_non_local_traffic)
    DD_TAGS                  = var.dd_tags
  }, var.map_environment)

  docker_labels = coalesce(var.docker_labels, {
    "com.datadoghq.ad.instances" = jsonencode([
      {
        host = "%%host%%"
        port = var.docker_labels_container_port
      }
    ])
    # integrations
    "com.datadoghq.ad.check_names"  = jsonencode(var.docker_labels_check_names)
    "com.datadoghq.ad.init_configs" = jsonencode(var.docker_labels_init_configs)
  })
}

module "container" {
  source = "git::https://github.com/cloudposse/terraform-aws-ecs-container-definition.git?ref=tags/0.56.0"

  container_name               = var.container_name
  container_image              = var.container_image
  essential                    = var.essential
  entrypoint                   = var.entrypoint
  command                      = var.command
  working_directory            = var.working_directory
  readonly_root_filesystem     = var.readonly_root_filesystem
  mount_points                 = var.mount_points
  dns_servers                  = var.dns_servers
  dns_search_domains           = var.dns_search_domains
  ulimits                      = var.ulimits
  repository_credentials       = var.repository_credentials
  links                        = var.links
  volumes_from                 = var.volumes_from
  user                         = var.user
  container_depends_on         = var.container_depends_on
  privileged                   = var.privileged
  port_mappings                = var.port_mappings
  healthcheck                  = var.healthcheck
  firelens_configuration       = var.firelens_configuration
  linux_parameters             = var.linux_parameters
  log_configuration            = local.log_configuration
  container_memory             = var.container_memory
  container_memory_reservation = var.container_memory_reservation
  container_cpu                = var.container_cpu
  map_environment              = local.map_environment
  environment_files            = var.environment_files
  secrets                      = var.secrets
  docker_labels                = local.docker_labels
  start_timeout                = var.start_timeout
  stop_timeout                 = var.stop_timeout
  system_controls              = var.system_controls
  extra_hosts                  = var.extra_hosts
  container_definition         = var.container_definition
}
