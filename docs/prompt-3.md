Prompt 1, 2에서 만든 모델과 비즈니스 로직을 기반으로 FastAPI REST API를 app/api/ 하위에 구현해줘.

## 엔드포인트 설계

### /budget-cycles
- GET /budget-cycles/current — 현재 사이클 + 가용예산 + spend/billing summary 한번에 반환
- GET /budget-cycles/{id} — 특정 사이클 상세
- GET /budget-cycles — 사이클 목록 (페이지네이션)

### /incomes
- POST /incomes — 수입 등록 (salary 또는 extra)
- GET /incomes?cycle_id= — 사이클별 수입 목록
- PATCH /incomes/{id}/confirm — 월급 실제 입금액 정정 (salary_confirmation.confirm_salary 호출)
- GET /incomes/pending-confirmations — 정정 필요한 월급 목록

### /fixed-expenses
- CRUD 풀세트 (POST, GET 목록, GET 단건, PATCH, DELETE는 soft delete로 is_active=false)

### /cards
- CRUD 풀세트

### /transactions
- POST /transactions — 거래 등록 (payment_method가 card면 billing.calculate_billing_date 자동 호출해서 billing_date, billing_cycle_id 자동 계산)
- GET /transactions?cycle_id=&cycle_type=spend|billing — cycle_type에 따라 spend_cycle_id 또는 billing_cycle_id 기준으로 필터
- PATCH /transactions/{id}
- DELETE /transactions/{id}
- POST /transactions/{id}/receipt — MinIO에 영수증 이미지 업로드 (presigned URL 방식 사용)

## 요구사항
1. 모든 요청/응답은 Pydantic 스키마로 명확히 정의 (app/schemas/)
2. 에러 핸들링: 존재하지 않는 리소스는 404, 잘못된 입력은 422
3. DB 세션은 FastAPI Depends 패턴으로 주입
4. MinIO 연동은 boto3 또는 minio 패키지 사용, presigned URL 발급 방식으로 구현 (서버가 이미지 바이트를 직접 안 받고 클라이언트가 presigned URL로 직접 업로드)
5. OpenAPI 문서(/docs)에서 각 엔드포인트 설명과 예시가 잘 보이도록 docstring과 example 작성
6. 인증은 아직 구현하지 마 (다음 단계에서 별도로 진행 예정)

작성 후 httpx 기반 통합 테스트도 주요 시나리오별로 작성해줘:
- 카드로 거래 등록 시 billing_date가 올바르게 자동 계산되는지
- 월급 정정 후 가용예산이 재계산되는지
- spend vs billing 합계가 다르게 나오는 케이스 (카드 사용 시나리오)
