Flutter 앱 "moun"(모운)의 디자인 시스템을 구축해줘. Apple의 Liquid Glass 스타일(iOS 18/26 계열)을 참고한 밝고 세련된 글래스모피즘 디자인으로 간다.

## 1. 디자인 토큰 (lib/core/theme/)

### app_colors.dart

primary: #5B8DEF (소프트 블루)
primaryGradientEnd: #7C6FF0 (인디고, 그라데이션용)
background: #F7F8FC ~ #FFFFFF (subtle gradient)
surfaceGlass: Colors.white.withOpacity(0.7)
surfaceGlassBorder: Colors.white.withOpacity(0.3)
income: #34C77B
expense: #FF6B6B
expensePending: #B39DFF (청구 예정 등 보조 지표용, income/expense와 명확히 구분되는 톤)
textPrimary: #1C1C1E
textSecondary: #8E8E93
divider: rgba(0,0,0,0.06)

다크모드 대비 컬러도 함께 정의해줘 (지금 바로 다크모드 구현은 안 해도 되지만, ColorScheme 구조는 미리 잡아둘 것).

### app_typography.dart
- Pretendard 폰트 적용 (google_fonts 패키지 또는 assets/fonts에 직접 추가하는 방식 중 더 적합한 걸로, 한글 지원 확실히 되는지 확인)
- TextTheme 전체 정의: displayLarge(큰 금액 표시용, 36~40sp bold), headlineMedium(섹션 타이틀), bodyLarge/Medium(본문), labelSmall(보조 캡션)
- 금액 표시 전용 스타일을 별도로 분리 (예: AmountTextStyle — 천단위 콤마, 통화기호 처리 고려)

### app_spacing.dart
- 4/8/12/16/24/32 기반 spacing scale (const 값들)

### app_radius.dart
- 카드 radius: 20~24
- 버튼 radius: 12~16
- 플로팅 탭바 radius: 999 (완전 타원)

## 2. 글래스모피즘 컴포넌트 (lib/shared/widgets/)

### glass_card.dart
- BackdropFilter + ImageFilter.blur(sigmaX: 20, sigmaY: 20) 사용
- 배경: surfaceGlass, 테두리 1px surfaceGlassBorder
- borderRadius는 app_radius 토큰 사용
- 그림자(box-shadow) 옅게 추가해서 떠있는 느낌 (blurRadius 20~30, opacity 0.08 정도)
- child를 받는 재사용 가능한 위젯으로 작성

### glass_floating_navbar.dart
- 화면 하단에 떠있는 타원형 네비게이션 바
- Stack + Positioned로 화면 하단에서 일정 마진을 두고 배치 (좌우 마진 16~24, 하단 마진 16~24)
- 내부에 BackdropFilter 블러 적용
- 탭 아이템: 홈, 거래내역, (중앙 + 버튼은 별도 강조), 통계, 설정 — 5개 아이템, 중앙 + 버튼만 primary 그라데이션 배경의 원형으로 살짝 위로 띄워서 강조
- 아이콘은 lucide_icons 또는 flutter의 기본 Icons 중 미니멀한 라인 아이콘 스타일로 통일
- 선택된 탭은 아이콘+라벨, 비선택은 아이콘만 (공간 절약 + 시각적 임팩트)
- 탭 전환 시 부드러운 애니메이션 (AnimatedContainer 또는 flutter_animate 사용)

### amount_display.dart
- 금액을 보여주는 공통 위젯, 천단위 콤마 자동 포맷팅 (intl 패키지의 NumberFormat 사용)
- 양수/음수에 따라 income/expense 컬러 자동 적용
- 카운트업 애니메이션 옵션 지원 (화면 진입 시 0에서 실제 값까지 애니메이션, flutter_animate 또는 TweenAnimationBuilder 사용)

### gradient_background.dart
- 앱 전체 배경에 적용할 subtle한 그라데이션 배경 위젯 (배경색 토큰의 background 그라데이션 사용)

## 3. 패키지 추가 (pubspec.yaml)
- google_fonts (또는 폰트 직접 추가 방식)
- fl_chart (차트용, 이번 단계에서 설정만)
- flutter_animate (애니메이션)
- intl (숫자 포맷)
- lucide_icons 또는 적합한 아이콘 패키지

## 4. 검증용 쇼케이스 화면
lib/features/_design_showcase/showcase_screen.dart 를 만들어서 위에서 만든 모든 컴포넌트(GlassCard, GlassFloatingNavbar, AmountDisplay 등)를 한 화면에 모아 미리보기 할 수 있게 해줘. 이 화면은 main.dart에서 임시로 첫 화면으로 띄워서 디자인 시스템이 의도대로 렌더링되는지 바로 확인 가능하게 해줘.

전체적으로 "밝고 화사하면서도 고급스러운" 톤을 유지하고, 채도가 너무 높은 색은 피해줘. 그림자와 블러를 과하지 않게 써서 무겁지 않은 느낌을 유지하는 게 핵심이야.
