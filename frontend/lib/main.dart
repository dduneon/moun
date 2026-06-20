import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'core/constants/app_constants.dart';
import 'core/network/dio_provider.dart';
import 'core/router/router.dart';
import 'core/storage/token_storage.dart';

void main() {
  runApp(
    ProviderScope(
      overrides: [
        tokenStorageProvider.overrideWithValue(
          SecureTokenStorage(const FlutterSecureStorage()),
        ),
      ],
      child: const MounApp(),
    ),
  );
}

class MounApp extends ConsumerWidget {
  const MounApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: appName,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      routerConfig: ref.watch(routerProvider),
    );
  }
}
