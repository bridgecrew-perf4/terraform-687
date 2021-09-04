variable "name" {
  type = string
}

variable "ec2_key_name" {
  type = string
}

variable "domain_name" {
  type        = string
  description = "The domain name of the static site."
}

variable "domain_certificate_arn" {
  type        = string
  description = "The ARN of the domain certificate."
}

variable "hosted_zone_id" {
  type        = string
  description = "The ID of the hosted zone for the domain certificate."
}