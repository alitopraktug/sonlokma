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
  bool _obscure = true;
  bool _kvkkAccepted = false;
  bool _kvkkError = false;

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

  Future<void> _showKvkk() => showDialog<void>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('KVKK Aydınlatma Metni'),
          // TASLAK: yayından önce hukuki onaylı metinle değiştirilmeli.
          content: const SingleChildScrollView(
            child: Text(
              'Ad, e-posta ve sipariş bilgilerin hesabını yönetmek ve siparişlerini '
              'tamamlamak için işlenir. Konumun yalnızca yakındaki paketleri göstermek için '
              'anlık kullanılır ve kaydedilmez. Ödeme bilgilerin bize değil, ödeme '
              'kuruluşuna iletilir. Hesabını Profil > Hesabımı sil adımıyla dilediğin an '
              'silebilirsin; kişisel verilerin anonimleştirilir.',
            ),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('Kapat'))],
        ),
      );

  Future<void> _submit() async {
    final formOk = _form.currentState!.validate();
    setState(() => _kvkkError = !_kvkkAccepted);
    if (_loading || !formOk || !_kvkkAccepted) return;
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
        final messenger = ScaffoldMessenger.of(context);
        await Navigator.of(context).maybePop();
        messenger.showSnackBar(
            const SnackBar(content: Text('Kayıt tamam, giriş yapabilirsin.')));
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
                  key: const Key('register_password'),
                  controller: _password,
                  obscureText: _obscure,
                  autofillHints: const [AutofillHints.newPassword],
                  decoration: InputDecoration(
                    labelText: 'Şifre (en az 8 karakter)',
                    suffixIcon: IconButton(
                      tooltip: _obscure ? 'Şifreyi göster' : 'Şifreyi gizle',
                      icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: AuthValidators.password,
                ),
                const SizedBox(height: 8),
                CheckboxListTile(
                  key: const Key('register_kvkk'),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: _kvkkAccepted,
                  onChanged: (v) => setState(() {
                    _kvkkAccepted = v ?? false;
                    if (_kvkkAccepted) _kvkkError = false;
                  }),
                  title: Wrap(children: [
                    InkWell(
                      onTap: _showKvkk,
                      child: Text('KVKK Aydınlatma Metni',
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              decoration: TextDecoration.underline)),
                    ),
                    const Text("'ni okudum ve kabul ediyorum."),
                  ]),
                  subtitle: _kvkkError
                      ? Text('Devam etmek için onaylaman gerekiyor.',
                          style: TextStyle(color: Theme.of(context).colorScheme.error))
                      : null,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  key: const Key('register_submit'),
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
