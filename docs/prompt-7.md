Prompt 6에서 만든 디자인 시스템(GlassCard, GlassFloatingNavbar, AmountDisplay, GradientBackground 등)을 사용해서 moun 앱의 메인 대시보드 화면을 구현해줘.

## 화면 구조 (lib/features/dashboard/)

상단부터 아래 순서로 배치:

### 1. 상단 헤더
- 인사말 텍스트 ("안녕하세요, {이름}님" — 지금은 더미 데이터 사용)
- 우측 알림 아이콘 (둥근 글래스 버튼 형태)
- 좌우 패딩 적용, SafeArea 고려

### 2. 월급 정정 배너 (조건부 노출)
- 21일이 지났는데 해당 사이클 월급이 'pending' 상태일 때만 노출되는 dismissible 카드
- "이번달 월급, 실제로 얼마 들어왔나요?" 텍스트 + "정정하기" 버튼
- X 버튼으로 닫기 가능 (닫으면 로컬 상태로만 숨김, 다음 앱 실행 시 다시 노출되거나 설정에서 재확인 가능하도록 구조 설계)
- 닫기/정정하기 둘 다 지금은 callback만 연결 (실제 API 연동은 다음 단계)

### 3. 가용 예산 Hero 카드 (가장 중요, 화면에서 가장 크게)
- GlassCard 사용, primary 그라데이션 느낌의 배경 강조 (다른 카드보다 톤 살짝 다르게)
- "이번 사이클 가용 예산" 라벨
- 큰 금액 (AmountDisplay, displayLarge 스타일, 카운트업 애니메이션)
- 사이클 기간 표시 ("6/21 ~ 7/20")
- 프로그레스 바 (사용한 비율, custom painted 또는 LinearProgressIndicator 커스터마이징, primary 그라데이션 색상)
- 진행률 텍스트 ("62% 사용")

### 4. spend vs billing 요약 (2개 카드, 가로 배치)
- 좌: "이번달 소비" 카드 — spend_cycle 기준 합계, 보조 설명 텍스트 "지금까지 실제로 쓴 금액"
- 우: "청구 예정" 카드 — billing_cycle 기준 합계, 보조 설명 텍스트 "카드값은 다음달에 청구돼요"
- 두 카드는 명확히 다른 색 강조 (income/expense 컬러와 별개로, expense vs expensePending 토큰 사용)
- 각 카드 탭하면 해당 상세 내역으로 이동 (지금은 콜백만, 실제 네비게이션은 라우팅 설정 후)

### 5. 카테고리별 소비 도넛 차트
- fl_chart의 PieChart 사용, 도넛 형태(center space 활용)
- 카테고리별 색상은 자동 생성 또는 사전 정의된 팔레트 사용
- 차트 중앙에 총 소비액 텍스트
- 하단에 카테고리 범례 (색상 dot + 이름 + 금액 + 퍼센트)

### 6. 최근 거래 내역 리스트
- 섹션 타이틀 "최근 거래" + "전체보기" 텍스트 버튼 (우측 정렬)
- 각 거래 아이템: 카테고리 아이콘(원형 배경) + 거래명 + 날짜(작은 텍스트) + 금액(AmountDisplay, income/expense 컬러)
- 카드가 아닌 리스트 형태로, 항목 간 구분은 옅은 divider 또는 충분한 spacing으로
- 최대 5개만 표시

### 7. 하단 GlassFloatingNavbar
- Prompt 6에서 만든 컴포넌트 그대로 사용, 홈 탭 활성화 상태

## 데이터
지금은 백엔드 연동 없이 더미 데이터(mock data)로 화면을 완성해줘. lib/features/dashboard/data/dashboard_mock_data.dart 에 더미 데이터를 정의하고, 나중에 실제 API 응답으로 교체하기 쉽도록 데이터 모델(freezed 또는 일반 dart class)을 먼저 설계한 뒤 그 모델 형태에 맞춰 mock 데이터를 작성해줘.

## 상태관리
riverpod의 Provider로 dashboard 상태를 관리하되, 지금은 mock data provider로 구성 (나중에 API 연동 시 provider 내부 구현만 교체하면 되도록 구조화).

## 인터랙션 디테일
- 전체 화면 스크롤 시 상단 헤더가 자연스럽게 줄어들거나 블러가 진해지는 효과는 선택사항으로 적용 (시간 되면)
- pull-to-refresh 제스처 지원 (RefreshIndicator, 지금은 mock data reload만)
- 각 카드는 화면 진입 시 순차적으로 fade-in + slide-up 애니메이션 (flutter_animate의 staggered animation 활용, 너무 느리지 않게 각 200ms 이내)

전체적으로 Prompt 6의 디자인 토큰과 컴포넌트를 최대한 재사용하고, 새로운 색상이나 스타일을 임의로 추가하지 말고 기존 토큰 체계 안에서 해결해줘.
