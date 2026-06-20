import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/auth_model.dart';
import '../providers/auth_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState is AuthStateAuthenticated ? authState.user : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('모운'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: '로그아웃',
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('대시보드 (준비 중)', style: TextStyle(fontSize: 20)),
            if (user != null) ...[
              const SizedBox(height: 12),
              Text('안녕하세요, ${user.name}님'),
            ],
          ],
        ),
      ),
    );
  }
}
