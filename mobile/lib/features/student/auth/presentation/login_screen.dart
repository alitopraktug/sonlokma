import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/auth_controller.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/router/app_router.dart';
import 'validators.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading || !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    try {
      await ref.read(authControllerProvider.notifier).login(_email.text.trim(), _password.text);
      // Başarılıysa yönlendirmeyi router yapar (role göre), burada navigate etmiyoruz.
    } on ApiError catch (e) {
      if (!mounted) return;
      final msg = e.code == ApiErrorCode.unauthorized ? 'E-posta veya şifre hatalı.' : e.userMessage;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _form,
                child: AutofillGroup(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(Icons.eco, size: 56, color: theme.colorScheme.primary),
                      const SizedBox(height: 12),
                      Text('SonLokma',
                          textAlign: TextAlign.center, style: theme.textTheme.headlineMedium),
                      Text('Gün sonu lezzetleri, öğrenci fiyatına',
                          textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
                      const SizedBox(height: 32),
                      TextFormField(
                        key: const Key('login_email'),
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                            labelText: 'E-posta', prefixIcon: Icon(Icons.mail_outline)),
                        validator: AuthValidators.email,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        key: const Key('login_password'),
                        controller: _password,
                        obscureText: _obscure,
                        autofillHints: const [AutofillHints.password],
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(),
                        decoration: InputDecoration(
                          labelText: 'Şifre',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            tooltip: _obscure ? 'Şifreyi göster' : 'Şifreyi gizle',
                            icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                            onPressed: () => setState(() => _obscure = !_obscure),
                          ),
                        ),
                        validator: AuthValidators.password,
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        key: const Key('login_submit'),
                        onPressed: _loading ? null : _submit,
                        child: _loading
                            ? const SizedBox.square(
                                dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text('Giriş yap'),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _loading ? null : () => context.push(Routes.register),
                        child: const Text('Hesabın yok mu? Kayıt ol'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
