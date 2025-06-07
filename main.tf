terraform {
  required_providers {
    aws = {
        source = "hashicorp/aws"
        version = "~> 5.0"
    }
  }
}

################################################
# PROVIDERS
################################################
provider "aws" {
  region = var.aws_region
}
provider "aws" {
  alias  = "us_east"
  region = "us-east-1"
}


################################################
# S3 BUCKET (static hosting)
################################################
resource "aws_s3_bucket" "site" {
  bucket = var.domain
  acl    = "private"

  website {
    index_document = "index.html"
    error_document = "404.html"
  }
}

resource "aws_s3_bucket_policy" "site_policy" {
  bucket = aws_s3_bucket.site.id
  policy = data.aws_iam_policy_document.s3_policy.json
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

################################################
# CLOUDFRONT ORIGIN ACCESS IDENTITY
################################################
resource "aws_cloudfront_origin_access_identity" "oai" {
  comment = "OAI for ${var.domain}"
}

################################################
# ACM CERTIFICATE (us-east-1) + DNS VALIDATION
################################################
resource "aws_route53_zone" "zone" {
  name = var.domain
}

resource "aws_acm_certificate" "cert" {
  provider          = aws.us_east
  domain_name       = var.domain
  validation_method = "DNS"
}

resource "aws_route53_record" "cert_validation" {
  for_each = {
    for opt in aws_acm_certificate.cert.domain_validation_options :
    opt.domain_name => opt
  }
  zone_id = aws_route53_zone.zone.zone_id
  name    = each.value.resource_record_name
  type    = each.value.resource_record_type
  ttl     = 60
  records = [each.value.resource_record_value]
}

resource "aws_acm_certificate_validation" "cert_validation" {
  provider                = aws.us_east
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [aws_route53_record.cert_validation.fqdn]
}

################################################
# CLOUDFRONT DISTRIBUTION
################################################
resource "aws_cloudfront_distribution" "cdn" {
  enabled             = true
  default_root_object = "index.html"
  aliases             = [var.domain, "www.${var.domain}"]

  origin {
    origin_id   = "S3-${var.domain}"
    domain_name = aws_s3_bucket.site.website_endpoint

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
    }
  }

  default_cache_behavior {
    target_origin_id       = "S3-${var.domain}"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET","HEAD"]
    cached_methods         = ["GET","HEAD"]
  }

  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate_validation.cert_validation.certificate_arn
    ssl_support_method  = "sni-only"
  }
}

################################################
# ROUTE53 RECORDS
################################################
resource "aws_route53_record" "root_alias" {
  zone_id = aws_route53_zone.zone.zone_id
  name    = var.domain
  type    = "A"
  alias {
    name                   = aws_cloudfront_distribution.cdn.domain_name
    zone_id                = aws_cloudfront_distribution.cdn.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "www_cname" {
  zone_id = aws_route53_zone.zone.zone_id
  name    = "www"
  type    = "CNAME"
  ttl     = 300
  records = [var.domain]
}
