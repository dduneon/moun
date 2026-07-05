import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../auth/domain/auth_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/space_budget_repository.dart';
import '../../data/space_category_repository.dart';
import '../../data/space_repository.dart';
import '../../data/space_transaction_repository.dart';
import '../../domain/space_category_model.dart';
import '../../domain/space_model.dart';
import '../../../../shared/widgets/category_selector.dart';

final spaceRepositoryProvider = Provider<SpaceRepository>((ref) {
  return SpaceRepository(ref.read(dioProvider));
});

final spaceCategoryRepositoryProvider = Provider<SpaceCategoryRepository>((ref) {
  return SpaceCategoryRepository(ref.read(dioProvider));
});

final spaceTransactionRepositoryProvider = Provider<SpaceTransactionRepository>((ref) {
  return SpaceTransactionRepository(ref.read(dioProvider));
});

final spaceBudgetRepositoryProvider = Provider<SpaceBudgetRepository>((ref) {
  return SpaceBudgetRepository(ref.read(dioProvider));
});

/// 내가 속한 Space 목록.
final mySpacesProvider = FutureProvider<List<SpaceModel>>((ref) async {
  final authState = ref.watch(authProvider);
  if (authState is! AuthStateAuthenticated) {
    await Future<void>.delayed(const Duration(days: 365));
    throw Exception('not authenticated');
  }
  return ref.watch(spaceRepositoryProvider).listMySpaces();
});

const _selectedSpaceIdKey = 'current_space_id';

/// 마지막으로 선택한 Space id를 기기에 저장/복원한다. null = 개인 공간.
class SelectedSpaceIdNotifier extends StateNotifier<int?> {
  SelectedSpaceIdNotifier(this._storage) : super(null) {
    _restore();
  }

  final FlutterSecureStorage _storage;

  Future<void> _restore() async {
    final raw = await _storage.read(key: _selectedSpaceIdKey);
    if (raw != null) {
      state = int.tryParse(raw);
    }
  }

  Future<void> select(int? spaceId) async {
    state = spaceId;
    if (spaceId == null) {
      await _storage.delete(key: _selectedSpaceIdKey);
    } else {
      await _storage.write(key: _selectedSpaceIdKey, value: spaceId.toString());
    }
  }
}

final selectedSpaceIdProvider = StateNotifierProvider<SelectedSpaceIdNotifier, int?>((ref) {
  return SelectedSpaceIdNotifier(const FlutterSecureStorage());
});

/// 현재 화면에 표시할 컨텍스트 — 개인 공간 또는 선택된 Space.
/// 선택된 spaceId가 더 이상 내가 속한 목록에 없으면(예: 탈퇴) 개인 공간으로 되돌아간다.
final currentSpaceProvider = FutureProvider<SpaceContext>((ref) async {
  final selectedId = ref.watch(selectedSpaceIdProvider);
  if (selectedId == null) return const PersonalContext();

  final spaces = await ref.watch(mySpacesProvider.future);
  final match = spaces.where((s) => s.id == selectedId).toList();
  if (match.isEmpty) return const PersonalContext();
  return SpaceSelected(match.first);
});

/// 특정 Space의 멤버 목록.
final spaceMembersProvider =
    FutureProvider.family<List<SpaceMemberModel>, int>((ref, spaceId) async {
  return ref.watch(spaceRepositoryProvider).listMembers(spaceId);
});

final spaceCategoriesProvider =
    FutureProvider.family<List<SpaceCategoryModel>, int>((ref, spaceId) async {
  return ref.watch(spaceCategoryRepositoryProvider).list(spaceId);
});

final spaceCategoryItemsProvider =
    FutureProvider.family<List<CategoryItem>, int>((ref, spaceId) async {
  final cats = await ref.watch(spaceCategoriesProvider(spaceId).future);
  return cats.map((c) => c.toCategoryItem()).toList();
});

final spaceCategoryMapProvider =
    FutureProvider.family<Map<int, CategoryItem>, int>((ref, spaceId) async {
  final items = await ref.watch(spaceCategoryItemsProvider(spaceId).future);
  return {for (final item in items) item.id: item};
});
