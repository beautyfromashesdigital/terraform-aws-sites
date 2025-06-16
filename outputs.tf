output "bucket_name" {
  value = aws_s3_bucket.site.bucket
}
output "cloudfront_id" {
  value = aws_cloudfront_distribution.cdn.id
}
output "zone_id" {
  value = aws_route53_zone.zone.zone_id
}
output "name_servers" {
  value = aws_route53_zone.zone.name_servers
}
output "validation_record_name" {
  description = "Name of the TXT record for ACM DNS validation"
  value       = aws_route53_record.cert_validation.name
}

output "validation_record_value" {
  description = "Value of the TXT record for ACM DNS validation"
  value       = aws_route53_record.cert_validation.records[0]
}