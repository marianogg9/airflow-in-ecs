# fetch vpc, subnets and additional stuff.
data "aws_vpc" "default" {
  id = local.default_vpc_id
}