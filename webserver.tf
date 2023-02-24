resource "aws_ecs_task_definition" "webserver" {
  family                   = "webserver"
  cpu                      = "512"
  execution_role_arn       = aws_iam_role.webserver-task-execution-role.arn
  memory                   = "1536"
  network_mode             = "awsvpc"
  requires_compatibilities = ["EC2"]
  task_role_arn            = aws_iam_role.webserver-task-role.arn
  volume {
    name      = "airflow"
    host_path = "/opt/airflow/dags"
  }
  container_definitions = data.template_file.webserver_container_definitions.rendered
}

data "template_file" "webserver_container_definitions" {
  template = file("task-definitions/webserver-container-definitions.tpl")
  vars = {
    log_configuration = jsonencode(local.log_configuration)
  }
}

resource "aws_ecs_service" "webserver" {
  name            = "webserver"
  cluster         = aws_ecs_cluster.airflow.id
  task_definition = aws_ecs_task_definition.webserver.arn
  desired_count   = 1
  depends_on = [
    aws_service_discovery_private_dns_namespace.cloudmap,
    aws_ecs_service.scheduler
  ]
  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100
  deployment_controller {
    type = "ECS"
  }
  launch_type = "EC2"
  network_configuration {
    subnets         = [for s in local.subnetsIDs : s]
    security_groups = [aws_security_group.default.id]
  }
  propagate_tags = "SERVICE"
  service_registries {
    registry_arn = aws_service_discovery_service.webserver.arn
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.webserver.arn
    container_name   = "airflow-webserver"
    container_port   = 8080
  }
  tags = {
    "com.docker.compose.project" = "airflow"
    "com.docker.compose.service" = "webserver"
  }
  placement_constraints {
    type       = "memberOf"
    expression = "attribute:tier in ['core']"
  }
}

resource "aws_service_discovery_service" "webserver" {
  name        = "webserver"
  description = "\"webserver\" service discovery entry in Cloud Map"
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

resource "aws_iam_role" "webserver-task-execution-role" {
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
    "com.docker.compose.service" = "webserver"
  }
}

resource "aws_iam_role" "webserver-task-role" {
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

resource "aws_lb_target_group" "webserver" {
  name        = "webserver"
  port        = 8080
  target_type = "ip"
  vpc_id      = local.default_vpc_id
  protocol    = "TCP"
}

resource "aws_lb_listener" "webserver" {
  load_balancer_arn = aws_lb.airflow.arn
  port              = 8080
  protocol          = "TCP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.webserver.arn
  }
}