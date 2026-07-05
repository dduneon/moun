import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/space_model.dart';
import '../providers/space_provider.dart';

/// Home/Transactions/Statistics 상단에 두는 "개인 공간 ↔ Space" 전환 드롭다운.
class SpaceSwitcher extends ConsumerWidget {
  const SpaceSwitcher({super.key});

  Future<void> _openPicker(BuildContext context, WidgetRef ref) async {
    final spaces = await ref.read(mySpacesProvider.future);
    if (!context.mounted) return;

    final selectedId = ref.read(selectedSpaceIdProvider);

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: AppSpacing.md),
              ListTile(
                leading: const Icon(Icons.person_rounded, color: AppColors.primary),
                title: const Text('개인 공간'),
                trailing: selectedId == null
                    ? const Icon(Icons.check_rounded, color: AppColors.primary)
                    : null,
                onTap: () {
                  ref.read(selectedSpaceIdProvider.notifier).select(null);
                  Navigator.of(sheetContext).pop();
                },
              ),
              for (final space in spaces)
                ListTile(
                  leading: const Icon(Icons.groups_rounded, color: AppColors.income),
                  title: Text(space.name),
                  subtitle: Text('멤버 ${space.memberCount}명'),
                  trailing: selectedId == space.id
                      ? const Icon(Icons.check_rounded, color: AppColors.primary)
                      : null,
                  onTap: () {
                    ref.read(selectedSpaceIdProvider.notifier).select(space.id);
                    Navigator.of(sheetContext).pop();
                  },
                ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.add_rounded, color: AppColors.textSecondary),
                title: const Text('스페이스 관리'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  context.push('/settings/spaces');
                },
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentAsync = ref.watch(currentSpaceProvider);
    final label = currentAsync.when(
      data: (c) => c is SpaceSelected ? c.space.name : '개인 공간',
      loading: () => '개인 공간',
      error: (_, __) => '개인 공간',
    );

    return InkWell(
      onTap: () => _openPicker(context, ref),
      borderRadius: AppRadius.buttonBorderRadius,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(width: 2),
            const Icon(Icons.expand_more_rounded, size: 16, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
