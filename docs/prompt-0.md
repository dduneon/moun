FastAPI 백엔드와 Flutter 프론트엔드로 구성된 가계부 앱 "moun"(모운) 프로젝트를 시작하려 해.

## 서비스 정보
- 서비스명(한글): 모운
- 서비스명(영문): moun
- 패키지 ID: com.dduneon.moun

모노레포 구조로 아래처럼 셋업해줘:

money-app/
├── backend/
└── frontend/

## backend/
- FastAPI 프로젝트 초기 구조 (app/models, app/schemas, app/api, app/core, app/db 디렉토리)
- SQLAlchemy 2.0 + Alembic 마이그레이션 셋업
- pydantic-settings 기반 설정 관리 (.env 사용)
  - app/core/config.py의 Settings 클래스에 APP_NAME = "모운" 추가
  - .env.example에 APP_NAME=모운 추가
- main.py에서 FastAPI(title=settings.APP_NAME, ...) 형태로 메타데이터 반영
- docker-compose.yml: MariaDB, Redis, MinIO 3개 서비스 정의 (로컬 개발용, 볼륨 마운트 포함)
  - 컨테이너명, 볼륨명 등에 moun 접두사 사용 (예: moun-mariadb, moun-redis, moun-minio)
- requirements.txt 또는 pyproject.toml (uv 사용 추천)
- Python 버전은 3.12 사용

## frontend/
- Flutter 프로젝트 초기화, 프로젝트명은 moun으로 (flutter create --org com.dduneon moun)
- 패키지/번들 ID 설정:
  - Android: applicationId를 com.dduneon.moun으로 설정 (android/app/build.gradle)
  - iOS: Bundle Identifier를 com.dduneon.moun으로 설정 (ios/Runner.xcodeproj 또는 Info.plist 연동 설정)
- 앱 표시 이름(기기 홈화면)을 "모운"으로 설정:
  - android/app/src/main/AndroidManifest.xml의 android:label="모운"
  - ios/Runner/Info.plist의 CFBundleDisplayName을 "모운"으로
- lib/core/constants/app_constants.dart에 const String appName = '모운'; 정의 (UI 내부 텍스트에서 참조용)
- 상태관리는 riverpod, 네트워킹은 dio 패키지 추가
- lib/ 하위에 features/, core/, shared/ 폴더 구조만 잡아두기 (빈 구조)

지금은 실제 비즈니스 로직 구현은 하지 말고, 두 프로젝트가 각각 정상 실행되는 상태(backend는 /health 엔드포인트가 {"app": "모운", "status": "ok"} 형태로 응답, frontend는 기본 화면에 "모운" 타이틀 표시)까지만 만들어줘.
