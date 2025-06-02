variable "domain" {
  description = "Custom domain to host"
  type        = string
}
variable "aws_region" {
  description = "AWS region for static site"
  type        = string
  default     = "us-east-1"
}
