import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sonlokma/core/auth/auth_repository.dart';
import 'package:sonlokma/core/router/app_router.dart';

AppUser _user(UserRole role) =>
    AppUser(id: '1', email: 'a@x.edu.tr', name: 'A', role: role);

void main() {
  test('yüklenirken splash', () {
    expect(authRedirect(const AsyncLoading(), Routes.home), Routes.splash);
  });

  test('giriş yoksa login, login sayfasında kalır', () {
    expect(authRedirect(const AsyncData(null), Routes.home), Routes.login);
    expect(authRedirect(const AsyncData(null), Routes.login), isNull);
  });

  test('role göre yönlendirme', () {
    expect(authRedirect(AsyncData(_user(UserRole.CUSTOMER)), Routes.login), Routes.home);
    expect(authRedirect(AsyncData(_user(UserRole.BUSINESS)), Routes.splash), Routes.business);
  });

  test('roller birbirinin ekranına giremez', () {
    expect(authRedirect(AsyncData(_user(UserRole.CUSTOMER)), '/business/orders'), Routes.home);
    expect(authRedirect(AsyncData(_user(UserRole.BUSINESS)), '/home/x'), Routes.business);
    expect(authRedirect(AsyncData(_user(UserRole.BUSINESS)), Routes.orders), Routes.business);
    expect(authRedirect(AsyncData(_user(UserRole.CUSTOMER)), Routes.orderQr('o1')), isNull);
  });
}
