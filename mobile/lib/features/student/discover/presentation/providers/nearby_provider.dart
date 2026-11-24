import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/config/env.dart';
import '../../../../../core/network/api_error.dart';
import '../../data/discover_repository_impl.dart';
import '../../domain/discover_repository.dart';
import '../../domain/geo_point.dart';
import '../../domain/nearby_package.dart';
import 'discover_filter_provider.dart';
import 'location_provider.dart';

/// Sorgunun merkezi. null → kullanıcının konumu (veya kampüs merkezi).
/// Harita kaydırıldıkça (debounce sonrası) güncellenir.
class QueryCenterNotifier extends Notifier<GeoPoint?> {
  /// Bu kadar küçük kaydırmalar yeni istek tetiklemez. Debounce "ne zaman" sorusunu,
  /// bu eşik "gerek var mı" sorusunu çözer; ikisi birlikte istek sayısını düşürür.
  static const minMoveMeters = 150.0;

  @override
  GeoPoint? build() => null;

  void moveTo(GeoPoint p) {
    final current = state;
    if (!Env.benchNoDebounce && current != null && current.distanceTo(p) < minMoveMeters) return;
    state = p;
  }
}

final queryCenterProvider =
    NotifierProvider<QueryCenterNotifier, GeoPoint?>(QueryCenterNotifier.new);

class NearbyState {
  const NearbyState({
    required this.items,
    required this.nextCursor,
    this.isLoadingMore = false,
    this.loadMoreError,
  });

  final List<NearbyPackage> items;
  final String? nextCursor;
  final bool isLoadingMore;
  final ApiError? loadMoreError;

  bool get hasMore => nextCursor != null;
}

class NearbyController extends AsyncNotifier<NearbyState> {
  NearbyQuery? _query;

  @override
  Future<NearbyState> build() async {
    // watch'lar await'ten ÖNCE: filtre/merkez değişince Riverpod build'i yeniden çalıştırır,
    // eski isteğin sonucunu da kendisi çöpe atar (yarış durumu yok).
    final filter = ref.watch(discoverFilterProvider);
    final explicitCenter = ref.watch(queryCenterProvider);
    final location = ref.watch(userLocationProvider.future);

    final center = explicitCenter ?? (await location).point;
    final query = _query = filter.toQuery(center);
    final page = await ref.read(discoverRepositoryProvider).nearby(query);
    return NearbyState(items: page.items, nextCursor: page.nextCursor);
  }

  /// Liste sonuna yaklaşınca çağrılır. Aynı anda ikinci kez tetiklenmez.
  Future<void> loadMore() async {
    final current = state.valueOrNull;
    final query = _query;
    if (current == null || query == null || current.isLoadingMore || !current.hasMore) return;
    if (state.isLoading) return; // filtre değişiyor; eski sayfaya ekleme yapma

    state = AsyncData(NearbyState(
      items: current.items,
      nextCursor: current.nextCursor,
      isLoadingMore: true,
    ));
    try {
      final page = await ref.read(discoverRepositoryProvider).nearby(query.withCursor(current.nextCursor));
      if (!identical(query, _query)) return; // bu arada filtre değişti → sonuç bayat
      state = AsyncData(NearbyState(
        items: [...current.items, ...page.items],
        nextCursor: page.nextCursor,
      ));
    } on ApiError catch (e) {
      if (!identical(query, _query)) return;
      // Sayfa 2 hatası mevcut listeyi silmesin; sadece altta "tekrar dene" gösterilir.
      state = AsyncData(NearbyState(
        items: current.items,
        nextCursor: current.nextCursor,
        loadMoreError: e,
      ));
    }
  }
}

final nearbyProvider = AsyncNotifierProvider<NearbyController, NearbyState>(NearbyController.new);
