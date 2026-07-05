import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_bottom_sheet.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/gradient_background.dart';
import '../../domain/space_model.dart';
import '../providers/space_provider.dart';
import 'create_space_screen.dart';
import 'space_detail_screen.dart';
import 'space_members_screen.dart';

class SpaceListScreen extends ConsumerWidget {
  const SpaceListScreen({super.key});

  Future<void> _leaveSpace(BuildContext context, WidgetRef ref, SpaceModel space) async {
    final ok = await AppConfirmDialog.show(
      context,
      title: '스페이스 나가기',
      message: '\'${space.name}\'에서 나가시겠어요? 기록된 데이터는 그대로 남아있어요.',
      confirmLabel: '나가기',
      isDestructive: true,
    );
    if (!ok) return;

    await ref.read(spaceRepositoryProvider).leaveSpace(space.id);

    final selectedId = ref.read(selectedSpaceIdProvider);
    if (selectedId == space.id) {
      await ref.read(selectedSpaceIdProvider.notifier).select(null);
    }
    ref.invalidate(mySpacesProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacesAsync = ref.watch(mySpacesProvider);
    final selectedId = ref.watch(selectedSpaceIdProvider);
    final tt = Theme.of(context).textTheme;

    return GradientBackground(
      child: Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xl),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_back_rounded,
                            size: 18, color: AppColors.textPrimary),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Text('스페이스 관리', style: tt.headlineMedium),
                  ],
                ).animate().fadeIn(),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              sliver: spacesAsync.when(
                loading: () => const SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, __) => const SliverToBoxAdapter(
                  child: Center(child: Text('스페이스 목록을 불러오지 못했어요.')),
                ),
                data: (spaces) {
                  return SliverList(
                    delegate: SliverChildListDelegate([
                      _PersonalTile(
                        isSelected: selectedId == null,
                        onTap: () => ref.read(selectedSpaceIdProvider.notifier).select(null),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      if (spaces.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                          child: Text(
                            '아직 참여 중인 스페이스가 없어요.\n함께 지출을 기록할 스페이스를 만들어보세요.',
                            textAlign: TextAlign.center,
                            style: tt.bodyMedium?.copyWith(color: AppColors.textSecondary),
                          ),
                        )
                      else
                        ...spaces.map((space) => Padding(
                              padding: const EdgeInsets.only(bottom: AppSpacing.md),
                              child: _SpaceTile(
                                space: space,
                                isSelected: selectedId == space.id,
                                onTap: () =>
                                    ref.read(selectedSpaceIdProvider.notifier).select(space.id),
                                onLeave: () => _leaveSpace(context, ref, space),
                                onManage: () => Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => SpaceDetailScreen(space: space)),
                                ),
                                onMembers: () => Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => SpaceMembersScreen(space: space)),
                                ),
                              ),
                            )),
                      const SizedBox(height: AppSpacing.md),
                      OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const CreateSpaceScreen()),
                        ),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('스페이스 만들기'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                          shape: RoundedRectangleBorder(borderRadius: AppRadius.buttonBorderRadius),
                        ),
                      ),
                    ]),
                  );
                },
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
          ],
        ),
      ),
    ));
  }
}

class _PersonalTile extends StatelessWidget {
  const _PersonalTile({required this.isSelected, required this.onTap});
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.cardBorderRadius,
      child: GlassCard(
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.person_rounded, color: AppColors.primary),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: Text('개인 공간', style: tt.titleMedium)),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}

class _SpaceTile extends StatelessWidget {
  const _SpaceTile({
    required this.space,
    required this.isSelected,
    required this.onTap,
    required this.onLeave,
    required this.onManage,
    required this.onMembers,
  });

  final SpaceModel space;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLeave;
  final VoidCallback onManage;
  final VoidCallback onMembers;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.cardBorderRadius,
      child: GlassCard(
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: AppColors.income.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.groups_rounded, color: AppColors.income),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(space.name, style: tt.titleMedium),
                  Text('멤버 ${space.memberCount}명',
                      style: tt.bodySmall?.copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
            if (isSelected)
              const Padding(
                padding: EdgeInsets.only(right: AppSpacing.xs),
                child: Icon(Icons.check_circle_rounded, color: AppColors.primary),
              ),
            IconButton(
              icon: const Icon(Icons.more_vert_rounded, color: AppColors.textSecondary),
              onPressed: () => _showSpaceActions(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showSpaceActions(BuildContext context) async {
    await AppBottomSheet.show<void>(
      context,
      title: space.name,
      child: _SpaceActionSheet(
        onMembers: () {
          Navigator.pop(context);
          onMembers();
        },
        onManage: () {
          Navigator.pop(context);
          onManage();
        },
        onLeave: () {
          Navigator.pop(context);
          onLeave();
        },
      ),
    );
  }
}

class _SpaceActionSheet extends StatelessWidget {
  const _SpaceActionSheet({
    required this.onMembers,
    required this.onManage,
    required this.onLeave,
  });

  final VoidCallback onMembers;
  final VoidCallback onManage;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SpaceActionItem(
          icon: Icons.group_rounded,
          iconColor: AppColors.primary,
          label: '멤버 관리',
          onTap: onMembers,
        ),
        const SizedBox(height: AppSpacing.sm),
        _SpaceActionItem(
          icon: Icons.account_balance_wallet_rounded,
          iconColor: AppColors.income,
          label: '고정수입/지출 관리',
          onTap: onManage,
        ),
        const SizedBox(height: AppSpacing.sm),
        _SpaceActionItem(
          icon: Icons.logout_rounded,
          iconColor: AppColors.expense,
          label: '나가기',
          labelColor: AppColors.expense,
          onTap: onLeave,
        ),
      ],
    );
  }
}

class _SpaceActionItem extends StatelessWidget {
  const _SpaceActionItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
    this.labelColor,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final Color? labelColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.buttonBorderRadius,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.06),
          borderRadius: AppRadius.buttonBorderRadius,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              label,
              style: tt.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: labelColor ?? AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
