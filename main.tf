terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

####################################
# Providers
####################################
provider "aws" {
  region = var.aws_region
}

provider "aws" {
  alias  = "us_east"
  region = "us-east-1"
}

####################################
# S3 Bucket + Policy
####################################
resource "aws_s3_bucket" "site" {
  bucket = var.domain
  acl    = "private"

  website {
    index_document = "index.html"
    error_document = "404.html"
  }
}

resource "aws_cloudfront_origin_access_identity" "oai" {
  comment = "OAI for ${var.domain}"
}

data "aws_iam_policy_document" "s3_policy" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.site.arn}/*"]
    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.oai.iam_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "site_policy" {
  bucket = aws_s3_bucket.site.id
  policy = data.aws_iam_policy_document.s3_policy.json
}

####################################
# Route 53 Hosted Zone (optional)
####################################
resource "aws_route53_zone" "zone" {
  count = var.use_route53 ? 1 : 0
  name  = var.domain
}

####################################
# ACM Certificate + DNS validation
####################################
resource "aws_acm_certificate" "cert" {
  provider          = aws.us_east
  domain_name       = var.domain
  validation_method = "DNS"
}

locals {
  dvo = tolist(aws_acm_certificate.cert.domain_validation_options)[0]
}

resource "aws_route53_record" "cert_validation" {
  count   = var.use_route53 ? 1 : 0
  zone_id = aws_route53_zone.zone[0].zone_id
  name    = local.dvo.resource_record_name
  type    = local.dvo.resource_record_type
  ttl     = 60
  records = [local.dvo.resource_record_value]
}

resource "aws_acm_certificate_validation" "cert_validation" {
  provider                = aws.us_east
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = var.use_route53 ? [aws_route53_record.cert_validation[0].fqdn] : []
}

####################################
# CloudFront Distribution
####################################
resource "aws_cloudfront_distribution" "cdn" {
  enabled             = true
  default_root_object = "index.html"
  aliases             = [var.domain, "www.${var.domain}"]

  origin {
    origin_id   = "S3-${var.domain}"
    domain_name = aws_s3_bucket.site.bucket_regional_domain_name  # ✅ Correct for OAI

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
    }
  }

  default_cache_behavior {
    target_origin_id       = "S3-${var.domain}"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate_validation.cert_validation.certificate_arn
    ssl_support_method  = "sni-only"
  }
}

####################################
# Route 53 Records (optional)
####################################
resource "aws_route53_record" "root_alias" {
  count   = var.use_route53 ? 1 : 0
  zone_id = aws_route53_zone.zone[0].zone_id
  name    = var.domain
  type    = "A"
  alias {
    name                   = aws_cloudfront_distribution.cdn.domain_name
    zone_id                = aws_cloudfront_distribution.cdn.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "www_cname" {
  count   = var.use_route53 ? 1 : 0
  zone_id = aws_route53_zone.zone[0].zone_id
  name    = "www"
  type    = "CNAME"
  ttl     = 300
  records = [var.domain]
}
