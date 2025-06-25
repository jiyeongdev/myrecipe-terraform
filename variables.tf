variable "asg_name" {
  description = "Auto Scaling Group Name"
  type        = string
}

variable "ecs_cluster" {
  description = "ECS Cluster Name"
  type        = string
}

variable "ecs_service" {
  description = "ECS Service Name"
  type        = string
}

variable "region" {
  default = "ap-northeast-3"
}


variable "scale_up_min_size" {
  default = 1
}

variable "scale_up_desired_capacity" {
  default = 1
}

variable "scale_up_max_size" {
  default = 2
}

variable "scale_up_ecs_count" {
  default = 1
}

variable "scale_down_cron" {
  default = "cron(0 17 * * ? *)" # 2AM KST
}

variable "scale_up_cron" {
  default = "cron(0 21 * * ? *)" # 6AM KST
}

variable "internal_alb_dns_name" {
  description = "Internal ALB DNS name (e.g. internal-my-alb-xxxx.ap-northeast-1.elb.amazonaws.com)"
  type        = string
}

variable "domain_name" {
  description = "CloudFront에 연결할 도메인 이름"
  type        = string
}

variable "acm_certificate_arn" {
  description = "ACM 인증서 ARN (us-east-1 리전에 있어야 함)"
  type        = string
}