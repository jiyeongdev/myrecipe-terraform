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
  description = "AWS 리전"
  type        = string
}

variable "scale_up_min_size" {
  description = "Scale Up 시 최소 인스턴스 수"
  type        = number
  default     = 1
}

variable "scale_up_desired_capacity" {
  description = "Scale Up 시 원하는 인스턴스 수"
  type        = number
  default     = 1
}

variable "scale_up_max_size" {
  description = "Scale Up 시 최대 인스턴스 수"
  type        = number
  default     = 2
}

variable "scale_up_ecs_count" {
  description = "Scale Up 시 ECS 태스크 수"
  type        = number
  default     = 1
}

variable "scale_down_cron" {
  description = "Scale Down 스케줄 (Cron 표현식)"
  type        = string
  default     = "cron(0 17 * * ? *)"  # 2AM KST
}

variable "scale_up_cron" {
  description = "Scale Up 스케줄 (Cron 표현식)"
  type        = string
  default     = "cron(0 21 * * ? *)"  # 6AM KST
} 