resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name = aws_s3_bucket.bucket.bucket_regional_domain_name
    origin_id   = aws_s3_bucket.bucket.id

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.origin_access_identity.cloudfront_access_identity_path
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  aliases = var.environment == "" ? split(",", "${var.domain},www.${var.domain}") : ["${var.environment}.${var.domain}"]

  default_cache_behavior {
    allowed_methods  = var.allowed_methods
    cached_methods   = var.allowed_methods
    target_origin_id = aws_s3_bucket.bucket.id
    compress         = true

    forwarded_values {
      query_string = true
      cookies {
        forward = "none"
      }
      headers = ["Origin", "Access-Control-Request-Headers", "Accept-Encoding", "Access-Control-Request-Method", "user-agent"]
    }
    lambda_function_association {
      event_type = "origin-response"
      lambda_arn = "${aws_lambda_function.hsts_protection.arn}:${aws_lambda_function.hsts_protection.version}"
    }
    dynamic "lambda_function_association" {
      for_each = var.basic_auth ? [1] : []
      content {
        event_type = "viewer-request"
        lambda_arn = "${aws_lambda_function.auth.0.arn}:${aws_lambda_function.auth.0.version}"
      }
    }
    dynamic "lambda_function_association" {
      for_each = var.enable_prerender ? [1] : []
      content {
        event_type = "origin-request"
        lambda_arn = "${aws_lambda_function.prerender.0.arn}:${aws_lambda_function.prerender.0.version}"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  tags = {
    Environment = "${var.environment}"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  viewer_certificate {
    acm_certificate_arn      = "arn:aws:acm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:certificate/${var.certificate_id}"
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2018"
  }
  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/index.html"
  }
  custom_error_response {
    error_code         = 403
    response_code      = 200
    response_page_path = "/index.html"
  }
}
