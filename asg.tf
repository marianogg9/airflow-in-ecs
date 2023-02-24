data "aws_key_pair" "default" {
  count = local.aws_key_pair_name != "" ? 1 : 0

  key_name           = "default"
  include_public_key = true

  filter {
    name   = "key-name"
    values = [local.aws_key_pair_name]
  }
}

resource "aws_iam_instance_profile" "ecs_instance_profile" {
  name = "ecs-instance-profile"
  role = aws_iam_role.ecs_instance_role.id
}

resource "aws_iam_role" "ecs_instance_role" {
  name = "ecs-instance-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Principal = {
          "Service" = ["ecs.amazonaws.com", "ec2.amazonaws.com"]
        }
        Sid = ""
      }
    ]
  })
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
  ]
  inline_policy {
    name   = "s3_access"
    policy = data.aws_iam_policy_document.s3_access.json
  }
}

data "aws_iam_policy_document" "s3_access" {
  statement {
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListObject",
      "s3:DeleteObject"
    ]
    resources = [
      join("", [aws_s3_bucket.airflow.arn, "/*"])
    ]
  }
  statement {
    actions = [
      "s3:ListBucket"
    ]
    resources = [
      aws_s3_bucket.airflow.arn
    ]
  }
}

resource "aws_autoscaling_group" "core" {
  name             = "core"
  max_size         = 2
  min_size         = 1
  desired_capacity = 1
  launch_template {
    id      = aws_launch_template.core.id
    version = "$Latest"
  }
  vpc_zone_identifier = [for subnet in local.subnetsIDs : subnet]
  #target_group_arns = [aws_lb_target_group.airflow.arn]
  tag {
    key                 = "tier"
    value               = "core"
    propagate_at_launch = true
  }
}

resource "aws_launch_template" "core" {
  name_prefix   = "core"
  image_id      = "ami-0032de2848deba7de"
  instance_type = "t3.medium"
  user_data     = base64encode(templatefile("user-data/core-user-data.sh", local.user_data_vars))
  key_name      = local.aws_key_pair_name // data.aws_key_pair.default.key_name
  iam_instance_profile {
    name = aws_iam_instance_profile.ecs_instance_profile.name
  }
  vpc_security_group_ids = [aws_security_group.default.id]
}

resource "aws_autoscaling_group" "worker" {
  name             = "worker"
  max_size         = 1
  min_size         = 1
  desired_capacity = 1
  launch_template {
    id      = aws_launch_template.worker.id
    version = "$Latest"
  }
  vpc_zone_identifier = [for subnet in local.subnetsIDs : subnet]
  tag {
    key                 = "tier"
    value               = "worker"
    propagate_at_launch = true
  }
}

resource "aws_launch_template" "worker" {
  name_prefix   = "worker"
  image_id      = local.ecs-ami
  instance_type = local.instance-type
  user_data     = base64encode(templatefile("user-data/worker-user-data.sh", local.user_data_vars))
  key_name      = local.aws_key_pair_name // data.aws_key_pair.default.key_name
  iam_instance_profile {
    name = aws_iam_instance_profile.ecs_instance_profile.name
  }
  vpc_security_group_ids = [aws_security_group.default.id]
  instance_market_options {
    market_type = "spot"
  }
}

resource "aws_security_group_rule" "allow_ssh_from_custom_ip" {
  count = local.custom_cidr != [] && local.aws_key_pair_name != "" ? 1 : 0

  type              = "ingress"
  description       = "Allow SSH access from a given IP (CIDR)"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = local.custom_cidr
  security_group_id = aws_security_group.default.id
}