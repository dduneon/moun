// 카테고리 이름으로 수입/저축/시스템 카테고리를 구분하기 위한 공통 상수.
// 백엔드 Category에는 type이 없어 이름 매칭으로 구분한다 (add_transaction_sheet,
// fixed_expense_screen, fixed_income_screen에서 공유).
const incomeCategoryNames = {'급여', '부업', '투자', '기타수입'};
const savingCategoryNames = {'저축', '적금', '예금', '주식'};
// 자동 생성되는 시스템 카테고리 — 카테고리 피커에서 항상 제외
const systemCategoryNames = {'고정지출', '수입', '고정저축', '상품권 충전'};
