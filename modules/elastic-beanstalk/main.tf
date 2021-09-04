data "aws_availability_zones" "available" {
  state = "available"
}

module "vpc_prod" {
  source = "terraform-aws-modules/vpc/aws"

  name = "${var.name}-prod"
  cidr = "10.0.0.0/16"

  azs            = [data.aws_availability_zones.available.names[0], data.aws_availability_zones.available.names[1]]
  public_subnets = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_dns_hostnames = true
  enable_dns_support = true

  tags = {
    Terraform   = "true"
    Environment = "prod"
  }
}

resource "aws_security_group" "egress_all" {
  name        = "egress_all"
  description = "Allow all outbound traffic"
  vpc_id      = module.vpc_prod.vpc_id

  egress = [
    {
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
      description      = null
      prefix_list_ids  = null
      security_groups  = null
      self             = null
    }
  ]

  tags = {
    Name = "egress_all"
  }
}
resource "aws_security_group" "ingress_all" {
  name        = "ingress_all"
  description = "Allow all inbound traffic"
  vpc_id      = module.vpc_prod.vpc_id

  ingress = [
    {
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
      description      = null
      prefix_list_ids  = null
      security_groups  = null
      self             = null
    }
  ]

  tags = {
    Name = "ingress_all"
  }
}

resource "aws_s3_bucket" "deployments" {
  bucket = "${var.name}-ebs-deployments"
  acl    = "private"
}

resource "aws_efs_file_system" "prod" {
  tags = {
    Name = "${var.name}-prod"
  }
}

resource "aws_efs_mount_target" "az_1" {
  file_system_id = aws_efs_file_system.prod.id
  subnet_id      = module.vpc_prod.public_subnets[0]
  security_groups = [aws_security_group.ingress_all.id]
}

resource "aws_efs_mount_target" "az_2" {
  file_system_id = aws_efs_file_system.prod.id
  subnet_id      = module.vpc_prod.public_subnets[1]
  security_groups = [aws_security_group.ingress_all.id]
}

resource "aws_elastic_beanstalk_application" "default" {
  name = var.name
  appversion_lifecycle {
    service_role          = "arn:aws:iam::060074084645:role/aws-elasticbeanstalk-service-role"
    max_count             = 128
    delete_source_from_s3 = true
  }
}

resource "aws_elastic_beanstalk_environment" "prod" {
  name                = "${var.name}-prod"
  application         = aws_elastic_beanstalk_application.default.name
  solution_stack_name = "64bit Amazon Linux 2 v3.4.4 running Docker"
  setting {
    namespace = "aws:ec2:vpc"
    name      = "VPCId"
    value     = module.vpc_prod.vpc_id
  }
  setting {
    namespace = "aws:ec2:vpc"
    name      = "Subnets"
    value     = join(", ", [module.vpc_prod.public_subnets[0], module.vpc_prod.public_subnets[1]])
  }
  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "SecurityGroups"
    value     = join(", ", [aws_security_group.egress_all.id])
  }
  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = "aws-elasticbeanstalk-ec2-role"
  }
  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "InstanceType"
    value     = "t3a.small"
  }
  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "EC2KeyName"
    value     = "${var.ec2_key_name}"
  }
  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "EnvironmentType"
    value     = "SingleInstance"
  }
}



resource "aws_cloudfront_distribution" "default" {
  origin {
    domain_name = aws_elastic_beanstalk_environment.prod.cname
    origin_id   = var.domain_name
    custom_origin_config {
      http_port = 80
      https_port = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols = ["TLSv1.1", "TLSv1.2"]
    }
  }
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "/"
  aliases             = [var.domain_name]

  default_cache_behavior {
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD", "OPTIONS"]
    target_origin_id       = var.domain_name
    min_ttl                = 0
    default_ttl            = 0
    max_ttl                = 0

    forwarded_values {
      query_string = true
      headers = ["*"]
      cookies {
        forward = "all"
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = var.domain_certificate_arn
    minimum_protocol_version = "TLSv1.2_2019"
    ssl_support_method       = "sni-only"
  }
}

resource "aws_route53_record" "default" {
  zone_id = var.hosted_zone_id
  name    = var.domain_name
  type    = "A"
  alias {
    name                   = aws_cloudfront_distribution.default.domain_name
    zone_id                = aws_cloudfront_distribution.default.hosted_zone_id
    evaluate_target_health = false
  }
}