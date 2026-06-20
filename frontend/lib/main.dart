import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/app_constants.dart';

void main() {
  runApp(const ProviderScope(child: MounApp()));
}

class MounApp extends StatelessWidget {
  const MounApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appName,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      home: Scaffold(
        appBar: AppBar(title: const Text(appName)),
        body: const Center(child: Text(appName, style: TextStyle(fontSize: 32))),
      ),
    );
  }
}
