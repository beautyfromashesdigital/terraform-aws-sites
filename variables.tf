variable "domain" {
  description = "Custom domain to host"
  type        = string
}

variable "aws_region" {
  description = "AWS region for static site"
  type        = string
  default     = "us-east-1"
}

variable "use_route53" {
  description = "Whether to manage Route 53 zone and DNS records automatically"
  type        = bool
  default     = true
}
