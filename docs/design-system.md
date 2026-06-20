# 모운 디자인 시스템

Apple Liquid Glass(iOS 18/26) 스타일을 참고한 밝고 세련된 글래스모피즘 디자인.  
"밝고 화사하면서도 고급스러운" 톤을 유지하고, 그림자와 블러를 과하지 않게 사용해 무겁지 않은 느낌을 목표로 한다.

---

## 1. 컬러

**파일:** `lib/core/theme/app_colors.dart`

| 토큰 | 값 | 용도 |
|---|---|---|
| `primary` | `#5B8DEF` | 메인 브랜드 컬러 (소프트 블루) |
| `primaryGradientEnd` | `#7C6FF0` | 그라데이션 끝 (인디고) |
| `backgroundStart` | `#F7F8FC` | 앱 배경 그라데이션 시작 |
| `backgroundEnd` | `#FFFFFF` | 앱 배경 그라데이션 끝 |
| `surfaceGlass` | `#FFFFFF 70%` | 글래스 카드 배경 |
| `surfaceGlassBorder` | `#FFFFFF 30%` | 글래스 카드 테두리 |
| `income` | `#34C77B` | 수입 (초록) |
| `expense` | `#FF6B6B` | 지출 (빨강) |
| `expensePending` | `#B39DFF` | 청구 예정 (보라) |
| `textPrimary` | `#1C1C1E` | 본문 텍스트 |
| `textSecondary` | `#8E8E93` | 보조 텍스트 |
| `divider` | `rgba(0,0,0,0.06)` | 구분선 |

라이트/다크 `ColorScheme` 모두 정의되어 있으며, `AppTheme.light` / `AppTheme.dark`로 바로 사용 가능하다.

---

## 2. 타이포그래피

**파일:** `lib/core/theme/app_typography.dart`  
**폰트:** Pretendard Variable (`assets/fonts/PretendardVariable.ttf`)

| 스타일 | 크기 | 굵기 | 용도 |
|---|---|---|---|
| `displayLarge` | 40sp | 700 | 대형 금액 표시 |
| `displayMedium` | 32sp | 700 | — |
| `headlineLarge` | 24sp | 700 | 페이지 타이틀 |
| `headlineMedium` | 20sp | 600 | 섹션 타이틀 |
| `titleLarge` | 16sp | 600 | 카드 타이틀 |
| `bodyLarge` | 16sp | 400 | 본문 |
| `bodyMedium` | 14sp | 400 | 본문 보조 |
| `labelSmall` | 11sp | 400 | 캡션, 날짜, 메타 |

금액 전용 스타일은 `AppTypography.amountLarge/Medium/Small`로 별도 제공.

---

## 3. 스페이싱

**파일:** `lib/core/theme/app_spacing.dart`

```
xs  =  4px
sm  =  8px
md  = 12px
lg  = 16px
xl  = 24px
xxl = 32px
```

---

## 4. 보더 라디우스

**파일:** `lib/core/theme/app_radius.dart`

| 토큰 | 값 | 용도 |
|---|---|---|
| `card` | 22 | GlassCard |
| `button` | 14 | 버튼, 입력창 |
| `chip` | 8 | 칩, 배지 |
| `navbar` | 999 | 플로팅 탭바 (완전 타원) |

---

## 5. 컴포넌트

### GlassCard
**파일:** `lib/shared/widgets/glass_card.dart`

```dart
GlassCard(
  child: Text('내용'),
)
```

- `BackdropFilter` blur 20 적용
- 배경: `surfaceGlass` (white 70%), 테두리: `surfaceGlassBorder` (white 30%) 1px
- 그림자: blurRadius 24, opacity 8%
- `padding`, `borderRadius`, `sigmaBlur` 커스터마이즈 가능

---

### GlassFloatingNavbar
**파일:** `lib/shared/widgets/glass_floating_navbar.dart`

```dart
GlassFloatingNavbar(
  currentIndex: _tab,
  onTap: (i) => setState(() => _tab = i),
)
```

- 화면 하단 좌우 16px, 하단 24px 마진으로 띄워서 배치
- 5탭 기본값 (홈 / 거래 / + / 통계 / 설정)
- 중앙 + 버튼: primary 그라데이션 원형으로 강조
- 선택된 탭: 아이콘 + 라벨 (AnimatedSize), 비선택: 아이콘만

---

### AmountDisplay
**파일:** `lib/shared/widgets/amount_display.dart`

```dart
AmountDisplay(
  amount: -12000,   // 양수=수입(+초록), 음수=지출(-빨강)
  size: AmountSize.medium,
  animate: true,    // 0에서 카운트업 애니메이션
)

LabeledAmount(label: '지출', amount: -12000)
```

- 부호 자동 부여: `+42만원` / `-1만2천원`
- 색상 자동 적용: 수입=`income`, 지출=`expense`, 0=`textPrimary`
- `FittedBox`로 줄바꿈 없이 축소
- 카운트업 애니메이션 옵션

---

### AppButton
**파일:** `lib/shared/widgets/app_button.dart`

```dart
AppButton(label: '저장하기', onPressed: () {})
AppButton(label: '취소', onPressed: () {}, variant: AppButtonVariant.secondary)
AppButton(label: '삭제', onPressed: () {}, variant: AppButtonVariant.danger)
AppButton(label: '닫기', onPressed: () {}, variant: AppButtonVariant.ghost)
AppButton(label: '로딩', onPressed: null, loading: true)
```

