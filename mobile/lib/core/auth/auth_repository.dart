import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_client.dart';
import 'token_storage.dart';

enum UserRole { CUSTOMER, BUSINESS, ADMIN } // ignore: constant_identifier_names — kontrattaki adlar

class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
  });

  final String id;
  final String email;
  final String name;
  final UserRole role;

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        id: j['id'] as String,
        email: j['email'] as String,
        name: j['name'] as String,
        role: UserRole.values.byName(j['role'] as String),
      );
}

/// Core'da çünkü Yusuf'un işletme modu da aynı oturumu kullanıyor.
/// Kayıt/doğrulama ekranları features/student/auth altında, bu repo'yu çağırır.
class AuthRepository {
  AuthRepository(this._api, this._storage);
  final ApiClient _api;
  final TokenStorage _storage;

  Future<AppUser> login(String email, String password) async {
    final res = await _api.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'email': email, 'password': password},
      skipAuth: true,
    );
    await _storage.save(TokenPair.fromJson(res));
    return AppUser.fromJson(res['user'] as Map<String, dynamic>);
  }

  Future<void> register({
    required String email,
    required String password,
    required String name,
    required UserRole role,
  }) =>
      _api.post<dynamic>(
        '/auth/register',
        data: {'email': email, 'password': password, 'name': name, 'role': role.name},
        skipAuth: true,
      );

  Future<void> verifyEmail(String token) =>
      _api.post<dynamic>('/auth/verify-email', data: {'token': token}, skipAuth: true);

  /// Uygulama açılışında oturum var mı? Token yoksa ağa gitmeden null döner.
  Future<AppUser?> restoreSession() async {
    if (await _storage.readRefreshToken() == null) return null;
    final me = await _api.get<Map<String, dynamic>>('/users/me');
    return AppUser.fromJson(me);
  }

  Future<void> registerDeviceToken(String fcmToken) =>
      _api.post<dynamic>('/users/me/device-token', data: {'fcmToken': fcmToken});

  Future<void> logout() => _storage.clear();
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(apiClientProvider), ref.watch(tokenStorageProvider)),
);
