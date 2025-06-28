# S3 접근 모니터링 모듈

특정 S3 폴더에 대한 접근을 추적하는 S3 액세스 로그 모듈입니다.

## 기능

- **S3 액세스 로그**: 비용 효율적인 S3 기본 액세스 로그 활용
- **특정 폴더 모니터링**: `/profile` 폴더 접근만 추적
- **GET 요청 필터링**: Lambda로 GET 요청만 필터링하여 저장
- **일일 로그 병합**: 매일 새벽 2시에 전날 로그를 하나의 파일로 병합
- **스토리지 최적화**: 원본 로그 파일 삭제 옵션으로 비용 절감
- **같은 버킷 내 저장**: 별도 버킷 불필요

## 사용법

### 1. 독립 실행

```bash
cd modules/s3_access_monitoring

# terraform.tfvars 파일 수정
# target_s3_bucket = "your-data-bucket-name"

terraform init
terraform plan
terraform apply -auto-approve
```

### 2. 루트에서 모듈 호출

```hcl
module "s3_monitoring" {
  source = "./modules/s3_access_monitoring"
  
  target_s3_bucket = "your-data-bucket-name"
  monitor_folder   = "profile"  # 선택적
}
```

## 변수

| 변수명 | 설명 | 기본값 | 필수 |
|--------|------|--------|------|
| `region` | AWS 리전 | `ap-northeast-3` | ❌ |
| `target_s3_bucket` | 모니터링할 대상 S3 버킷 이름 | - | ✅ |
| `monitor_folder` | 모니터링할 폴더 경로 | `profile` | ❌ |

## 출력

| 출력명 | 설명 |
|--------|------|
| `target_bucket_name` | 모니터링 대상 S3 버킷 이름 |
| `log_prefix` | 로그 저장 경로 |
| `cloudwatch_log_group` | CloudWatch 로그 그룹 |

## 로그 저장 구조

### 원본 로그 파일 (AWS 자동 생성)
```
s3://{target_bucket}/profile/access-logs/{YYYY}/{MM}/{DD}/{HH}-{MM}-{SS}-{UNIQUE_ID}.log
```

### 필터링된 로그 파일 (Lambda 생성)
```
s3://{target_bucket}/profile/access-logs/{YYYY}/{MM}/{DD}/profile-get-only.log
```

예시:
```
# 원본 (삭제됨)
s3://myrecipe-bucket/profile/access-logs/2024/01/15/14-30-25-ABCD1234.log

# 필터링된 결과 (유지)
s3://myrecipe-bucket/profile/access-logs/2024/01/15/profile-get-only.log
```

## 로그 내용 예시

```
79a59df900b949e55d96a1e698fbacedfd6e09d98eacf8f8d5218e7cd47ef2be myrecipe-bucket [15/Jan/2024:14:30:25 +0000] 203.0.113.1 ... REST.GET.OBJECT profile/profile_2.png "GET /profile/profile_2.png HTTP/1.1" 200 - 425516 425516 - - "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
```

## 비용 최적화

- S3 액세스 로그: 무료 (기본 제공)
- CloudWatch Logs: 7일 보관으로 비용 최소화
- 별도 S3 버킷 불필요로 스토리지 비용 절감

## 예상 비용 (월)

- S3 액세스 로그: 무료
- CloudWatch Logs: 약 $0.50 (7일 보관 기준)
- S3 스토리지: 기존 버킷 사용으로 추가 비용 없음

## 주의사항

1. 대상 S3 버킷이 실제로 존재해야 합니다
2. S3 액세스 로그는 모든 S3 접근을 기록합니다
3. 로그 생성까지 1-2시간 소요될 수 있습니다
4. 특정 폴더만 필터링하려면 로그 분석 도구 사용 필요
5. 실시간 모니터링이 필요한 경우 CloudTrail 사용을 고려하세요

## 최종
cloudtrail_logs_bucket = "myre-bucket-profile-trail-logs"
cloudtrail_name = "myre-bucket-profile-access-trail"
monitored_path = "myre-bucket/profile/*"
target_bucket_name = "myre-bucket"


## 특정날짜의 모든 CloudTrail 로그 파일을 통합해서 다운로드하는 방법

1. 특정 날짜 로그 다운로드
./download_cloudtrail_logs.sh 2025/06/25

2. 오늘 로그 다운로드 (매개변수 없음)
./download_cloudtrail_logs.sh