| Variant | 스타일 |
|---|---|
| `primary` | primary→primaryGradientEnd 그라데이션, 흰 텍스트 |
| `secondary` | primary 아웃라인 |
| `ghost` | 텍스트만, 회색 |
| `danger` | expense(빨강) 배경 |

---

### AppTextField / AmountTextField
**파일:** `lib/shared/widgets/app_text_field.dart`

```dart
AppTextField(label: '메모', hint: '거래 내용 입력')
AppTextField(label: '비밀번호', obscureText: true)  // 눈 아이콘 토글 포함
AmountTextField(label: '금액', onChanged: (int v) {})  // 천단위 콤마 자동
```

---

### SelectionChipGroup / TransactionTypeToggle
**파일:** `lib/shared/widgets/selection_chip.dart`

```dart
// 기간 필터 칩
SelectionChipGroup<String>(
  items: ['이번 달', '3개월', '6개월'],
  labelOf: (s) => s,
  selected: _selected,
  onSelected: (v) => setState(() => _selected = v),
)

// 수입/지출 슬라이딩 탭
TransactionTypeToggle(
  isExpense: _isExpense,
  onChanged: (v) => setState(() => _isExpense = v),
)
```

`TransactionTypeToggle`은 `AnimatedPositioned`로 흰 thumb가 슬라이딩.

---

### CategorySelector
**파일:** `lib/shared/widgets/category_selector.dart`

```dart
// 인라인 그리드
CategoryGrid(
  items: defaultExpenseCategories,
  selectedId: _category?.id,
  onSelected: (c) => setState(() => _category = c),
)

// 탭 → 바텀시트
CategoryPickerField(
  selected: _category,
  onSelected: (c) => setState(() => _category = c),
)

// 직접 호출
final result = await CategorySelectorSheet.show(context);
```

기본 카테고리: `defaultExpenseCategories` (식비/교통/쇼핑 등 10종), `defaultIncomeCategories` (급여/부업/투자 등 4종)

---

### AppBottomSheet / AppConfirmDialog
**파일:** `lib/shared/widgets/app_bottom_sheet.dart`

```dart
// 바텀시트
AppBottomSheet.show(
  context,
  title: '거래 추가',
  child: MyFormWidget(),
);

// 확인 다이얼로그 (bool 반환)
final ok = await AppConfirmDialog.show(
  context,
  title: '삭제',
  message: '삭제하면 되돌릴 수 없어요.',
  confirmLabel: '삭제',
  isDestructive: true,
);
```

둘 다 `BackdropFilter` 글래스 효과 적용.

---

### MounCalendar
**파일:** `lib/shared/widgets/moun_calendar.dart`

```dart
MounCalendar(
  data: {
    DateTime(2025, 6, 3): DayData(expense: 65000),
    DateTime(2025, 6, 1): DayData(income: 4200000),
    DateTime(2025, 6, 12): DayData(expense: 88000, hasPending: true),
  },
  onDayTap: (day) { /* 거래 내역 바텀시트 등 */ },
  onMonthChanged: (month) { /* API 재요청 */ },
)
```

- 날짜 셀에 `+42만` / `-7만` 인라인 표시
- 청구 예정: 보라 점(●)
- 오늘: primary 테두리, 선택된 날: primary 배경
- 미래 월 이동 비활성

---

### DayTransactionSheet
**파일:** `lib/shared/widgets/transaction_list.dart`

```dart
DayTransactionSheet.show(
  context,
  day: selectedDay,
  transactions: txList,   // List<TransactionItem>
  onEdit: (t) { /* 편집 */ },
  onDelete: (t) { /* 삭제 */ },
);
```

---

## 6. 차트

**파일:** `lib/shared/widgets/charts/`

```dart
// 카테고리 도넛 (터치 인터랙션 + 범례)
CategoryDonutChart(items: [...])

// 월별 수입/지출 바 차트
MonthlyBarChart(data: [...])

// 일별 지출 라인 (예산선 포함)
SpendingLineChart(points: [...], budgetLimit: 2000000)

// 이번달 vs 지난달 비교 라인
CompareLineChart(series: [...])
```

---

## 7. 전체 구조

```
lib/
├── core/
│   └── theme/
│       ├── app_colors.dart       # 컬러 토큰 + ColorScheme
│       ├── app_typography.dart   # Pretendard TextTheme
│       ├── app_spacing.dart      # 스페이싱 상수
│       ├── app_radius.dart       # 라디우스 상수
│       └── app_theme.dart        # ThemeData (light/dark)
│
└── shared/widgets/
    ├── glass_card.dart
    ├── glass_floating_navbar.dart
    ├── gradient_background.dart
    ├── amount_display.dart
    ├── app_button.dart
    ├── app_text_field.dart
    ├── app_bottom_sheet.dart
    ├── selection_chip.dart
    ├── category_selector.dart
    ├── moun_calendar.dart
    ├── transaction_list.dart
    └── charts/
        ├── category_donut_chart.dart
        ├── monthly_bar_chart.dart
        └── spending_line_chart.dart
```

---

## 8. 쇼케이스

`lib/features/_design_showcase/showcase_screen.dart`

`main.dart`에서 `_showDesignShowcase = true`로 설정하면 모든 컴포넌트를 한 화면에서 미리보기 가능.  
실제 앱으로 전환 시 `false`로 변경.
