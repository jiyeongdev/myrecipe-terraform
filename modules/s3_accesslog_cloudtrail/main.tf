# S3 특정 폴더 GET 접근 추적 모듈
# CloudTrail 데이터 이벤트를 사용한 효율적 모니터링

############################
# 1. CloudTrail용 S3 버킷 (로그 저장용)
############################
resource "aws_s3_bucket" "cloudtrail_logs" {
  bucket = "${var.target_s3_bucket}-profile-trail-logs"
}

resource "aws_s3_bucket_versioning" "cloudtrail_logs_versioning" {
  bucket = aws_s3_bucket.cloudtrail_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail_logs_encryption" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

############################
# 2. CloudTrail IAM 역할
############################
resource "aws_iam_role" "cloudtrail_role" {
  name = "${var.target_s3_bucket}-profile-trail-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "cloudtrail_logs_policy" {
  name = "${var.target_s3_bucket}-profile-trail-policy"
  role = aws_iam_role.cloudtrail_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetBucketAcl",
          "s3:PutBucketAcl"
        ]
        Resource = [
          aws_s3_bucket.cloudtrail_logs.arn,
          "${aws_s3_bucket.cloudtrail_logs.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "logs:PutLogEvents",
          "logs:CreateLogGroup",
          "logs:CreateLogStream"
        ]
        Resource = "${aws_cloudwatch_log_group.profile_access_logs.arn}:*"
      }
    ]
  })
}

############################
# 3. CloudTrail - /profile GET 요청만 추적
############################
resource "aws_cloudtrail" "profile_access_trail" {
  name           = "${var.target_s3_bucket}-profile-access-trail"
  s3_bucket_name = aws_s3_bucket.cloudtrail_logs.bucket # 로그 저장 버킷

  # 관리 이벤트는 비활성화 (비용 절약)
  include_global_service_events = false
  is_multi_region_trail        = false
  enable_logging               = true

  # 데이터 이벤트 - /profile 폴더의 GET 요청만
  event_selector {
    read_write_type                 = "ReadOnly"
    include_management_events       = false
    exclude_management_event_sources = []

    data_resource {
      type   = "AWS::S3::Object"
      values = ["arn:aws:s3:::${var.target_s3_bucket}/${var.monitor_folder}/*"]
    }
  }

  depends_on = [aws_iam_role_policy.cloudtrail_logs_policy]
}

############################
# 4. S3 버킷 정책 - CloudTrail 권한
############################
resource "aws_s3_bucket_policy" "cloudtrail_bucket_policy" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSCloudTrailAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.cloudtrail_logs.arn
      },
      {
        Sid    = "AWSCloudTrailWrite"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.cloudtrail_logs.arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

############################
# 5. CloudWatch Logs (선택적 - 실시간 모니터링)
############################
resource "aws_cloudwatch_log_group" "profile_access_logs" {
  name              = "/aws/cloudtrail/${var.target_s3_bucket}-profile-access"
  retention_in_days = 7  # 7일 보관 (비용 절감)
}

# CloudTrail을 CloudWatch Logs에도 전송 (선택적)
resource "aws_cloudtrail" "profile_access_trail_cw" {
  count = var.enable_cloudwatch_logs ? 1 : 0
  
  name           = "${var.target_s3_bucket}-profile-trail-cw"
  s3_bucket_name = aws_s3_bucket.cloudtrail_logs.bucket
  
  cloud_watch_logs_group_arn = "${aws_cloudwatch_log_group.profile_access_logs.arn}:*"
  cloud_watch_logs_role_arn  = aws_iam_role.cloudtrail_role.arn

  event_selector {
    read_write_type                 = "ReadOnly"
    include_management_events       = false
    exclude_management_event_sources = []

    data_resource {
      type   = "AWS::S3::Object"
      values = ["arn:aws:s3:::${var.target_s3_bucket}/${var.monitor_folder}/*"]
    }
  }
}

############################
# 6. 출력값
############################
output "target_bucket_name" {
  description = "모니터링 대상 S3 버킷 이름"
  value       = var.target_s3_bucket
}

output "cloudtrail_name" {
  description = "CloudTrail 이름"
  value       = aws_cloudtrail.profile_access_trail.name
}

output "cloudtrail_logs_bucket" {
  description = "CloudTrail 로그 저장 버킷"
  value       = aws_s3_bucket.cloudtrail_logs.bucket
}

output "monitored_path" {
  description = "모니터링 경로"
  value       = "${var.target_s3_bucket}/${var.monitor_folder}/*"
} 