variable "profile_bucket_name" {
  description = "익명 접근용 S3 버킷 이름 (존재하지 않으면 새로 생성)"
  type        = string
  default     = "profile"
}

variable "image_folder" {
  description = "익명 접근을 허용할 이미지 폴더 경로"
  type        = string
  default     = "image"
}

variable "log_prefix" {
  description = "Access Log 파일의 접두사"
  type        = string
  default     = "access-log"
}

variable "log_retention_days" {
  description = "Access Log 보관 기간 (일)"
  type        = number
  default     = 30
}

variable "aws_region" {
  description = "AWS 리전"
  type        = string
  default     = "ap-northeast-3"
}

variable "upload_sample_files" {
  description = "샘플 파일을 업로드할지 여부"
  type        = bool
  default     = false
}

variable "tags" {
  description = "리소스에 적용할 태그"
  type        = map(string)
  default = {
    Environment = "dev"
    Purpose     = "anonymous-access-logging"
  }
} 