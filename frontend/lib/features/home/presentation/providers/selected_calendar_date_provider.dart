import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 홈 화면 달력에서 사용자가 선택한 날짜.
/// 하단 네비게이션의 '+' 버튼이 거래 추가 시트를 열 때 초기 날짜로 사용된다.
final selectedCalendarDateProvider = StateProvider<DateTime?>((ref) => null);
