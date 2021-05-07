terraform {
  backend "s3" {
    bucket = "tf-npaz-backups"
    key    = "terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "backups" {
  bucket = "npaz-backups"
  acl    = "private"

  versioning {
    enabled = true
  }
}
