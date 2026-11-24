import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/auth_repository.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/router/app_router.dart';
import 'validators.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _email.addListener(() => setState(() {})); // .edu.tr ipucunu canlı güncelle
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading || !_form.currentState!.validate()) return;
    setState(() => _loading = true);
    final email = _email.text.trim();
    try {
      await ref.read(authRepositoryProvider).register(
            email: email,
            password: _password.text,
            name: _name.text.trim(),
            role: UserRole.STUDENT, // işletme kaydı Yusuf'un akışında
          );
      if (!mounted) return;
      if (AuthValidators.isStudentEmail(email)) {
        context.pushReplacement(Routes.verifyEmail, extra: email);
      } else {
        context.pop();
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Kayıt tamam, giriş yapabilirsin.')));
      }
    } on ApiError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.userMessage)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isStudent = AuthValidators.isStudentEmail(_email.text);
    return Scaffold(
      appBar: AppBar(title: const Text('Kayıt ol')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _name,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Ad Soyad'),
                  validator: AuthValidators.name,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'E-posta',
                    helperText: isStudent
                        ? '✓ Öğrenci e-postası: doğrulama kodu gönderilecek'
                        : 'Öğrenci indirimleri için .edu.tr adresini kullan',
                  ),
                  validator: AuthValidators.email,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _password,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Şifre (en az 8 karakter)'),
                  validator: AuthValidators.password,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox.square(
                          dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Kayıt ol'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
