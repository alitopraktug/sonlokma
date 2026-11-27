import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_client.dart';
import '../network/api_error.dart';
import 'auth_repository.dart';

/// data(null) = çıkış yapılmış, data(user) = giriş yapılmış, loading = açılışta kontrol.
class AuthController extends AsyncNotifier<AppUser?> {
  @override
  Future<AppUser?> build() async {
    // Interceptor refresh'te başarısız olursa oturumu düşür → router login'e atar.
    ref.listen(sessionExpiredProvider, (_, __) => state = const AsyncData(null));
    try {
      return await ref.read(authRepositoryProvider).restoreSession();
    } on ApiError {
      return null;
    }
  }

  /// Global state'i AsyncLoading yapmıyoruz: yapsaydık router splash'e atlar, login ekranı
  /// kaybolurdu. Yükleniyor/hata durumu ekranın kendi işi; hata [ApiError] olarak fırlatılır.
  Future<void> login(String email, String password) async {
    final user = await ref.read(authRepositoryProvider).login(email, password);
    state = AsyncData(user);
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncData(null);
  }
}

final authControllerProvider =
    AsyncNotifierProvider<AuthController, AppUser?>(AuthController.new);
