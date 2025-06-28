# S3 익명 접근 모니터링 모듈
# S3 Access Logging을 사용한 익명 접근 추적

############################
# 1. 기존 버킷 자동 감지 및 조건부 생성
############################

# 먼저 새 버킷 생성을 시도하고, 실패하면 기존 버킷 사용
resource "aws_s3_bucket" "profile_bucket" {
  bucket = var.profile_bucket_name

  lifecycle {
    # 버킷이 이미 존재하는 경우 에러를 무시하고 기존 버킷 참조
    ignore_changes = [bucket]
  }
}

# 버킷 생성 성공 여부 체크 및 기존 버킷 fallback
data "aws_s3_bucket" "profile_bucket_fallback" {
  bucket = var.profile_bucket_name
  
  depends_on = [aws_s3_bucket.profile_bucket]
}

# 사용할 버킷을 로컬 변수로 정의
locals {
  profile_bucket_id  = data.aws_s3_bucket.profile_bucket_fallback.id
  profile_bucket_arn = data.aws_s3_bucket.profile_bucket_fallback.arn
  bucket_was_created = try(aws_s3_bucket.profile_bucket.id, "") != ""
}

# 버킷 버전 관리 (새로 생성된 버킷에만 적용)
resource "aws_s3_bucket_versioning" "profile_bucket_versioning" {
  count  = local.bucket_was_created ? 1 : 0
  bucket = local.profile_bucket_id
  versioning_configuration {
    status = "Enabled"
  }
}

# 서버 사이드 암호화 (새로 생성된 버킷에만 적용)
resource "aws_s3_bucket_server_side_encryption_configuration" "profile_bucket_encryption" {
  count  = local.bucket_was_created ? 1 : 0
  bucket = local.profile_bucket_id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# 퍼블릭 액세스 블록 설정 (새로 생성된 버킷에만 적용)
resource "aws_s3_bucket_public_access_block" "profile_bucket_pab" {
  count  = local.bucket_was_created ? 1 : 0
  bucket = local.profile_bucket_id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# 익명 읽기 허용 버킷 정책 (항상 적용)
resource "aws_s3_bucket_policy" "profile_bucket_policy" {
  bucket = local.profile_bucket_id
  depends_on = local.bucket_was_created ? [aws_s3_bucket_public_access_block.profile_bucket_pab[0]] : []

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${local.profile_bucket_arn}/${var.image_folder}/*"
      }
    ]
  })
}

############################
# 2. Access Logging용 S3 버킷
############################
resource "aws_s3_bucket" "access_logs_bucket" {
  bucket = "${var.profile_bucket_name}-access-logs"
}

# 로그 버킷 버전 관리
resource "aws_s3_bucket_versioning" "access_logs_bucket_versioning" {
  bucket = aws_s3_bucket.access_logs_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# 로그 버킷 암호화
resource "aws_s3_bucket_server_side_encryption_configuration" "access_logs_bucket_encryption" {
  bucket = aws_s3_bucket.access_logs_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# 로그 버킷 라이프사이클 (비용 절약)
resource "aws_s3_bucket_lifecycle_configuration" "access_logs_lifecycle" {
  bucket = aws_s3_bucket.access_logs_bucket.id

  rule {
    id     = "delete_old_logs"
    status = "Enabled"

    expiration {
      days = var.log_retention_days
    }

    noncurrent_version_expiration {
      noncurrent_days = 7
    }
  }
}

############################
# 3. S3 Access Logging 설정
############################
resource "aws_s3_bucket_logging" "profile_bucket_logging" {
  bucket = local.profile_bucket_id

  target_bucket = aws_s3_bucket.access_logs_bucket.id
  target_prefix = "${var.log_prefix}/"
}

############################
# 4. 샘플 README 파일 업로드 (선택적)
############################
resource "aws_s3_object" "sample_readme" {
  count = var.upload_sample_files ? 1 : 0

  bucket = local.profile_bucket_id
  key    = "${var.image_folder}/README.txt"
  content = <<-EOF
이 폴더는 익명 접근이 가능한 이미지 파일들이 저장되는 곳입니다.

접근 URL 형식:
https://${var.profile_bucket_name}.s3.${var.aws_region}.amazonaws.com/${var.image_folder}/파일명

예시 (파일 업로드 후):
https://${var.profile_bucket_name}.s3.${var.aws_region}.amazonaws.com/${var.image_folder}/your-image.png

모든 접근 로그는 ${aws_s3_bucket.access_logs_bucket.id} 버킷의 ${var.log_prefix}/ 폴더에 저장됩니다.

파일 업로드 방법:
aws s3 cp your-image.png s3://${var.profile_bucket_name}/${var.image_folder}/ --region ${var.aws_region}
  EOF

  content_type = "text/plain"

  depends_on = [aws_s3_bucket_policy.profile_bucket_policy]
} 