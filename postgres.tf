resource "aws_ecs_task_definition" "postgres" {
  family                   = "postgres"
  cpu                      = "256"
  execution_role_arn       = aws_iam_role.postgres-task-execution-role.arn
  memory                   = "512"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  task_role_arn            = aws_iam_role.postgres-task-role.arn
  volume {
    name = "postgres-db-volume"
    efs_volume_configuration {
      authorization_config {
        access_point_id = aws_efs_access_point.postgres.id
        iam             = "ENABLED"
      }
      file_system_id     = aws_efs_file_system.postgres.id
      transit_encryption = "ENABLED"
    }
  }
  container_definitions = data.template_file.postgres_container_definitions.rendered
}

data "template_file" "postgres_container_definitions" {
  template = file("task-definitions/postgres-container-definitions.tpl")
  vars = {
    log_configuration = jsonencode(local.log_configuration)
  }
}

resource "aws_ecs_service" "postgres" {
  name            = "postgres"
  cluster         = aws_ecs_cluster.airflow.id
  task_definition = aws_ecs_task_definition.postgres.arn
  desired_count   = 1
  depends_on = [
    aws_efs_mount_target.postgres_mt,
    aws_service_discovery_private_dns_namespace.cloudmap
  ]
  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100
  deployment_controller {
    type = "ECS"
  }
  launch_type = "FARGATE"
  network_configuration {
    subnets          = [for s in local.subnetsIDs : s]
    assign_public_ip = true
    security_groups  = [aws_security_group.default.id]
  }
  platform_version = "1.4.0"
  propagate_tags   = "SERVICE"
  service_registries {
    registry_arn = aws_service_discovery_service.postgres.arn
  }
  tags = {
    "com.docker.compose.project" = "airflow"
    "com.docker.compose.service" = "postgres"
  }
}

resource "aws_service_discovery_service" "postgres" {
  name        = "postgres"
  description = "\"postgres\" service discovery entry in Cloud Map"
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

resource "aws_iam_role" "postgres-task-execution-role" {
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
    "com.docker.compose.service" = "postgres"
  }
}

resource "aws_iam_role" "postgres-task-role" {
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
    name   = "AirflowpostgresAirflowVolumeMountPolicy"
    policy = data.aws_iam_policy_document.postgres_inline_policy.json
  }
}

data "aws_iam_policy_document" "postgres_inline_policy" {
  statement {
    actions = [
      "elasticfilesystem:ClientMount",
      "elasticfilesystem:ClientWrite",
      "elasticfilesystem:ClientRootAccess"
    ]
    resources = [aws_efs_file_system.postgres.arn]
    condition {
      test     = "StringEquals"
      variable = "elasticfilesystem:AccessPointArn"
      values   = [aws_efs_access_point.postgres.arn]
    }
  }
}