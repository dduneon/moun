import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_provider.dart';
import '../../data/category_repository.dart';
import '../../domain/category_model.dart';
import '../../../../shared/widgets/category_selector.dart';

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository(ref.read(dioProvider));
});

final categoriesProvider = FutureProvider<List<CategoryModel>>((ref) async {
  final repo = ref.watch(categoryRepositoryProvider);
  await repo.seedIfEmpty();
  return repo.list();
});

final categoryItemsProvider = FutureProvider<List<CategoryItem>>((ref) async {
  final cats = await ref.watch(categoriesProvider.future);
  return cats.map((c) => c.toCategoryItem()).toList();
});

final categoryMapProvider = FutureProvider<Map<int, CategoryItem>>((ref) async {
  final items = await ref.watch(categoryItemsProvider.future);
  return {for (final item in items) item.id: item};
});

