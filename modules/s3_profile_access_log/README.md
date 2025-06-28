# S3 Profile Access Logging Module

익명 접근이 가능한 S3 버킷과 Access Logging을 설정하는 Terraform 모듈입니다.

## 📋 기능

- ✅ **익명 접근 허용**: `/image` 폴더의 파일들에 대한 익명 읽기 허용
- ✅ **S3 Access Logging**: 모든 요청(익명 포함)을 별도 버킷에 로그 저장
- ✅ **보안 설정**: 최소 권한 원칙 적용
- ✅ **비용 최적화**: 로그 자동 삭제 설정
- ✅ **암호화**: 모든 버킷 서버 사이드 암호화 적용

## 🏗️ 생성되는 리소스

### 메인 S3 버킷 (`profile`)
- 익명 읽기 접근 허용 (`/image/*` 경로만)
- 버전 관리 활성화
- 서버 사이드 암호화 (AES256)

### Access Logs S3 버킷 (`profile-access-logs`)
- Access Log 저장용
- 30일 후 자동 삭제
- 서버 사이드 암호화

## 🚀 사용법

### 1. 모듈 적용

```bash
# 모듈 디렉토리로 이동
cd modules/s3_profile_access_log

# Terraform 초기화
terraform init

# 계획 확인
terraform plan

# 리소스 생성
terraform apply -auto-approve
```

### 2. 파일 업로드

```bash
# 이미지 파일 업로드
aws s3 cp your-image.png s3://profile/image/ --region ap-northeast-3

# 업로드 확인
aws s3 ls s3://profile/image/ --region ap-northeast-3
```

### 3. 익명 접근 테스트

```bash
# 익명 접근 URL 형식
https://profile.s3.ap-northeast-3.amazonaws.com/image/your-image.png

# 브라우저에서 직접 접근 가능
curl https://profile.s3.ap-northeast-3.amazonaws.com/image/your-image.png
```

### 4. Access Log 확인

```bash
# Access Log 확인 (5-10분 후 생성됨)
aws s3 ls s3://profile-access-logs/access-log/ --region ap-northeast-3

# 로그 파일 다운로드
aws s3 cp s3://profile-access-logs/access-log/[로그파일명] ./ --region ap-northeast-3
```

## 📊 Access Log 형식

```
79a59df900b949e55d96a1e698fbacedfd6e09d98eacf8f8d5218e7cd47ef2be profile [06/Feb/2019:00:00:38 +0000] 192.0.2.3 - 3E57427F3EXAMPLE REST.GET.OBJECT image/sample.png "GET /image/sample.png HTTP/1.1" 200 - 2434 2434 5 4 "-" "Mozilla/5.0" - 7SeGYQpxl8d3+E73IFcCpNaB2OjHInHk3KaJEWjEhCyGkFHQ12CXGqaKDV3fP2i7gVsOVSLLW= SigV4 ECDHE-RSA-AES128-GCM-SHA256 AuthHeader profile.s3.amazonaws.com TLSv1.2
```

주요 필드:
- `192.0.2.3`: 클라이언트 IP
- `REST.GET.OBJECT`: 요청 타입
- `image/sample.png`: 요청된 객체
- `200`: HTTP 상태 코드
- `Mozilla/5.0`: User Agent

## ⚙️ 설정 변수

| 변수명 | 설명 | 기본값 | 타입 |
|--------|------|--------|------|
| `profile_bucket_name` | 메인 버킷 이름 | `"profile"` | string |
| `image_folder` | 익명 접근 허용 폴더 | `"image"` | string |
| `log_prefix` | Access Log 접두사 | `"access-log"` | string |
| `log_retention_days` | 로그 보관 기간 | `30` | number |
| `aws_region` | AWS 리전 | `"ap-northeast-3"` | string |
| `upload_sample_files` | 샘플 파일 업로드 | `false` | bool |

## 📤 출력값

- `profile_bucket_name`: 생성된 버킷 이름
- `access_logs_bucket_name`: 로그 버킷 이름
- `public_image_url_base`: 익명 접근 URL 베이스
- `access_log_location`: 로그 저장 위치

## 🔒 보안 고려사항

1. **최소 권한**: `/image` 폴더만 익명 읽기 허용
2. **암호화**: 모든 데이터 서버 사이드 암호화
3. **로그 관리**: 30일 후 자동 삭제로 비용 절감
4. **버전 관리**: 실수로 삭제된 파일 복구 가능

## 🚨 주의사항

- ⚠️ **익명 접근**: `/image` 폴더의 모든 파일이 인터넷에 공개됩니다
- ⚠️ **비용**: Access Logging 활성화 시 스토리지 비용 발생
- ⚠️ **지연**: Access Log는 5-10분 후에 생성됩니다
- ⚠️ **로그 형식**: S3 Access Log는 고정 형식으로만 제공됩니다

## 🎯 사용 예시

### 이미지 호스팅 서비스
```bash
# 프로필 이미지 업로드
aws s3 cp profile.jpg s3://profile/image/ --region ap-northeast-3

# 웹사이트에서 사용
<img src="https://profile.s3.ap-northeast-3.amazonaws.com/image/profile.jpg">
```

### 익명 접근 모니터링
```bash
# 로그 분석 (IP별 접근 통계)
aws s3 cp s3://profile-access-logs/access-log/ ./ --recursive
grep "GET" *.log | awk '{print $3}' | sort | uniq -c | sort -nr
```

## 🧹 정리

```bash
# 리소스 삭제
terraform destroy -auto-approve

# 버킷 수동 정리 (필요시)
aws s3 rm s3://profile --recursive
aws s3 rm s3://profile-access-logs --recursive
``` 