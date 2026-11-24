import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/auth_repository.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/router/app_router.dart';

/// Kontrat: POST /auth/verify-email {token}. Token maildeki linkten/koddan gelir.
/// İleride deep link ile `?token=` doğrudan doldurulabilir.
class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key, this.email, this.initialToken});
  final String? email;
  final String? initialToken;

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  late final _token = TextEditingController(text: widget.initialToken);
  bool _loading = false;

  @override
  void dispose() {
    _token.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final token = _token.text.trim();
    if (_loading || token.isEmpty) return;
    setState(() => _loading = true);
    try {
      await ref.read(authRepositoryProvider).verifyEmail(token);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('E-postan doğrulandı, giriş yapabilirsin.')));
      context.go(Routes.login);
    } on ApiError catch (e) {
      if (!mounted) return;
      final msg = e.code == ApiErrorCode.validationError || e.code == ApiErrorCode.notFound
          ? 'Kod geçersiz veya süresi dolmuş.'
          : e.userMessage;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('E-posta doğrulama')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.mark_email_unread_outlined, size: 56),
              const SizedBox(height: 16),
              Text(
                '${widget.email ?? 'E-posta adresine'} gönderdiğimiz doğrulama kodunu gir.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _token,
                decoration: const InputDecoration(labelText: 'Doğrulama kodu'),
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox.square(
                        dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Doğrula'),
              ),
              TextButton(
                onPressed: () => context.go(Routes.login),
                child: const Text('Daha sonra'),
              ),
            ],
          ),
        ),
      );
}
