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

variable "index_document" {
  type        = string
  default     = "index.html"
  description = "The document to serve."
}
