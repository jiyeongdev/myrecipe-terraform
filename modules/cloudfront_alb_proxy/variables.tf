variable "internal_alb_dns_name" {
  description = "Internal ALB의 DNS 이름"
  type        = string
}

variable "region" {
  description = "AWS 리전"
  type        = string
}

variable "acm_certificate_arn" {
  description = "ACM 인증서 ARN (us-east-1 리전에 있어야 함)"
  type        = string
  default     = null  # 선택적 변수로 설정
} 