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

variable "scale_down_cron" {
  default = "cron(0 17 * * ? *)" # 2AM KST
}

variable "scale_up_cron" {
  default = "cron(0 21 * * ? *)" # 6AM KST
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
