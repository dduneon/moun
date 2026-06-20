가계부 앱의 핵심 비즈니스 로직을 app/core/ 하위에 구현해줘. Prompt 1에서 만든 모델을 사용한다.

## 1. 예산 사이클 관리 (app/core/budget_cycle.py)
- get_or_create_current_cycle(): 오늘 날짜 기준으로 현재 속하는 budget_cycle을 반환. 없으면 생성 (21일 시작 ~ 익월 20일 종료 규칙)
- get_cycle_for_date(date): 특정 날짜가 속하는 사이클 계산 (이미 DB에 있으면 조회, 없으면 생성)
- 월말/월초 경계, 윤년 등 엣지케이스 테스트 케이스도 같이 작성

## 2. 카드 청구일 계산 (app/core/billing.py)
- calculate_billing_date(transaction_date, card): 카드의 statement_day를 기준으로 실제 청구일 계산.
  - 규칙: 카드사 일반적인 방식 참고해서 구현 (예: 매월 1일~말일 이용분 → 익월 statement_day에 청구되는 방식을 기본값으로 하되, 카드별로 이용기간 기준일이 다를 수 있다는 점 고려)
  - cash/account 결제는 transaction_date == billing_date

## 3. 가용 예산 계산 (app/core/budget_calculator.py)
다음달 가용 예산 = 
    해당 사이클.salary_actual (없으면 salary_expected) 
    + 해당 사이클에 속한 extra income 합계
    - 해당 사이클에 billing_day가 속하는 fixed_expense 합계
    - 해당 사이클에 billing_cycle_id가 속하는 transaction 합계

다음 함수들을 구현해줘:
- get_available_budget(cycle_id): 위 계산식으로 가용 예산 반환
- get_spend_summary(cycle_id): spend_cycle_id 기준 이번달 실제 소비 현황 (카테고리별 합계 포함) — "내가 얼마 썼는지" 패턴 파악용
- get_billing_summary(cycle_id): billing_cycle_id 기준 이번달 실제 청구/차감 현황 — "통장에서 얼마 빠지는지" 파악용

두 지표(spend vs billing)의 차이를 API 응답에서도 명확히 구분해서 반환하도록 Pydantic 스키마도 함께 설계해줘.

## 4. 월급 정정 로직 (app/core/salary_confirmation.py)
- confirm_salary(cycle_id, actual_amount): salary_actual 업데이트, status를 confirmed로 변경
- 월급일(scheduled_day)이 지났는데 아직 status가 pending인 income이 있으면 알림 대상으로 조회하는 함수 get_pending_salary_confirmations()도 작성 (실제 푸시 발송은 이번 단계에서 구현 안 해도 됨, 대상 조회 로직만)

pytest 테스트 코드도 각 모듈별로 작성해줘. 특히 예산 사이클 경계값(21일 당일, 20일 23:59, 월말 등)과 카드 청구일 계산 케이스를 꼼꼼히 다뤄줘.
