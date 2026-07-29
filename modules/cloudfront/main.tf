# CloudFront Distribution for ARMAGEDDON

resource "aws_cloudfront_distribution" "armageddon_distribution" {
  enabled             = true
  comment             = "ARMAGEDDON CloudFront Distribution"
  default_root_object = "index.html"

  # Origin (S3)
  origin {
    domain_name = var.origin_domain_name
    origin_id   = "armageddon-s3-origin"

    s3_origin_config {
      origin_access_identity = var.origin_access_identity
    }
  }


  # Default Behavior

  default_cache_behavior {
    target_origin_id       = "armageddon-s3-origin"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD"]
    cached_methods  = ["GET", "HEAD"]

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 3600
    max_ttl     = 86400
  }

  # Required Restrictions Block
  
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }


  # Logging (optional)

  logging_config {
    bucket          = var.logging_bucket
    prefix          = "cloudfront/"
    include_cookies = false
  }

 
  # WAF Web ACL Association

  web_acl_id = var.waf_acl_arn

 
  # Price Class

  price_class = "PriceClass_100"


  # Viewer Certificate
  
  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = var.common_tags
}
