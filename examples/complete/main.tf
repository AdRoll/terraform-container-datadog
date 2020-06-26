variable "region" {
  default = "us-east-2"
}

provider "aws" {
  region  = var.region
  version = "= 2.68"
}

module "container" {
  source = "../.."

  dd_tags = "env:staging"

  # example dockerlabels
  # https://docs.datadoghq.com/integrations/faq/integration-setup-ecs-fargate/?tab=rediswebui
  docker_labels = {
    "com.datadoghq.ad.instances" = jsonencode([
      {
        host = "%%host%%"
        port = 8080
      }
    ])
    "com.datadoghq.ad.check_names" = jsonencode(
      [
        "supervisord"
      ]
    )
    "com.datadoghq.ad.init_configs" = jsonencode(
      [{}]
    )
  }

  container_name               = "app"
  container_image              = "datadog/agent:latest"
  container_memory             = 256
  container_memory_reservation = 128
  container_cpu                = 256
  essential                    = true
  readonly_root_filesystem     = false

  map_environment = {
    string_var        = "I am a string"
    true_boolean_var  = true
    false_boolean_var = false
    integer_var       = 42
  }

  port_mappings = [
    {
      containerPort = 8080
      hostPort      = 80
      protocol      = "tcp"
    },
    {
      containerPort = 8081
      hostPort      = 443
      protocol      = "udp"
    }
  ]

  log_configuration = {
    logDriver = "json-file"
    options = {
      "max-size" = "10m"
      "max-file" = "3"
    }
    secretOptions = null
  }

  privileged = false

  extra_hosts = [
    {
      ipAddress = "127.0.0.1"
      hostname  = "app.local"
    },
  ]
}
