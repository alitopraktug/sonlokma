import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sonlokma/core/auth/auth_repository.dart';
import 'package:sonlokma/features/student/auth/presentation/register_screen.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository repo;

  setUpAll(() => registerFallbackValue(UserRole.STUDENT));
  setUp(() => repo = MockAuthRepository());

  Future<void> pumpAndFill(WidgetTester t) async {
    await t.pumpWidget(ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(repo)],
      child: const MaterialApp(home: RegisterScreen()),
    ));
    final fields = find.byType(TextFormField);
    await t.enterText(fields.at(0), 'Ali');
    await t.enterText(fields.at(1), 'ali@gmail.com'); // .edu.tr değil → doğrulama ekranına gitmez
    await t.enterText(fields.at(2), 'sifre1234');
    await t.ensureVisible(find.byKey(const Key('register_submit')));
    await t.pump();
  }

  void stubRegister() => when(() => repo.register(
        email: any(named: 'email'),
        password: any(named: 'password'),
        name: any(named: 'name'),
        role: any(named: 'role'),
      )).thenAnswer((_) async {});

  testWidgets('KVKK onayı olmadan kayıt isteği gitmez', (t) async {
    stubRegister();
    await pumpAndFill(t);
    await t.tap(find.byKey(const Key('register_submit')));
    await t.pump();

    expect(find.text('Devam etmek için onaylaman gerekiyor.'), findsOneWidget);
    verifyNever(() => repo.register(
          email: any(named: 'email'),
          password: any(named: 'password'),
          name: any(named: 'name'),
          role: any(named: 'role'),
        ));
  });

  testWidgets('onay verilince STUDENT rolüyle kayıt olunur', (t) async {
    stubRegister();
    await pumpAndFill(t);
    await t.tap(find.byKey(const Key('register_kvkk')));
    await t.pump();
    await t.tap(find.byKey(const Key('register_submit')));
    await t.pump();

    verify(() => repo.register(
          email: 'ali@gmail.com',
          password: 'sifre1234',
          name: 'Ali',
          role: UserRole.STUDENT,
        )).called(1);
  });

  testWidgets('şifre göster/gizle', (t) async {
    await pumpAndFill(t);
    EditableText field() => t.widget<EditableText>(
        find.descendant(of: find.byKey(const Key('register_password')), matching: find.byType(EditableText)));
    expect(field().obscureText, isTrue);
    await t.tap(find.byTooltip('Şifreyi göster'));
    await t.pump();
    expect(field().obscureText, isFalse);
  });
}
