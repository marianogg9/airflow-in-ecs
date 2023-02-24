resource "aws_ecs_task_definition" "scheduler" {
  family                   = "scheduler"
  cpu                      = "256"
  execution_role_arn       = aws_iam_role.scheduler-task-execution-role.arn
  memory                   = "512"
  network_mode             = "awsvpc"
  requires_compatibilities = ["EC2"]
  task_role_arn            = aws_iam_role.scheduler-task-role.arn
  volume {
    name      = "airflow"
    host_path = "/opt/airflow/dags"
  }
  container_definitions = data.template_file.scheduler_container_definitions.rendered
}

data "template_file" "scheduler_container_definitions" {
  template = file("task-definitions/scheduler-container-definitions.tpl")
  vars = {
    secrets           = jsonencode(local.container_secrets)
    log_configuration = jsonencode(local.log_configuration)
  }
}

resource "aws_ecs_service" "scheduler" {
  name            = "scheduler"
  cluster         = aws_ecs_cluster.airflow.id
  task_definition = aws_ecs_task_definition.scheduler.arn
  desired_count   = 1
  depends_on = [
    aws_service_discovery_private_dns_namespace.cloudmap,
    aws_ecs_service.postgres
  ]
  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100
  deployment_controller {
    type = "ECS"
  }
  launch_type = "EC2"
  network_configuration {
    subnets = [for s in local.subnetsIDs : s]
    # assign_public_ip = true
    security_groups = [aws_security_group.default.id]
  }
  propagate_tags = "SERVICE"
  service_registries {
    registry_arn = aws_service_discovery_service.scheduler.arn
  }
  tags = {
    "com.docker.compose.project" = "airflow"
    "com.docker.compose.service" = "scheduler"
  }
  placement_constraints {
    type       = "memberOf"
    expression = "attribute:tier in ['core']"
  }
}

resource "aws_service_discovery_service" "scheduler" {
  name        = "scheduler"
  description = "\"scheduler\" service discovery entry in Cloud Map"
  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.cloudmap.id

    dns_records {
      ttl  = 60
      type = "A"
    }
    routing_policy = "MULTIVALUE"
  }
  health_check_custom_config {
    failure_threshold = 1
  }
}

resource "aws_iam_role" "scheduler-task-execution-role" {
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  ]
  tags = {
    "com.docker.compose.project" = "airflow"
    "com.docker.compose.service" = "scheduler"
  }
  inline_policy {
    name   = "AirflowSchedulerAdminSecretPolicy"
    policy = data.aws_iam_policy_document.scheduler_inline_policy_secrets.json
  }
}

resource "aws_iam_role" "scheduler-task-role" {
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
  inline_policy {
    name   = "AirflowSchedulerAdminSecretPolicy"
    policy = data.aws_iam_policy_document.scheduler_inline_policy_secrets.json
  }
}

data "aws_iam_policy_document" "scheduler_inline_policy_secrets" {
  statement {
    actions = [
      "secretsmanager:GetSecretValue"
    ]
    resources = [aws_secretsmanager_secret.airflow_ui_admin_password.arn]
  }
}