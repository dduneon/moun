import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../providers/space_provider.dart';

class CreateSpaceScreen extends ConsumerStatefulWidget {
  const CreateSpaceScreen({super.key});

  @override
  ConsumerState<CreateSpaceScreen> createState() => _CreateSpaceScreenState();
}

class _CreateSpaceScreenState extends ConsumerState<CreateSpaceScreen> {
  final _nameController = TextEditingController();
  int _baseDay = 1;
  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _submitting) return;

    setState(() => _submitting = true);
    try {
      final space = await ref
          .read(spaceRepositoryProvider)
          .createSpace(name: name, baseDay: _baseDay);
      ref.invalidate(mySpacesProvider);
      await ref.read(selectedSpaceIdProvider.notifier).select(space.id);
      if (mounted) Navigator.of(context).pop(space);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('스페이스 생성에 실패했어요. 다시 시도해주세요.')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('스페이스 만들기')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text('이름', style: tt.labelLarge),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: '예: 우리집, 여행 모임',
                border: OutlineInputBorder(borderRadius: AppRadius.cardBorderRadius),
              ),
              autofocus: true,
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('예산 기준일', style: tt.labelLarge),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '매월 몇 일부터 예산 사이클을 시작할지 정해요. 스페이스 생성 후에는 바꿀 수 없어요.',
              style: tt.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.md),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              children: List.generate(31, (i) {
                final day = i + 1;
                final isLast = day == 31;
                final isSelected = day == _baseDay;
                return GestureDetector(
                  onTap: () => setState(() => _baseDay = day),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      isLast ? '말일' : '$day',
                      style: tt.bodySmall?.copyWith(
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                        fontSize: isLast ? 9 : null,
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: AppSpacing.xxl),
            ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                shape: RoundedRectangleBorder(borderRadius: AppRadius.buttonBorderRadius),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('만들기'),
            ),
          ],
        ),
      ),
    );
  }
}
