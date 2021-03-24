terraform {
  backend "s3" {
    bucket = "terraform-react-boids"
    key    = "terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = "us-east-1"
}

module "frontend" {
  source                 = "../../modules/s3-frontend"
  domain_name            = "boids.nickpaz.com"
  domain_certificate_arn = "arn:aws:acm:us-east-1:060074084645:certificate/4b6877fe-49ea-4ca6-98d4-30d5500743f7"
  hosted_zone_id         = "Z03949441Z4HA0AXZLD7G"
}
