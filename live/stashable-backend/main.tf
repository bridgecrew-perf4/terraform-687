terraform {
  backend "s3" {
    bucket = "terraform-stashable"
    key    = "terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = "us-east-1"
}

module "frontend" {
  source = "../../modules/elastic-beanstalk"
  name   = var.name
  ec2_key_name = var.name
  domain_name            = var.domain_name
  domain_certificate_arn = var.domain_certificate_arn
  hosted_zone_id         = var.hosted_zone_id
}



