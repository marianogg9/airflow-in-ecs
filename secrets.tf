resource "random_password" "airflow_ui_admin_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_secretsmanager_secret" "airflow_ui_admin_password" {
  name                    = "airflow-ui-admin-password"
  recovery_window_in_days = 0 // set to avoid SSM error on deleting
}

resource "aws_secretsmanager_secret_version" "airflow_ui_admin_password" {
  secret_id     = aws_secretsmanager_secret.airflow_ui_admin_password.id
  secret_string = random_password.airflow_ui_admin_password.result
}