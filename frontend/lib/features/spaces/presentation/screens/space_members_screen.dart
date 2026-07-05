import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_bottom_sheet.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/gradient_background.dart';
import '../../../auth/domain/auth_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/space_model.dart';
import '../providers/space_provider.dart';

/// Space 멤버 목록 조회 + 관리자(생성자)만 멤버 초대/제외가 가능한 화면.
class SpaceMembersScreen extends ConsumerWidget {
  const SpaceMembersScreen({super.key, required this.space});
  final SpaceModel space;

  Future<void> _createInvite(BuildContext context, WidgetRef ref) async {
    try {
      final invite = await ref.read(spaceRepositoryProvider).createInvite(space.id);
      await SharePlus.instance.share(
        ShareParams(text: '${space.name} 스페이스에 초대할게요!\n${invite.url}'),
      );
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('초대 링크 생성에 실패했어요.')),
        );
      }
    }
  }

  Future<void> _removeMember(BuildContext context, WidgetRef ref, SpaceMemberModel member) async {
    final ok = await AppConfirmDialog.show(
      context,
      title: '멤버 제외',
      message: '\'${member.name}\'님을 스페이스에서 제외할까요?',
      confirmLabel: '제외',
      isDestructive: true,
    );
    if (!ok) return;

    try {
      await ref.read(spaceRepositoryProvider).removeMember(space.id, member.userId);
      ref.invalidate(spaceMembersProvider(space.id));
      ref.invalidate(mySpacesProvider);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('멤버를 제외하지 못했어요.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tt = Theme.of(context).textTheme;
    final membersAsync = ref.watch(spaceMembersProvider(space.id));
    final authState = ref.watch(authProvider);
    final currentUserId = authState is AuthStateAuthenticated ? authState.user.id : null;
    final isAdmin = currentUserId != null && currentUserId == space.createdByUserId;

    return GradientBackground(
      child: Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xl),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back_rounded,
                          size: 18, color: AppColors.textPrimary),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Text('${space.name} 멤버 관리', style: tt.headlineMedium),
                ],
              ).animate().fadeIn(),
            ),
            Expanded(
              child: membersAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const Center(child: Text('멤버 목록을 불러오지 못했어요.')),
                data: (members) {
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
                    children: [
                      ...members.map((member) => Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.md),
                            child: _MemberTile(
                              member: member,
                              isMe: member.userId == currentUserId,
                              canRemove: isAdmin && !member.isOwner,
                              onRemove: () => _removeMember(context, ref, member),
                            ),
                          )),
                      const SizedBox(height: AppSpacing.md),
                      OutlinedButton.icon(
                        onPressed: () => _createInvite(context, ref),
                        icon: const Icon(Icons.person_add_alt_1_rounded),
                        label: const Text('멤버 초대하기'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                          shape: RoundedRectangleBorder(borderRadius: AppRadius.buttonBorderRadius),
                        ),
                      ),
                      if (!isAdmin) ...[
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          '관리자만 멤버를 제외할 수 있어요.',
                          textAlign: TextAlign.center,
                          style: tt.labelSmall?.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ));
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({
    required this.member,
    required this.isMe,
    required this.canRemove,
    required this.onRemove,
  });

  final SpaceMemberModel member;
  final bool isMe;
  final bool canRemove;
  final VoidCallback onRemove;

  static final _dateFmt = DateFormat('yyyy.MM.dd');

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return GlassCard(
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (member.isOwner ? AppColors.primary : AppColors.income).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              member.isOwner ? Icons.shield_rounded : Icons.person_rounded,
              color: member.isOwner ? AppColors.primary : AppColors.income,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(member.name, style: tt.titleMedium),
                    if (isMe) ...[
                      const SizedBox(width: 4),
                      Text('(나)', style: tt.bodySmall?.copyWith(color: AppColors.textSecondary)),
                    ],
                    if (member.isOwner) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '관리자',
                          style: tt.labelSmall?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  '${member.email ?? ''}${member.email != null ? ' · ' : ''}${_dateFmt.format(member.joinedAt)} 가입',
                  style: tt.bodySmall?.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          if (canRemove)
            IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.person_remove_rounded, color: AppColors.expense),
              tooltip: '제외',
            ),
        ],
      ),
    );
  }
}
