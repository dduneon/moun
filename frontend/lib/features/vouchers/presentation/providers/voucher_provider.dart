import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_provider.dart';
import '../../data/voucher_repository.dart';
import '../../domain/voucher_model.dart';

final voucherRepositoryProvider = Provider<VoucherRepository>((ref) {
  return VoucherRepository(ref.read(dioProvider));
});

/// 사용자의 상품권 목록 (잔액 포함).
final vouchersProvider = FutureProvider<List<VoucherModel>>((ref) async {
  return ref.read(voucherRepositoryProvider).list();
});

/// 결제수단 선택에 쓸 활성 상품권만.
final activeVouchersProvider = FutureProvider<List<VoucherModel>>((ref) async {
  final all = await ref.watch(vouchersProvider.future);
  return all.where((v) => v.isActive).toList();
});
