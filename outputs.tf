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
