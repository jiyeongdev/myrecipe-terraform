#!/bin/bash

# 자동 버킷 체크 및 Terraform 적용 스크립트
# 사용법: ./check_and_apply.sh [버킷명] [리전]

# 기본값 설정
BUCKET_NAME=${1:-"my-profile-datas"}
REGION=${2:-"ap-northeast-3"}

echo "🔍 S3 버킷 자동 체크 및 Terraform 적용"
echo "📋 버킷명: $BUCKET_NAME"
echo "🌏 리전: $REGION"
echo "----------------------------------------"

# 기존 버킷 존재 여부 확인 (정보 제공용)
echo "📦 기존 버킷 존재 여부 확인 중..."
if aws s3api head-bucket --bucket "$BUCKET_NAME" --region "$REGION" 2>/dev/null; then
    echo "✅ 기존 버킷 발견: $BUCKET_NAME (Terraform이 자동으로 감지하여 사용)"
    BUCKET_STATUS="existing"
else
    echo "❌ 기존 버킷 없음: $BUCKET_NAME (Terraform이 새 버킷 생성)"
    BUCKET_STATUS="new"
fi

echo ""
echo "⚙️ Terraform 변수 설정 중..."

# terraform.tfvars 업데이트
cat > terraform.tfvars << EOF
# S3 익명 접근 로깅 모듈 설정 (자동 생성됨)

# 기본 버킷 설정 (자동으로 기존 버킷 감지 후 처리)
profile_bucket_name = "$BUCKET_NAME"
image_folder        = "image"
log_prefix          = "access-log"

# 로그 보관 설정
log_retention_days = 30

# AWS 설정
aws_region = "$REGION"

# 샘플 파일 업로드 (테스트용)
upload_sample_files = false

# 태그 설정
tags = {
  Environment = "dev"
  Purpose     = "anonymous-access-logging"
  Module      = "s3_profile_access_log"
  CreatedBy   = "check_and_apply_script"
}
EOF

echo "✅ terraform.tfvars 업데이트 완료"
echo ""

# Terraform 실행
echo "🚀 Terraform 실행 중..."
echo "----------------------------------------"

# 초기화
echo "1️⃣ terraform init"
terraform init

if [ $? -ne 0 ]; then
    echo "❌ terraform init 실패"
    exit 1
fi

echo ""
echo "2️⃣ terraform plan"
terraform plan

if [ $? -ne 0 ]; then
    echo "❌ terraform plan 실패"
    exit 1
fi

echo ""
echo "🤔 계속 진행하시겠습니까? (y/n)"
read -r CONTINUE

if [[ $CONTINUE =~ ^[Yy]$ ]]; then
    echo "3️⃣ terraform apply"
    terraform apply -auto-approve
    
    if [ $? -eq 0 ]; then
        echo ""
        echo "🎉 Terraform 적용 완료!"
        echo "----------------------------------------"
        echo "📊 생성된 리소스 정보:"
        
        if [ "$BUCKET_STATUS" = "existing" ]; then
            echo "  🔄 기존 버킷 사용: $BUCKET_NAME"
        else
            echo "  🆕 새 버킷 생성: $BUCKET_NAME"
        fi
        
        echo "  📁 로그 버킷: $BUCKET_NAME-access-logs"
        echo "  🌐 익명 접근 URL: https://$BUCKET_NAME.s3.$REGION.amazonaws.com/image/"
        echo "  📋 로그 위치: s3://$BUCKET_NAME-access-logs/access-log/"
        
        echo ""
        echo "📝 다음 단계:"
        echo "  1. 이미지 업로드: aws s3 cp your-image.png s3://$BUCKET_NAME/image/"
        echo "  2. 익명 접근 테스트: https://$BUCKET_NAME.s3.$REGION.amazonaws.com/image/your-image.png"
        echo "  3. 로그 분석: ./analyze_access_logs.sh"
        
    else
        echo "❌ Terraform 적용 실패"
        exit 1
    fi
else
    echo "🛑 Terraform 적용 취소"
fi

echo ""
echo "✨ 스크립트 완료!" 