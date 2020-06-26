variable "api_key" {
  type        = string
  description = "Use a different API key than the default one in dev-infra/dd_api_key/sre_scripts/secret.b64"
  default     = ""
}

variable "docker_labels_container_port" {
  type        = number
  description = "The container port for the `com.datadoghq.ad.instances`. Useful if `var.docker_labels` is undefined."
  default     = 8080
}

variable "docker_labels_check_names" {
  type        = list
  description = "The integrations for the `com.datadoghq.ad.check_names`. Useful if `var.docker_labels` is undefined."
  default     = []
}

variable "docker_labels_init_configs" {
  type        = list
  description = "The integrations for the `com.datadoghq.ad.init_configs`. Useful if `var.docker_labels` is undefined."
  default     = [{}]
}

variable "logging_group_name" {
  type        = string
  description = "If logging to cloudwatch, this will be the cloudwatch log group name"
  default     = ""
}

### Environment variable switches
### These can be appended using var.map_environment

variable "ecs_fargate" {
  type        = bool
  description = "Set to true to add `ECS_FARGATE` environment variable"
  default     = true
}

variable "apm_enabled" {
  type        = bool
  description = "Set to true to add `DD_APM_ENABLED` environment variable"
  default     = true
}

variable "apm_non_local_traffic" {
  type        = bool
  description = "Set to true to add `DD_APM_NON_LOCAL_TRAFFIC` environment variable"
  default     = true
}

variable "process_agent_enabled" {
  type        = bool
  description = "Set to true to add `DD_PROCESS_AGENT_ENABLED` environment variable"
  default     = true
}

variable "dd_tags" {
  type        = string
  description = "The datadog tags for the metrics and service map expressed as a colon and comma separated string. Ex: `labelname1:value1,labelname2:value2`"
  default     = ""
}

### Copied from https://github.com/cloudposse/terraform-aws-ecs-container-definition.git?ref=tags/0.37.0
### Updated with datadog defaults
### Removed environment in favor of map_environment

variable "container_name" {
  type        = string
  description = "The name of the container. Up to 255 characters ([a-z], [A-Z], [0-9], -, _ allowed)"
  default     = "datadog-agent"
}

variable "container_image" {
  type        = string
  description = "The image used to start the container. Images in the Docker Hub registry available by default"
  default     = "datadog/agent:latest"
}

variable "container_memory" {
  type        = number
  description = "The amount of memory (in MiB) to allow the container to use. This is a hard limit, if the container attempts to exceed the container_memory, the container is killed. This field is optional for Fargate launch type and the total amount of container_memory of all containers in a task will need to be lower than the task memory value"
  default     = 192
}

variable "container_memory_reservation" {
  type        = number
  description = "The amount of memory (in MiB) to reserve for the container. If container needs to exceed this threshold, it can do so up to the set container_memory hard limit"
  default     = null
}

variable "container_definition" {
  type        = map
  description = "Container definition overrides which allows for extra keys or overriding existing keys."
  default     = {}
}

variable "port_mappings" {
  type = list(object({
    containerPort = number
    hostPort      = number
    protocol      = string
  }))

  description = "The port mappings to configure for the container. This is a list of maps. Each map should contain \"containerPort\", \"hostPort\", and \"protocol\", where \"protocol\" is one of \"tcp\" or \"udp\". If using containers in a task with the awsvpc or host network mode, the hostPort can either be left blank or set to the same value as the containerPort"

  default = [
    # "host port that uses 8126 with tcp protocol under port mappings."
    # source: https://docs.datadoghq.com/integrations/ecs_fargate/#trace-collection
    {
      protocol      = "tcp",
      hostPort      = 8126,
      containerPort = 8126
    },
    # "Metrics are collected with DogStatsD through UDP port 8125"
    # source: https://docs.datadoghq.com/integrations/ecs_fargate/#dogstatsd
    {
      protocol      = "udp",
      hostPort      = 8125,
      containerPort = 8125
    }
  ]
}

# https://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_HealthCheck.html
variable "healthcheck" {
  type = object({
    command     = list(string)
    retries     = number
    timeout     = number
    interval    = number
    startPeriod = number
  })
  description = "A map containing command (string), timeout, interval (duration in seconds), retries (1-10, number of times to retry before marking container unhealthy), and startPeriod (0-300, optional grace period to wait, in seconds, before failed healthchecks count toward retries)"
  default = {
    interval    = 30
    retries     = 3
    startPeriod = 0
    timeout     = 5
    command = [
      "CMD-SHELL",
      "agent health"
    ]
  }
}

variable "container_cpu" {
  type        = number
  description = "The number of cpu units to reserve for the container. This is optional for tasks using Fargate launch type and the total amount of container_cpu of all containers in a task will need to be lower than the task-level cpu value"
  default     = 192
}

variable "essential" {
  type        = bool
  description = "Determines whether all other containers in a task are stopped, if this container fails or stops for any reason. Due to how Terraform type casts booleans in json it is required to double quote this value"
  default     = true
}

variable "entrypoint" {
  type        = list(string)
  description = "The entry point that is passed to the container"
  default     = null
}

variable "command" {
  type        = list(string)
  description = "The command that is passed to the container"
  default     = null
}

