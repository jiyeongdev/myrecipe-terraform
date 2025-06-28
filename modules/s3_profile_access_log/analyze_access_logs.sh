#!/bin/bash

# S3 Access Log 분석 스크립트
# 사용법: ./analyze_access_logs.sh [날짜] 
# 예: ./analyze_access_logs.sh 2025-06-26

# 기본 설정
LOG_BUCKET="profile-access-logs"
LOG_PREFIX="access-log"
REGION="ap-northeast-3"

# 날짜 설정 (매개변수가 없으면 오늘 날짜 사용)
if [ -z "$1" ]; then
    TARGET_DATE=$(date +%Y-%m-%d)
else
    TARGET_DATE="$1"
fi

WORK_DIR="access_logs_analysis_$TARGET_DATE"

echo "🚀 S3 Access Log 분석 시작"
echo "📅 분석 날짜: $TARGET_DATE"
echo "🪣 로그 버킷: $LOG_BUCKET"
echo "📂 작업 폴더: $WORK_DIR"
echo "----------------------------------------"

# 작업 디렉토리 생성
mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

# S3에서 로그 파일 다운로드
echo "📥 Access Log 파일 다운로드 중..."
aws s3 sync "s3://$LOG_BUCKET/$LOG_PREFIX/" . --region "$REGION" --exclude "*" --include "*$TARGET_DATE*"

# 다운로드된 파일 확인
if [ ! "$(ls -A .)" ]; then
    echo "❌ 해당 날짜($TARGET_DATE)에 로그 파일이 없습니다."
    echo "💡 S3 Access Log는 보통 2-24시간 후에 생성됩니다."
    cd ..
    rmdir "$WORK_DIR"
    exit 1
fi

echo "📦 다운로드된 로그 파일:"
ls -la *.log 2>/dev/null || ls -la *

echo ""
echo "📊 로그 분석 시작..."

# 1. 전체 요청 수
echo "🔢 전체 요청 수:"
cat *.log 2>/dev/null | wc -l

echo ""
echo "🌐 IP별 요청 통계 (상위 10개):"
cat *.log 2>/dev/null | awk '{print $3}' | sort | uniq -c | sort -nr | head -10

echo ""
echo "📁 요청된 파일 통계 (상위 10개):"
cat *.log 2>/dev/null | grep -E "REST\.GET\.OBJECT" | awk '{print $7}' | sort | uniq -c | sort -nr | head -10

echo ""
echo "🌍 User Agent 통계 (상위 5개):"
cat *.log 2>/dev/null | awk -F'"' '{print $6}' | sort | uniq -c | sort -nr | head -5

echo ""
echo "⏰ 시간대별 요청 통계:"
cat *.log 2>/dev/null | awk '{print $4}' | cut -d':' -f2 | sort | uniq -c | sort -k2n

echo ""
echo "📈 HTTP 상태 코드 통계:"
cat *.log 2>/dev/null | awk '{print $9}' | sort | uniq -c | sort -nr

echo ""
echo "🎯 /image 폴더 접근만 필터링:"
cat *.log 2>/dev/null | grep "image/" | wc -l
echo "개의 /image 폴더 접근 요청"

echo ""
echo "📋 /image 폴더 접근 상세 (최근 10개):"
cat *.log 2>/dev/null | grep "image/" | tail -10 | while read line; do
    IP=$(echo "$line" | awk '{print $3}')
    TIME=$(echo "$line" | awk '{print $4 " " $5}')
    FILE=$(echo "$line" | awk '{print $7}')
    STATUS=$(echo "$line" | awk '{print $9}')
    echo "  $TIME | $IP | $STATUS | $FILE"
done

echo ""
echo "🔍 익명 접근 분석 (인증 정보가 '-'인 요청):"
cat *.log 2>/dev/null | awk '$4 == "-"' | wc -l
echo "개의 익명 요청"

# CSV 파일로 요약 저장
echo ""
echo "💾 분석 결과를 CSV로 저장 중..."
{
    echo "timestamp,ip,method,file,status_code,user_agent"
    cat *.log 2>/dev/null | grep "image/" | while IFS= read -r line; do
        TIMESTAMP=$(echo "$line" | awk '{print $4}' | tr -d '[]')
        IP=$(echo "$line" | awk '{print $3}')
        METHOD=$(echo "$line" | awk '{print $6}')
        FILE=$(echo "$line" | awk '{print $7}')
        STATUS=$(echo "$line" | awk '{print $9}')
        USER_AGENT=$(echo "$line" | awk -F'"' '{print $6}' | tr ',' ';')
        echo "$TIMESTAMP,$IP,$METHOD,$FILE,$STATUS,$USER_AGENT"
    done
} > "image_access_summary_$TARGET_DATE.csv"

echo "✅ 분석 완료!"
echo "----------------------------------------"
echo "📁 생성된 파일:"
ls -la *.csv *.log 2>/dev/null | head -10
echo ""
echo "📊 요약 CSV 파일: image_access_summary_$TARGET_DATE.csv"
echo "🎉 분석 결과는 $WORK_DIR 폴더에 저장되었습니다."

cd ..
echo "🔍 상세 분석을 위해 다음 명령어를 사용하세요:"
echo "cd $WORK_DIR && cat image_access_summary_$TARGET_DATE.csv" 