terraform {
  backend "s3" {
    bucket         = "your_tf_bucket"
    key            = "your_tfstate_key"
    region         = "your_region"
    dynamodb_table = "your_dynamodb_table"
  }
}
