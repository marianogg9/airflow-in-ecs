resource "aws_efs_file_system" "postgres" {
  creation_token = "postgres-efs"
  encrypted      = true

  tags = {
    Name = "postgres-efs"
  }
}

resource "aws_efs_access_point" "postgres" {
  file_system_id = aws_efs_file_system.postgres.id
}

resource "aws_efs_mount_target" "postgres_mt" {
  for_each = local.subnetsIDs

  file_system_id  = aws_efs_file_system.postgres.id
  subnet_id       = each.value
  security_groups = [aws_security_group.default.id]
}