# create ECS definitions

resource "aws_ecs_cluster" "airflow" {
  name = "airflow-tf"

  tags = {
    Name = "airflow-tf"
  }
}

resource "aws_security_group" "default" {
  name        = "airflow"
  description = "Default SG"
  vpc_id      = local.default_vpc_id
}

resource "aws_security_group_rule" "allow_8080" {
  count = local.custom_cidr != [] ? 1 : 0

  type              = "ingress"
  description       = "Allow 8080 traffic from selected CIDR(s)"
  from_port         = 8080
  to_port           = 8080
  protocol          = "tcp"
  cidr_blocks       = local.custom_cidr // narrowing down access to a given CIDR
  security_group_id = aws_security_group.default.id
}

resource "aws_security_group_rule" "allow_5555" {
  count = local.custom_cidr != [] ? 1 : 0

  type              = "ingress"
  description       = "Allow 5555 traffic from selected CIDR(s)"
  from_port         = 5555
  to_port           = 5555
  protocol          = "tcp"
  cidr_blocks       = local.custom_cidr // narrowing down access to a given CIDR
  security_group_id = aws_security_group.default.id
}

resource "aws_security_group_rule" "allow_internal_traffic" {
  type                     = "ingress"
  description              = "Allow internal network traffic"
  security_group_id        = aws_security_group.default.id
  source_security_group_id = aws_security_group.default.id
  protocol                 = -1
  from_port                = 0
  to_port                  = 0
}

resource "aws_security_group_rule" "allow_internal_traffic_by_IP" {
  type              = "ingress"
  description       = "Allow internal network traffic by IP"
  security_group_id = aws_security_group.default.id
  cidr_blocks       = [data.aws_vpc.default.cidr_block]
  protocol          = -1
  from_port         = 0
  to_port           = 0
}

resource "aws_security_group_rule" "out" {
  type              = "egress"
  description       = "Allow Internet outbound"
  security_group_id = aws_security_group.default.id
  protocol          = -1
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_service_discovery_private_dns_namespace" "cloudmap" {
  name        = "airflow.local"
  description = "Service Map for Docker Compose project airflow"
  vpc         = local.default_vpc_id
}

resource "aws_lb" "airflow" {
  name               = "airflow"
  internal           = false
  load_balancer_type = "network"
  subnets            = [for subnet in local.subnetsIDs : subnet]
}