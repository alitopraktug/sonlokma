import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Router uygulamanın "composition root"u: feature ekranlarını yalnızca burada import ederiz.
import '../../features/student/auth/presentation/login_screen.dart';
import '../../features/student/auth/presentation/register_screen.dart';
import '../../features/student/auth/presentation/verify_email_screen.dart';
import '../../features/student/checkout/presentation/checkout_screen.dart';
import '../../features/student/discover/presentation/discover_screen.dart';
import '../../features/student/orders/presentation/order_detail_screen.dart';
import '../../features/student/orders/presentation/orders_screen.dart';
import '../../features/student/orders/presentation/qr_screen.dart';
import '../../features/student/package_detail/presentation/package_detail_screen.dart';
import '../../features/student/profile/presentation/profile_screen.dart';
import '../auth/auth_controller.dart';
import '../auth/auth_repository.dart';

abstract final class Routes {
  static const splash = '/splash';
  static const login = '/login';
  static const register = '/register';
  static const verifyEmail = '/verify-email';

  // CUSTOMER (alt menü sekmeleri: home / orders / profile)
  static const home = '/home';
  static const orders = '/orders';
  static const profile = '/profile';
  static String packageDetail(String id) => '$home/packages/$id';
  static String checkout(String packageId) => '$home/packages/$packageId/checkout';
  static String orderDetail(String id) => '$orders/$id';
  static String orderQr(String id) => '$orders/$id/qr';

  // BUSINESS (Yusuf) — /business altındaki her şey
  static const business = '/business';
}

/// Saf fonksiyon: test edilebilsin diye router'dan ayrı.
String? authRedirect(AsyncValue<AppUser?> auth, String location) {
  if (auth.isLoading && !auth.hasValue) return location == Routes.splash ? null : Routes.splash;

  final user = auth.valueOrNull;
  final onAuthPage = location == Routes.login ||
      location == Routes.register ||
      location == Routes.verifyEmail;

  if (user == null) return onAuthPage ? null : Routes.login;

  final isBusiness = user.role == UserRole.BUSINESS;
  final inBusinessArea = location.startsWith(Routes.business);
  if (onAuthPage || location == Routes.splash) return isBusiness ? Routes.business : Routes.home;
  // Roller birbirinin alanına giremez (asıl yetki kontrolü backend'de, bu UX katmanı).
  if (isBusiness && !inBusinessArea) return Routes.business;
  if (!isBusiness && inBusinessArea) return Routes.home;
  return null;
}

final rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  // Auth değişince router'ı yeniden oluşturmak yerine sadece redirect'i tetikle.
  final refresh = ValueNotifier(0);
  ref.listen(authControllerProvider, (_, __) => refresh.value++);
  ref.onDispose(refresh.dispose);

  // Alt menüyü kapatan tam ekran sayfalar kök navigator'da açılır.
  GoRoute full(String path, Widget Function(GoRouterState) b, {List<RouteBase> routes = const []}) =>
      GoRoute(
        path: path,
        parentNavigatorKey: rootNavigatorKey,
        builder: (_, s) => b(s),
        routes: routes,
      );

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: Routes.splash,
    refreshListenable: refresh,
    redirect: (_, state) => authRedirect(ref.read(authControllerProvider), state.matchedLocation),
    routes: [
      GoRoute(
        path: Routes.splash,
        builder: (_, __) => const Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      GoRoute(path: Routes.login, builder: (_, __) => const LoginScreen()),
      GoRoute(path: Routes.register, builder: (_, __) => const RegisterScreen()),
      GoRoute(
        path: Routes.verifyEmail,
        builder: (_, s) => VerifyEmailScreen(
          email: s.extra as String?,
          initialToken: s.uri.queryParameters['token'],
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) => _StudentShell(shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.home,
              builder: (_, __) => const DiscoverScreen(),
              routes: [
                full('packages/:id', (s) => PackageDetailScreen(packageId: s.pathParameters['id']!),
                    routes: [
                      full('checkout',
                          (s) => CheckoutScreen(packageId: s.pathParameters['id']!)),
                    ]),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.orders,
              builder: (_, __) => const OrdersScreen(),
              routes: [
                full(':id', (s) => OrderDetailScreen(orderId: s.pathParameters['id']!), routes: [
                  full('qr', (s) => QrScreen(orderId: s.pathParameters['id']!)),
                ]),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: Routes.profile, builder: (_, __) => const ProfileScreen()),
          ]),
        ],
      ),
      // Yusuf işletme ekranlarını buraya ekler.
      GoRoute(
        path: Routes.business,
        builder: (_, __) => const Scaffold(body: Center(child: Text('İşletme modu'))),
      ),
    ],
  );
});

class _StudentShell extends StatelessWidget {
  const _StudentShell(this.shell);
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: shell,
        bottomNavigationBar: NavigationBar(
          selectedIndex: shell.currentIndex,
          onDestinationSelected: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.explore_outlined), label: 'Keşfet'),
            NavigationDestination(icon: Icon(Icons.receipt_long_outlined), label: 'Siparişlerim'),
            NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profil'),
          ],
        ),
      );
}
