import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/deeplink/deep_link_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/space_model.dart';
import '../providers/space_provider.dart';

class InvitePreviewScreen extends ConsumerStatefulWidget {
  const InvitePreviewScreen({super.key, required this.token});

  final String token;

  @override
  ConsumerState<InvitePreviewScreen> createState() => _InvitePreviewScreenState();
}

class _InvitePreviewScreenState extends ConsumerState<InvitePreviewScreen> {
  late Future<SpaceInvitePreviewModel> _previewFuture;
  bool _accepting = false;

  @override
  void initState() {
    super.initState();
    _previewFuture = ref.read(spaceRepositoryProvider).previewInvite(widget.token);
  }

  void _dismiss() {
    ref.read(pendingInviteTokenProvider.notifier).state = null;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  Future<void> _accept() async {
    setState(() => _accepting = true);
    try {
      final space = await ref.read(spaceRepositoryProvider).acceptInvite(widget.token);
      ref.invalidate(mySpacesProvider);
      await ref.read(selectedSpaceIdProvider.notifier).select(space.id);
      ref.read(pendingInviteTokenProvider.notifier).state = null;
      if (mounted) context.go('/home');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('참여에 실패했어요. 링크가 만료되었을 수 있어요.')),
        );
        setState(() => _accepting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('스페이스 초대')),
      body: SafeArea(
        child: FutureBuilder<SpaceInvitePreviewModel>(
          future: _previewFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return _InvalidInvite(onClose: _dismiss);
            }

            final preview = snapshot.data!;
            if (!preview.valid) {
              return _InvalidInvite(onClose: _dismiss);
            }

            return Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 72, height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.income.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.groups_rounded, size: 36, color: AppColors.income),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(preview.spaceName, style: tt.headlineSmall, textAlign: TextAlign.center),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '현재 멤버 ${preview.memberCount}명',
                    style: tt.bodyMedium?.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  Text(
                    '이 스페이스에 참여하면 함께 지출/수입을 기록하고 볼 수 있어요.',
                    textAlign: TextAlign.center,
                    style: tt.bodySmall?.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  ElevatedButton(
                    onPressed: _accepting ? null : _accept,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: AppRadius.buttonBorderRadius),
                    ),
                    child: _accepting
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('참여하기'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextButton(
                    onPressed: _accepting ? null : _dismiss,
                    child: const Text('나중에'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _InvalidInvite extends StatelessWidget {
  const _InvalidInvite({required this.onClose});
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.link_off_rounded, size: 48, color: AppColors.textSecondary),
          const SizedBox(height: AppSpacing.md),
          Text('유효하지 않은 초대 링크예요', style: tt.titleMedium, textAlign: TextAlign.center),
          Text('만료되었거나 취소된 링크일 수 있어요.',
              style: tt.bodySmall?.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton(onPressed: onClose, child: const Text('닫기')),
        ],
      ),
    );
  }
}
