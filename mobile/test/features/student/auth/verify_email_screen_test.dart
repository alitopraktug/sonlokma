import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sonlokma/core/auth/auth_repository.dart';
import 'package:sonlokma/core/network/api_error.dart';
import 'package:sonlokma/features/student/auth/presentation/verify_email_screen.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository repo;
  setUp(() => repo = MockAuthRepository());

  Future<void> pump(WidgetTester t) => t.pumpWidget(ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(home: VerifyEmailScreen(email: 'ali@ogr.edu.tr')),
      ));

  testWidgets('boş kodla istek gitmez', (t) async {
    await pump(t);
    await t.tap(find.text('Doğrula'));
    await t.pump();
    verifyNever(() => repo.verifyEmail(any()));
  });

  testWidgets('geçersiz kod → anlaşılır mesaj', (t) async {
    when(() => repo.verifyEmail('123'))
        .thenThrow(const ApiError(code: ApiErrorCode.validationError, statusCode: 400));
    await pump(t);
    await t.enterText(find.byType(TextField), ' 123 ');
    await t.tap(find.text('Doğrula'));
    await t.pump();
    verify(() => repo.verifyEmail('123')).called(1);
    expect(find.text('Kod geçersiz veya süresi dolmuş.'), findsOneWidget);
  });
}
