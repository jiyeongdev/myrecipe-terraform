# provider는 루트 모듈에서 설정하는 걸 권장합니다 (region 등)

# 1. CloudFront Origin Access Identity (OAI) - S3 전용이므로, ALB에선 안 써도 됨

# 2. CloudFront Distribution 생성 (Internal ALB를 Origin으로 지정)

resource "aws_cloudfront_distribution" "alb_proxy" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "CloudFront proxy for Internal ALB"
  default_root_object = ""

  origin {
    domain_name = var.internal_alb_dns_name
    origin_id   = "internal-alb-origin"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"  # ALB가 https 지원 시
      origin_ssl_protocols   = ["TLSv1.2"]  # TLSv1.3 제거
    }
  }

  default_cache_behavior {
    target_origin_id       = "internal-alb-origin"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods  = ["GET", "HEAD", "OPTIONS"]

    forwarded_values {
      query_string = true
      headers      = ["Host", "Authorization"]  # 필요한 헤더 추가 가능
      cookies {
        forward = "all"
      }
    }

    min_ttl                = 0
    default_ttl            = 60
    max_ttl                = 300
  }

  price_class = "PriceClass_200"  # 아시아 지역 엣지 로케이션 포함

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
    
    #도메인 연결 설정
    #acm_certificate_arn      = var.acm_certificate_arn
    #ssl_support_method       = "sni-only"
    #minimum_protocol_version = "TLSv1.2_2021"
  }

  #aliases = [var.domain_name]
}

# CloudFront 배포의 도메인 이름을 출력
#output "cloudfront_domain_name" {
#  value = aws_cloudfront_distribution.alb_proxy.domain_name
#}

# CloudFront 배포의 호스팅 영역 ID를 출력
#output "cloudfront_hosted_zone_id" {
#  value = aws_cloudfront_distribution.alb_proxy.hosted_zone_id
#}
