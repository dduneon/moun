가계부 앱 백엔드의 DB 스키마를 설계하고 SQLAlchemy 모델 + Alembic 마이그레이션을 작성해줘.

## 핵심 설계 원칙
예산 주기는 "월급날(매월 21일) ~ 다음달 20일"을 한 사이클로 본다. 카드 결제는 "쓴 날(거래일)"과 "실제 청구되는 날(청구일, 보통 익월)"이 다르므로 이 둘을 분리 추적해야 한다.

## 테이블 설계

### budget_cycle (예산 사이클)
- id (PK)
- start_date, end_date (date) — 예: 2026-06-21 ~ 2026-07-20
- label (varchar) — 표시용, 예: "2026년 6월"
- salary_expected (decimal) — 예상 월급
- salary_actual (decimal, nullable) — 월급일에 정정된 실제 입금액
- created_at, updated_at

### income (수입)
- id (PK)
- type (enum: 'salary', 'extra')
- name (varchar) — '본급여', '프리랜싱' 등
- expected_amount (decimal, nullable) — salary 타입만 사용
- actual_amount (decimal, nullable) — 실제 입금액
- scheduled_day (int, nullable) — salary 타입만, 매월 며칠
- received_date (date, nullable)
- status (enum: 'pending', 'confirmed')
- budget_cycle_id (FK → budget_cycle, nullable)
- created_at, updated_at

### fixed_expense (고정 지출 — 구독료, 월세 등 매달 반복)
- id (PK)
- name (varchar)
- amount (decimal)
- payment_method (enum: 'card', 'cash', 'account')
- billing_day (int) — 매월 청구되는 날
- is_active (bool) — 해지 여부
- created_at, updated_at

### transaction (실제 소비 기록)
- id (PK)
- amount (decimal)
- category (varchar 또는 별도 category 테이블 FK — 둘 중 더 적합한 방식으로 설계)
- payment_method (enum: 'card', 'cash', 'account')
- transaction_date (date) — 실제 쓴 날
- billing_date (date) — 통장에서 실제 빠지는 날. card는 거래일+익월 특정일 등으로 계산되어 저장, cash/account는 transaction_date와 동일
- spend_cycle_id (FK → budget_cycle) — transaction_date 기준으로 속하는 사이클
- billing_cycle_id (FK → budget_cycle) — billing_date 기준으로 속하는 사이클
- memo (text, nullable)
- receipt_image_url (varchar, nullable) — MinIO 경로
- created_at, updated_at

### card (카드 정보 — 카드별 결제일이 다를 수 있으므로)
- id (PK)
- name (varchar) — '신한카드' 등
- statement_day (int) — 매월 결제일(청구일)
- is_active (bool)

transaction의 payment_method가 'card'인 경우 card_id FK도 추가해줘 (어느 카드인지 구분, billing_date 계산에 사용).

## 요청사항
1. 위 테이블들을 SQLAlchemy 2.0 스타일(Mapped, mapped_column)로 작성
2. 적절한 인덱스 추가 (특히 transaction의 spend_cycle_id, billing_cycle_id, transaction_date)
3. Alembic 마이그레이션 파일 생성
4. 모델 간 relationship 정의 (예: BudgetCycle.transactions, BudgetCycle.incomes)
5. 아직 API 엔드포인트는 만들지 마. 모델과 마이그레이션까지만.

설계가 끝나면 ERD를 텍스트(mermaid 문법)로도 같이 보여줘.
