output "nlb_cname" {
  description = "Webserver + Flower NLB"
  value       = aws_lb.airflow.dns_name
}

output "airflow_ui_password_secret_arn" {
  description = "Airflow Webserver user Secrets Manager secret ARN"
  value       = aws_secretsmanager_secret.airflow_ui_admin_password.arn
}

output "s3_bucket" {
  description = "DAG S3 bucket"
  value       = aws_s3_bucket.airflow.id
}