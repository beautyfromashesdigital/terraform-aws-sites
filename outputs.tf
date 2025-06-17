output "bucket_name" {
  value = aws_s3_bucket.site.bucket
}

output "cloudfront_id" {
  value = aws_cloudfront_distribution.cdn.id
}

output "cloudfront_domain_name" {
  value = aws_cloudfront_distribution.cdn.domain_name
}

output "validation_record_names" {
  value = [for dvo in local.dvos : dvo.resource_record_name]
}

output "validation_record_types" {
  value = [for dvo in local.dvos : dvo.resource_record_type]
}

output "validation_record_values" {
  value = [for dvo in local.dvos : dvo.resource_record_value]
}

output "zone_name_servers" {
  value = var.use_route53 ? data.aws_route53_zone.zone[0].name_servers : []
}
