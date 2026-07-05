import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/category_selector.dart';

// Space 카테고리는 사용자가 자유롭게 이름을 짓기 때문에 개인 카테고리처럼
// 이름 기반 아이콘 매핑을 쓸 수 없다 — id를 해싱해 팔레트에서 색을 고른다.
const _palette = <Color>[
  AppColors.primary,
  Color(0xFF34C77B),
  Color(0xFFFF6B6B),
  Color(0xFFB39DFF),
  Color(0xFFFF9F43),
  Color(0xFF54A0FF),
];

@immutable
class SpaceCategoryModel {
  const SpaceCategoryModel({required this.id, required this.name, this.icon});

  final int id;
  final String name;
  final String? icon;

  factory SpaceCategoryModel.fromJson(Map<String, dynamic> json) => SpaceCategoryModel(
        id: json['id'] as int,
        name: json['name'] as String,
        icon: json['icon'] as String?,
      );

  CategoryItem toCategoryItem() {
    return CategoryItem(
      id: id,
      label: name,
      icon: Icons.category_rounded,
      color: _palette[id % _palette.length],
    );
  }
}
