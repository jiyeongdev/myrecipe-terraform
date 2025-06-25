module "scheduler" {
  source = "./modules/autoscaling_scheduler"
  
  asg_name                = var.asg_name
  ecs_cluster             = var.ecs_cluster
  ecs_service             = var.ecs_service
  region                  = var.region
  scale_up_min_size       = var.scale_up_min_size
  scale_up_desired_capacity = var.scale_up_desired_capacity
  scale_up_max_size       = var.scale_up_max_size
  scale_up_ecs_count      = var.scale_up_ecs_count
  scale_down_cron         = var.scale_down_cron
  scale_up_cron           = var.scale_up_cron

}

module "alb_proxy" {
  source = "./modules/cloudfront_alb_proxy"
  region                = var.region
  #internal_alb_dns_name = var.internal_alb_dns_name
  #acm_certificate_arn   =var.acm_certificate_arn
}