variable "working_directory" {
  type        = string
  description = "The working directory to run commands inside the container"
  default     = null
}

variable "extra_hosts" {
  type = list(object({
    ipAddress = string
    hostname  = string
  }))
  description = "A list of hostnames and IP address mappings to append to the /etc/hosts file on the container. This is a list of maps"
  default     = null
}

variable "map_environment" {
  type        = map(string)
  description = "The environment variables to pass to the container. This is a map of string: {key: value}, environment override map_environment"
  default     = {}
}

# https://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_EnvironmentFile.html
variable "environment_files" {
  type = list(object({
    value = string
    type  = string
  }))
  description = "One or more files containing the environment variables to pass to the container. This maps to the --env-file option to docker run. The file must be hosted in Amazon S3. This option is only available to tasks using the EC2 launch type. This is a list of maps"
  default     = null
}

variable "secrets" {
  type = list(object({
    name      = string
    valueFrom = string
  }))
  description = "The secrets to pass to the container. This is a list of maps"
  default     = null
}

variable "readonly_root_filesystem" {
  type        = bool
  description = "Determines whether a container is given read-only access to its root filesystem. Due to how Terraform type casts booleans in json it is required to double quote this value"
  default     = false
}

# https://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_LinuxParameters.html
variable "linux_parameters" {
  type = object({
    capabilities = object({
      add  = list(string)
      drop = list(string)
    })
    devices = list(object({
      containerPath = string
      hostPath      = string
      permissions   = list(string)
    }))
    initProcessEnabled = bool
    maxSwap            = number
    sharedMemorySize   = number
    swappiness         = number
    tmpfs = list(object({
      containerPath = string
      mountOptions  = list(string)
      size          = number
    }))
  })
  description = "Linux-specific modifications that are applied to the container, such as Linux kernel capabilities. For more details, see https://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_LinuxParameters.html"
  default     = null
}

# https://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_LogConfiguration.html
variable "log_configuration" {
  # type        = map
  description = "Log configuration options to send to a custom log driver for the container. For more details, see https://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_LogConfiguration.html"
  default     = null
}

# https://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_FirelensConfiguration.html
variable "firelens_configuration" {
  type = object({
    type    = string
    options = map(string)
  })
  description = "The FireLens configuration for the container. This is used to specify and configure a log router for container logs. For more details, see https://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_FirelensConfiguration.html"
  default     = null
}

variable "mount_points" {
  type = list

  description = "Container mount points. This is a list of maps, where each map should contain a `containerPath` and `sourceVolume`. The `readOnly` key is optional."
  default     = []
}

variable "dns_servers" {
  type        = list(string)
  description = "Container DNS servers. This is a list of strings specifying the IP addresses of the DNS servers"
  default     = null
}

variable "dns_search_domains" {
  type        = list(string)
  description = "Container DNS search domains. A list of DNS search domains that are presented to the container"
  default     = null
}

variable "ulimits" {
  type = list(object({
    name      = string
    hardLimit = number
    softLimit = number
  }))
  description = "Container ulimit settings. This is a list of maps, where each map should contain \"name\", \"hardLimit\" and \"softLimit\""
  default     = null
}

variable "repository_credentials" {
  type        = map(string)
  description = "Container repository credentials; required when using a private repo.  This map currently supports a single key; \"credentialsParameter\", which should be the ARN of a Secrets Manager's secret holding the credentials"
  default     = null
}

variable "volumes_from" {
  type = list(object({
    sourceContainer = string
    readOnly        = bool
  }))
  description = "A list of VolumesFrom maps which contain \"sourceContainer\" (name of the container that has the volumes to mount) and \"readOnly\" (whether the container can write to the volume)"
  default     = []
}

variable "links" {
  type        = list(string)
  description = "List of container names this container can communicate with without port mappings"
  default     = null
}

variable "user" {
  type        = string
  description = "The user to run as inside the container. Can be any of these formats: user, user:group, uid, uid:gid, user:gid, uid:group. The default (null) will use the container's configured `USER` directive or root if not set."
  default     = null
}

variable "container_depends_on" {
  type = list(object({
    containerName = string
    condition     = string
  }))
  description = "The dependencies defined for container startup and shutdown. A container can contain multiple dependencies. When a dependency is defined for container startup, for container shutdown it is reversed. The condition can be one of START, COMPLETE, SUCCESS or HEALTHY"
  default     = null
}

variable "docker_labels" {
  type        = map(string)
  description = "The configuration options to send to the `docker_labels`"
  default     = null
}

variable "start_timeout" {
  type        = number
  description = "Time duration (in seconds) to wait before giving up on resolving dependencies for a container"
  default     = null
}

variable "stop_timeout" {
  type        = number
  description = "Time duration (in seconds) to wait before the container is forcefully killed if it doesn't exit normally on its own"
  default     = null
}

variable "privileged" {
  type        = bool
  description = "When this variable is `true`, the container is given elevated privileges on the host container instance (similar to the root user). This parameter is not supported for Windows containers or tasks using the Fargate launch type."
  default     = null
}

variable "system_controls" {
  type        = list(map(string))
  description = "A list of namespaced kernel parameters to set in the container, mapping to the --sysctl option to docker run. This is a list of maps: { namespace = \"\", value = \"\"}"
  default     = null
}
