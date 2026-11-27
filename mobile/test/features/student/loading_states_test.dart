import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sonlokma/core/network/cursor_page.dart';
import 'package:sonlokma/features/student/discover/data/discover_repository_impl.dart';
import 'package:sonlokma/features/student/discover/domain/discover_repository.dart';
import 'package:sonlokma/features/student/discover/domain/geo_point.dart';
import 'package:sonlokma/features/student/discover/domain/nearby_package.dart';
import 'package:sonlokma/features/student/discover/presentation/providers/location_provider.dart';
import 'package:sonlokma/features/student/discover/presentation/widgets/package_list_view.dart';

/// İlk istek, test [release] diyene kadar bekler → yükleniyor durumunu görebiliriz.
class SlowDiscover implements DiscoverRepository {
  final gate = Completer<void>();
  void release() => gate.complete();

  @override
  Future<CursorPage<NearbyPackage>> nearby(NearbyQuery q) async {
    await gate.future;
    return const CursorPage(items: [], nextCursor: null);
  }
}

class Here implements LocationService {
  @override
  Future<LocationReading> read() async => const LocationReading.ok(GeoPoint(41, 29));
  @override
  Future<void> openSettings(LocationIssue issue) async {}
}

void main() {
  setUpAll(() => initializeDateFormatting('tr_TR'));

  testWidgets('yüklenirken iskelet, sonra boş durum', (t) async {
    final repo = SlowDiscover();
    await t.pumpWidget(ProviderScope(
      overrides: [
        discoverRepositoryProvider.overrideWithValue(repo),
        locationServiceProvider.overrideWithValue(Here()),
      ],
      child: const MaterialApp(home: Scaffold(body: PackageListView())),
    ));
    await t.pump();
    await t.pump(const Duration(milliseconds: 100));

    expect(find.byKey(const Key('skeleton_list')), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    repo.release();
    await t.pumpAndSettle();

    expect(find.byKey(const Key('skeleton_list')), findsNothing);
    expect(find.textContaining('Yakınında şu an paket yok'), findsOneWidget);
  });
}
