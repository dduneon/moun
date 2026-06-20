가계부 앱을 멀티유저로 전환해줘. 각 사용자는 자신의 데이터만 볼 수 있어야 하고, 여러 기기(모바일 앱)에서 로그인해서 동일한 데이터에 접근할 수 있어야 한다.

## 1. User 테이블 추가 (app/models/user.py)
- id (PK)
- email (varchar, unique)
- hashed_password (varchar)
- name (varchar)
- created_at, updated_at
- is_active (bool)

## 2. 기존 테이블에 user_id 추가 및 격리
Prompt 1에서 만든 아래 테이블 전부에 user_id (FK → user, not null) 컬럼 추가하고 Alembic 마이그레이션 작성:
- budget_cycle
- income
- fixed_expense
- transaction
- card

기존 모델의 unique 제약조건(있다면)도 user_id 기준으로 범위를 재조정 해줘 (예: budget_cycle의 start_date~end_date 겹침 방지는 user_id 단위로).

## 3. 인증 구현 (app/core/auth.py, app/api/auth.py)
- JWT 기반 인증 (access token + refresh token 방식)
- access token 만료는 짧게(예: 30분~1시간), refresh token으로 갱신
- 비밀번호 해싱은 passlib(bcrypt) 또는 argon2 사용
- 엔드포인트:
  - POST /auth/register — 이메일/비밀번호/이름으로 가입
  - POST /auth/login — 이메일/비밀번호로 로그인, access+refresh token 발급
  - POST /auth/refresh — refresh token으로 access token 재발급
  - POST /auth/logout — refresh token 무효화 (Redis에 블랙리스트 또는 저장된 refresh token 삭제)
  - GET /auth/me — 현재 로그인한 사용자 정보 조회

refresh token은 Redis에 저장해서 멀티 디바이스 로그인을 지원해줘 (한 유저가 여러 기기에서 동시 로그인 가능해야 하므로, key를 user_id+device_id 또는 token 자체의 jti로 관리하는 방식으로 설계)

## 4. 기존 API 전체에 인증 적용
Prompt 3에서 만든 /budget-cycles, /incomes, /fixed-expenses, /cards, /transactions 모든 엔드포인트에:
- FastAPI Depends로 현재 로그인 사용자(get_current_user) 주입
- 모든 쿼리에 자동으로 user_id 필터링 적용 (다른 유저 데이터 접근 시 404 반환, 403이 아니라 404로 — 데이터 존재 여부 자체를 숨기기 위함)
- 본인 소유가 아닌 리소스에 대한 PATCH/DELETE 시도는 명확히 차단 및 테스트 코드로 검증

## 5. 보안 체크리스트 반영
- 비밀번호는 절대 평문 저장/로깅 금지
- 로그인 실패 시 "이메일 또는 비밀번호가 올바르지 않습니다" 같은 일반화된 메시지 사용 (이메일 존재 여부 추측 방지)
- rate limiting을 /auth/login에 적용 (Redis 기반, 예: 동일 IP 5회 실패 시 일정시간 차단)

## 6. 테스트
- 회원가입 → 로그인 → 인증이 필요한 API 호출 전체 플로우 통합 테스트
- A 유저가 B 유저의 transaction id로 접근 시 404 반환되는지 테스트
- refresh token으로 멀티 디바이스 로그인 시나리오 테스트 (기기1 로그인 상태에서 기기2 로그인해도 기기1 세션 유지되는지)
