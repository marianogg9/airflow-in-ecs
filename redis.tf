resource "aws_ecs_task_definition" "redis" {
  family                   = "redis"
  cpu                      = "256"
  execution_role_arn       = aws_iam_role.redis-task-execution-role.arn
  memory                   = "512"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  task_role_arn            = aws_iam_role.redis-task-role.arn
  container_definitions    = data.template_file.redis_container_definitions.rendered
}

data "template_file" "redis_container_definitions" {
  template = file("task-definitions/redis-container-definitions.tpl")
  vars = {
    log_configuration = jsonencode(local.log_configuration)
  }
}

resource "aws_ecs_service" "redis" {
  name            = "redis"
  cluster         = aws_ecs_cluster.airflow.id
  task_definition = aws_ecs_task_definition.redis.arn
  desired_count   = 1
  depends_on = [
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
    registry_arn = aws_service_discovery_service.redis.arn
  }
  tags = {
    "com.docker.compose.project" = "airflow"
    "com.docker.compose.service" = "redis"
  }
}

resource "aws_service_discovery_service" "redis" {
  name        = "redis"
  description = "\"redis\" service discovery entry in Cloud Map"
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

resource "aws_iam_role" "redis-task-execution-role" {
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
    "com.docker.compose.service" = "redis"
  }
}

resource "aws_iam_role" "redis-task-role" {
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
}