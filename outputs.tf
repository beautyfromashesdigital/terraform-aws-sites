output "bucket_name" {
  value = aws_s3_bucket.site.bucket
}

output "cloudfront_id" {
  value = aws_cloudfront_distribution.cdn.id
}

output "cloudfront_domain_name" {
  value = aws_cloudfront_distribution.cdn.domain_name
}

output "validation_record_name" {
  value = local.dvo.resource_record_name
}

output "validation_record_type" {
  value = local.dvo.resource_record_type
}

output "validation_record_value" {
  value = local.dvo.resource_record_value
}

output "zone_name_servers" {
  value = var.use_route53 ? aws_route53_zone.zone[0].name_servers : []
}
