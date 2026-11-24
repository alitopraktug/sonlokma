import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sonlokma/core/auth/auth_repository.dart';
import 'package:sonlokma/core/network/api_error.dart';
import 'package:sonlokma/features/student/profile/data/profile_repository_impl.dart';
import 'package:sonlokma/features/student/profile/domain/profile.dart';
import 'package:sonlokma/features/student/profile/presentation/profile_screen.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}

class MockAuthRepository extends Mock implements AuthRepository {}

const _user = AppUser(
    id: 'u1', email: 'ali@ogr.edu.tr', name: 'Ali', role: UserRole.STUDENT, isStudentVerified: true);

void main() {
  setUpAll(() => initializeDateFormatting('tr_TR'));

  late MockProfileRepository profile;
  late MockAuthRepository auth;

  setUp(() {
    profile = MockProfileRepository();
    auth = MockAuthRepository();
    when(() => profile.me()).thenAnswer((_) async => const Profile(
        user: _user, impact: Impact(packagesSaved: 3, kgSaved: 2, moneySaved: 15000)));
    when(() => auth.restoreSession()).thenAnswer((_) async => _user);
    when(() => auth.logout()).thenAnswer((_) async {});
  });

  Future<void> pump(WidgetTester t) async {
    await t.pumpWidget(ProviderScope(
      overrides: [
        profileRepositoryProvider.overrideWithValue(profile),
        authRepositoryProvider.overrideWithValue(auth),
      ],
      child: const MaterialApp(home: ProfileScreen()),
    ));
    await t.pumpAndSettle();
  }

  Future<void> openDelete(WidgetTester t) async {
    await t.scrollUntilVisible(find.text('Hesabımı sil'), 100);
    await t.tap(find.text('Hesabımı sil'));
    await t.pumpAndSettle();
  }

  testWidgets('profil ve öğrenci rozeti gösterilir', (t) async {
    await pump(t);
    expect(find.text('Ali'), findsOneWidget);
    expect(find.text('Öğrenci'), findsOneWidget);
    expect(find.text('Sosyal etki'), findsOneWidget);
  });

  testWidgets('hesap silmede vazgeç → istek gitmez', (t) async {
    await pump(t);
    await openDelete(t);
    await t.tap(find.text('Vazgeç'));
    await t.pumpAndSettle();
    verifyNever(() => profile.deleteAccount());
    verifyNever(() => auth.logout());
  });

  testWidgets('onaylayınca hesap silinir ve oturum kapanır', (t) async {
    when(() => profile.deleteAccount()).thenAnswer((_) async {});
    await pump(t);
    await openDelete(t);
    await t.tap(find.text('Sil'));
    await t.pumpAndSettle();
    verify(() => profile.deleteAccount()).called(1);
    verify(() => auth.logout()).called(1);
  });

  testWidgets('silme başarısızsa oturum açık kalır, hata gösterilir', (t) async {
    when(() => profile.deleteAccount()).thenThrow(const ApiError(code: ApiErrorCode.network));
    await pump(t);
    await openDelete(t);
    await t.tap(find.text('Sil'));
    await t.pumpAndSettle();
    verifyNever(() => auth.logout());
    expect(find.byType(SnackBar), findsOneWidget);
  });
}
