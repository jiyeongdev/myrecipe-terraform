#!/bin/bash

# CloudTrail 로그 통합 다운로드 스크립트
# 사용법: ./download_cloudtrail_logs.sh [날짜] 
# 예: ./download_cloudtrail_logs.sh 2025/06/25

# 기본 날짜 설정 (매개변수가 없으면 오늘 날짜 사용)
if [ -z "$1" ]; then
    TARGET_DATE=$(date +%Y/%m/%d)
else
    TARGET_DATE="$1"
fi

# 설정
BUCKET_NAME="myrecipe-bucket-profile-trail-logs"
ACCOUNT_ID="222634385502"
REGION="ap-northeast-3"
DATE_FOLDER=$(echo $TARGET_DATE | tr '/' '_')  # 2025_06_25 형태로 변경

echo "🚀 CloudTrail 로그 다운로드 시작"
echo "📅 대상 날짜: $TARGET_DATE"
echo "🪣 버킷: $BUCKET_NAME"
echo "📂 작업 폴더: cloudtrail_logs_$DATE_FOLDER"
echo "----------------------------------------"

# 작업 디렉토리 생성
mkdir -p "cloudtrail_logs_$DATE_FOLDER"
cd "cloudtrail_logs_$DATE_FOLDER"

# S3 경로 설정
S3_PATH="s3://$BUCKET_NAME/AWSLogs/$ACCOUNT_ID/CloudTrail/$REGION/$TARGET_DATE/"

# 해당 날짜의 모든 로그 파일 다운로드
echo "📥 CloudTrail 로그 파일 다운로드 중..."
aws s3 sync "$S3_PATH" . --region "$REGION"

# 다운로드된 파일 확인
if [ ! "$(ls -A .)" ]; then
    echo "❌ 해당 날짜($TARGET_DATE)에 로그 파일이 없습니다."
    echo "💡 CloudTrail 로그는 보통 5-15분 후에 생성됩니다."
    cd ..
    rmdir "cloudtrail_logs_$DATE_FOLDER"
    exit 1
fi

echo "📦 압축 해제 중..."
# 모든 .gz 파일 압축 해제
for file in *.gz; do
    if [ -f "$file" ]; then
        echo "  - 압축 해제: $file"
        gunzip "$file"
    fi
done

echo "🔄 JSON 파일 통합 중..."
# 모든 JSON 파일을 하나로 통합 (Records 배열 병합)
{
    echo '{"Records":['
    first_file=true
    for file in *.json; do
        if [ -f "$file" ] && [ "$file" != "combined_logs.json" ] && [ "$file" != "s3_events_only.json" ]; then
            if [ "$first_file" = true ]; then
                jq -c '.Records[]' "$file"
                first_file=false
            else
                echo ','
                jq -c '.Records[]' "$file"
            fi
        fi
    done
    echo ']}'
} > combined_logs.json

echo "🎯 S3 이벤트만 추출 중..."
# S3 이벤트만 필터링
jq '.Records[] | select(.eventSource == "s3.amazonaws.com")' combined_logs.json > s3_events_only.json

# /profile 경로 접근만 필터링
echo "📁 /profile 경로 접근만 추출 중..."
jq '.Records[] | select(.eventSource == "s3.amazonaws.com" and (.resources[]?.ARN? // "" | contains("/profile/")))' combined_logs.json > profile_access_only.json

echo "✅ 완료!"
echo "----------------------------------------"
echo "📁 생성된 파일:"
ls -la *.json
echo ""
echo "📊 통계:"
echo "  - 전체 이벤트: $(jq '.Records | length' combined_logs.json 2>/dev/null || echo "0")"
echo "  - S3 이벤트: $(jq -s 'length' s3_events_only.json 2>/dev/null || echo "0")"
echo "  - /profile 접근: $(jq -s 'length' profile_access_only.json 2>/dev/null || echo "0")"
echo ""
echo "🔍 S3 이벤트 미리보기:"
jq -r '.[] | "\(.eventTime) \(.eventName) \(.sourceIPAddress) \(.resources[0].ARN // "N/A")"' s3_events_only.json 2>/dev/null | head -5

cd ..
echo "🎉 로그 분석 완료! 결과는 cloudtrail_logs_$DATE_FOLDER 폴더에 저장되었습니다." 