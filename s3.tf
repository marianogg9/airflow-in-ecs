resource "aws_s3_bucket" "airflow" {
  bucket_prefix = "airflow"
  tags = {
    Name = "airflow"
  }
}