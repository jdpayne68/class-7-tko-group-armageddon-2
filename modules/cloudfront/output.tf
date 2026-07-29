output "cloudfront_distribution_id" {
  value = aws_cloudfront_distribution.armageddon_distribution.id
}

output "cloudfront_domain_name" {
  value = aws_cloudfront_distribution.armageddon_distribution.domain_name
}
