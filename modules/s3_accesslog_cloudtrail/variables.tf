variable "region" {
  description = "AWS 리전"
  type        = string
  default     = "ap-northeast-3"
}

variable "target_s3_bucket" {
  description = "모니터링할 대상 S3 버킷 이름"
  type        = string
}

variable "monitor_folder" {
  description = "모니터링할 S3 폴더 경로 (기본값: profile)"
  type        = string
  default     = "profile"
}

variable "monitor_read_only" {
  description = "읽기 작업만 추적할지 여부 (CloudTrail ReadOnly)"
  type        = bool
  default     = true
}

variable "enable_cloudwatch_logs" {
  description = "CloudWatch Logs 실시간 모니터링 활성화 여부 (추가 비용 발생)"
  type        = bool
  default     = false
}

 