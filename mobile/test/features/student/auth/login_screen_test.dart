import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sonlokma/core/auth/auth_controller.dart';
import 'package:sonlokma/core/auth/auth_repository.dart';
import 'package:sonlokma/core/network/api_error.dart';
import 'package:sonlokma/features/student/auth/presentation/login_screen.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

const _customer = AppUser(
  id: 'u1',
  email: 'ali@example.com',
  name: 'Ali',
  role: UserRole.CUSTOMER,
);

void main() {
  late MockAuthRepository repo;
  late ProviderContainer container;

  setUp(() {
    repo = MockAuthRepository();
    when(() => repo.restoreSession()).thenAnswer((_) async => null);
    container = ProviderContainer(overrides: [authRepositoryProvider.overrideWithValue(repo)]);
  });
  tearDown(() => container.dispose());

  Future<void> pump(WidgetTester t) => t.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: LoginScreen()),
      ));

  Future<void> fill(WidgetTester t, String email, String pass) async {
    await t.enterText(find.byKey(const Key('login_email')), email);
    await t.enterText(find.byKey(const Key('login_password')), pass);
    await t.tap(find.byKey(const Key('login_submit')));
  }

  testWidgets('boş form gönderilmez, doğrulama mesajları görünür', (t) async {
    await pump(t);
    await t.tap(find.byKey(const Key('login_submit')));
    await t.pump();

    expect(find.text('E-posta gerekli'), findsOneWidget);
    expect(find.text('Şifre gerekli'), findsOneWidget);
    verifyNever(() => repo.login(any(), any()));
  });

  testWidgets('başarılı girişte oturum state\'i kullanıcıya döner', (t) async {
    when(() => repo.login('ali@example.com', 'sifre1234')).thenAnswer((_) async => _customer);
    await pump(t);
    await fill(t, ' ali@example.com ', 'sifre1234'); // boşluklar kırpılmalı
    await t.pumpAndSettle();

    expect(container.read(authControllerProvider).valueOrNull?.id, 'u1');
  });

  testWidgets('401 → "E-posta veya şifre hatalı" snackbar', (t) async {
    when(() => repo.login(any(), any())).thenThrow(
        const ApiError(code: ApiErrorCode.unauthorized, statusCode: 401));
    await pump(t);
    await fill(t, 'ali@example.com', 'yanlis123');
    await t.pumpAndSettle();

    expect(find.text('E-posta veya şifre hatalı.'), findsOneWidget);
    expect(container.read(authControllerProvider).valueOrNull, isNull);
  });

  testWidgets('ağ hatası genel Türkçe mesajla gösterilir', (t) async {
    when(() => repo.login(any(), any())).thenThrow(const ApiError(code: ApiErrorCode.network));
    await pump(t);
    await fill(t, 'ali@example.com', 'sifre1234');
    await t.pumpAndSettle();

    expect(find.text('İnternet bağlantını kontrol et.'), findsOneWidget);
  });
}
