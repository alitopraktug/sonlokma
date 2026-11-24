abstract final class AuthValidators {
  static final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? email(String? v) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return 'E-posta gerekli';
    if (!_email.hasMatch(s)) return 'Geçerli bir e-posta gir';
    return null;
  }

  static String? password(String? v) {
    if (v == null || v.isEmpty) return 'Şifre gerekli';
    if (v.length < 8) return 'Şifre en az 8 karakter olmalı';
    return null;
  }

  static String? name(String? v) =>
      (v == null || v.trim().length < 2) ? 'Adını gir' : null;

  /// Öğrenci doğrulaması backend'de yapılır; burada sadece kullanıcıyı bilgilendiriyoruz.
  static bool isStudentEmail(String email) => email.trim().toLowerCase().endsWith('.edu.tr');
}
