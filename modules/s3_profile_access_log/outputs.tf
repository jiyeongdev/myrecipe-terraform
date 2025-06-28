output "profile_bucket_name" {
  description = "사용 중인 프로필 버킷 이름"
  value       = local.profile_bucket_id
}

output "profile_bucket_arn" {
  description = "프로필 버킷 ARN"
  value       = local.profile_bucket_arn
}

output "access_logs_bucket_name" {
  description = "Access Logs 저장 버킷 이름"
  value       = aws_s3_bucket.access_logs_bucket.id
}

output "access_logs_bucket_arn" {
  description = "Access Logs 버킷 ARN"
  value       = aws_s3_bucket.access_logs_bucket.arn
}

output "public_image_url_base" {
  description = "익명 접근 가능한 이미지 URL 베이스"
  value       = "https://${local.profile_bucket_id}.s3.${var.aws_region}.amazonaws.com/${var.image_folder}/"
}

output "sample_readme_url" {
  description = "샘플 README URL (업로드된 경우)"
  value       = var.upload_sample_files ? "https://${local.profile_bucket_id}.s3.${var.aws_region}.amazonaws.com/${var.image_folder}/README.txt" : null
}

output "access_log_location" {
  description = "Access Log가 저장되는 S3 위치"
  value       = "s3://${aws_s3_bucket.access_logs_bucket.id}/${var.log_prefix}/"
}

output "bucket_policy" {
  description = "적용된 익명 접근 정책"
  value = {
    bucket   = local.profile_bucket_id
    folder   = var.image_folder
    action   = "s3:GetObject"
    effect   = "Allow"
    principal = "*"
  }
}

output "bucket_creation_mode" {
  description = "버킷 생성 모드 (existing: 기존 버킷 사용, new: 새 버킷 생성)"
  value       = local.bucket_was_created ? "new" : "existing"
} 