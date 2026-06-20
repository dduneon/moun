import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/auth_model.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_text_field.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _errorMessage = null);

    try {
      await ref.read(authProvider.notifier).register(
            email: _emailCtrl.text.trim(),
            password: _passwordCtrl.text,
            name: _nameCtrl.text.trim(),
          );
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAuthenticating =
        ref.watch(authProvider) is AuthStateAuthenticating;

    return Scaffold(
      appBar: AppBar(title: const Text('회원가입')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AuthTextField(
                      controller: _nameCtrl,
                      label: '이름',
                      textInputAction: TextInputAction.next,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? '이름을 입력해주세요' : null,
                    ),
                    const SizedBox(height: 16),
                    AuthTextField(
                      controller: _emailCtrl,
                      label: '이메일',
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: (v) =>
                          (v == null || !v.contains('@')) ? '올바른 이메일을 입력해주세요' : null,
                    ),
                    const SizedBox(height: 16),
                    AuthTextField(
                      controller: _passwordCtrl,
                      label: '비밀번호',
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submit(),
                      validator: (v) =>
                          (v == null || v.length < 6) ? '비밀번호는 6자 이상이어야 합니다' : null,
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _errorMessage!,
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: isAuthenticating ? null : _submit,
                      child: isAuthenticating
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('가입하기'),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => context.go('/login'),
                      child: const Text('이미 계정이 있으신가요? 로그인'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
