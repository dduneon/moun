import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/category_selector.dart';

class CategoryModel {
  const CategoryModel({required this.id, required this.name});

  final int id;
  final String name;

  factory CategoryModel.fromJson(Map<String, dynamic> json) => CategoryModel(
        id: json['id'] as int,
        name: json['name'] as String,
      );

  CategoryItem toCategoryItem() {
    final meta = _categoryMeta[name];
    return CategoryItem(
      id: id,
      label: name,
      icon: meta?.$1 ?? Icons.more_horiz_rounded,
      color: meta?.$2 ?? AppColors.textSecondary,
    );
  }
}

// name → (icon, color) 매핑
const _categoryMeta = <String, (IconData, Color)>{
  '식비': (Icons.restaurant_rounded, Color(0xFF5B8DEF)),
  '교통': (Icons.directions_subway_rounded, Color(0xFF7C6FF0)),
  '쇼핑': (Icons.shopping_bag_rounded, Color(0xFFFF6B6B)),
  '문화': (Icons.movie_rounded, Color(0xFF34C77B)),
  '의료': (Icons.local_hospital_rounded, Color(0xFFFF9F43)),
  '통신': (Icons.smartphone_rounded, Color(0xFF54A0FF)),
  '카페': (Icons.local_cafe_rounded, Color(0xFF8D6E63)),
  '여행': (Icons.flight_rounded, Color(0xFFB39DFF)),
  '구독': (Icons.subscriptions_rounded, Color(0xFFFF6B6B)),
  '기타': (Icons.more_horiz_rounded, AppColors.textSecondary),
  '급여': (Icons.account_balance_rounded, Color(0xFF34C77B)),
  '부업': (Icons.work_rounded, Color(0xFF5B8DEF)),
  '투자': (Icons.trending_up_rounded, Color(0xFFB39DFF)),
  '기타수입': (Icons.more_horiz_rounded, AppColors.textSecondary),
  // 시스템 카테고리 (자동 생성, 카테고리 피커에서 제외)
  '수입': (Icons.arrow_circle_up_rounded, Color(0xFF34C77B)),
  '고정지출': (Icons.repeat_rounded, Color(0xFFB39DFF)),
};
