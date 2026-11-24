import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenPair {
  const TokenPair({required this.accessToken, required this.refreshToken});
  final String accessToken;
  final String refreshToken;

  factory TokenPair.fromJson(Map<String, dynamic> json) => TokenPair(
        accessToken: json['accessToken'] as String,
        refreshToken: json['refreshToken'] as String,
      );
}

/// Soyut tutuyoruz ki testlerde bellek içi sahte sürüm kullanılabilsin.
abstract class TokenStorage {
  Future<String?> readAccessToken();
  Future<String?> readRefreshToken();
  Future<void> save(TokenPair pair);
  Future<void> clear();
}

/// Keychain (iOS) / EncryptedSharedPreferences (Android). SharedPreferences düz metindir,
/// refresh token 30 gün geçerli olduğu için orada tutulmaz.
class SecureTokenStorage implements TokenStorage {
  SecureTokenStorage([FlutterSecureStorage? storage])
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  final FlutterSecureStorage _storage;
  static const _kAccess = 'access_token';
  static const _kRefresh = 'refresh_token';

  // Her istekte keychain'e gitmemek için bellek önbelleği.
  String? _accessCache;

  @override
  Future<String?> readAccessToken() async =>
      _accessCache ??= await _storage.read(key: _kAccess);

  @override
  Future<String?> readRefreshToken() => _storage.read(key: _kRefresh);

  @override
  Future<void> save(TokenPair pair) async {
    _accessCache = pair.accessToken;
    await _storage.write(key: _kAccess, value: pair.accessToken);
    await _storage.write(key: _kRefresh, value: pair.refreshToken);
  }

  @override
  Future<void> clear() async {
    _accessCache = null;
    await _storage.delete(key: _kAccess);
    await _storage.delete(key: _kRefresh);
  }
}

class InMemoryTokenStorage implements TokenStorage {
  String? access;
  String? refresh;

  @override
  Future<String?> readAccessToken() async => access;
  @override
  Future<String?> readRefreshToken() async => refresh;
  @override
  Future<void> save(TokenPair pair) async {
    access = pair.accessToken;
    refresh = pair.refreshToken;
  }

  @override
  Future<void> clear() async => access = refresh = null;
}
