import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../../core/config/env.dart';
import '../../../../../core/network/request_metrics.dart';
import '../../../../../core/router/app_router.dart';
import '../../../../../core/utils/debouncer.dart';
import '../../../../../core/utils/formatters.dart';
import '../../domain/geo_point.dart';
import '../../domain/nearby_package.dart';
import '../providers/location_provider.dart';
import '../providers/nearby_provider.dart';

/// Performans stratejisi (sunum konusu):
/// 1. Clustering → binlerce marker yerine ekranda onlarca küme çizilir (FPS).
/// 2. Debounce 400 ms → kamera her karede değil, kullanıcı durunca sorgulanır (istek sayısı).
/// 3. 150 m eşiği → küçük kaydırmalar hiç istek atmaz (QueryCenterNotifier).
/// 4. Marker set'i yalnızca veri değişince yeniden kurulur (_markersFor cache).
class PackageMapView extends ConsumerStatefulWidget {
  const PackageMapView({super.key});

  @override
  ConsumerState<PackageMapView> createState() => _PackageMapViewState();
}

class _PackageMapViewState extends ConsumerState<PackageMapView> {
  static const _clusterId = ClusterManagerId('packages');
  final _debouncer = Debouncer(const Duration(milliseconds: 400));
  GoogleMapController? _controller;

  List<NearbyPackage>? _lastItems;
  Set<Marker> _markers = const {};

  @override
  void dispose() {
    _debouncer.dispose();
    _controller?.dispose();
    super.dispose();
  }

  Set<Marker> _markersFor(List<NearbyPackage> items) {
    if (identical(items, _lastItems)) return _markers;
    _lastItems = items;
    return _markers = {
      for (final p in items)
        Marker(
          markerId: MarkerId(p.id),
          clusterManagerId: Env.benchNoCluster ? null : _clusterId,
          position: LatLng(p.location.lat, p.location.lng),
          icon: BitmapDescriptor.defaultMarkerWithHue(_hue(p.category)),
          infoWindow: InfoWindow(
            title: '${p.businessName} · ${Fmt.kurus(p.price)}',
            snippet: '${p.title} · ${Fmt.timeRange(p.pickupStart, p.pickupEnd)}',
            onTap: () => context.push(Routes.packageDetail(p.id)),
          ),
        ),
    };
  }

  static double _hue(BusinessCategory c) => switch (c) {
        BusinessCategory.BAKERY => BitmapDescriptor.hueOrange,
        BusinessCategory.CAFE => BitmapDescriptor.hueViolet,
        BusinessCategory.RESTAURANT => BitmapDescriptor.hueRed,
      };

  void _onCameraMove(CameraPosition pos) {
    void update() {
      if (!mounted) return;
      ref
          .read(queryCenterProvider.notifier)
          .moveTo(GeoPoint(pos.target.latitude, pos.target.longitude));
    }

    Env.benchNoDebounce ? update() : _debouncer.run(update);
  }

  /// Kamerayı taşır; sorgu merkezi onCameraMove → debounce yoluyla kendiliğinden güncellenir.
  Future<void> _moveCamera(GeoPoint p) async {
    await _controller?.animateCamera(CameraUpdate.newLatLngZoom(LatLng(p.lat, p.lng), 14));
  }

  Future<void> _zoomToCluster(Cluster c) async {
    final current = await _controller?.getZoomLevel() ?? 14;
    await _controller?.animateCamera(CameraUpdate.newLatLngZoom(c.position, current + 2));
  }

  @override
  Widget build(BuildContext context) {
    final location = ref.watch(userLocationProvider);
    final nearby = ref.watch(nearbyProvider);

    // initialCameraPosition yalnızca ilk açılışta okunur. İzin sonradan verilirse
    // (ayarlardan dönüş) kamerayı kullanıcının konumuna taşı.
    ref.listen(userLocationProvider, (prev, next) {
      final before = prev?.valueOrNull;
      final now = next.valueOrNull;
      if (before != null && before.isFallback && now != null && !now.isFallback) {
        _moveCamera(now.point);
      }
    });

    return location.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const SizedBox.shrink(), // provider hata fırlatmaz, kampüse düşer
      data: (loc) {
        final items = nearby.valueOrNull?.items ?? const <NearbyPackage>[];
        return Stack(
          children: [
            GoogleMap(
              initialCameraPosition:
                  CameraPosition(target: LatLng(loc.point.lat, loc.point.lng), zoom: 14),
              myLocationEnabled: !loc.isFallback,
              myLocationButtonEnabled: !loc.isFallback,
              mapToolbarEnabled: false,
              onMapCreated: (c) => _controller = c,
              onCameraMove: _onCameraMove,
              clusterManagers: Env.benchNoCluster
                  ? const <ClusterManager>{}
                  : {ClusterManager(clusterManagerId: _clusterId, onClusterTap: _zoomToCluster)},
              markers: _markersFor(items),
            ),
            Positioned(
              left: 12,
              bottom: 24,
              child: FloatingActionButton.small(
                heroTag: 'campus',
                tooltip: 'Kampüse dön',
                onPressed: () => _moveCamera(campusCenter),
                child: const Icon(Icons.school_outlined),
              ),
            ),
            if (Env.benchOverlay)
              Positioned(
                top: 8,
                right: 8,
                child: ValueListenableBuilder(
                  valueListenable: requestMetrics.counts,
                  builder: (_, m, __) => Chip(
                    label: Text('nearby: ${m['/packages/nearby'] ?? 0} · marker: ${items.length}'),
                    onDeleted: requestMetrics.reset,
                    deleteIcon: const Icon(Icons.restart_alt, size: 18),
                  ),
                ),
              ),
            if (nearby.isLoading)
              const Positioned(top: 0, left: 0, right: 0, child: LinearProgressIndicator()),
            if (nearby.hasError && !nearby.isLoading)
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Material(
                  elevation: 2,
                  borderRadius: BorderRadius.circular(8),
                  child: ListTile(
                    leading: const Icon(Icons.cloud_off),
                    title: const Text('Paketler yüklenemedi'),
                    trailing: TextButton(
                      onPressed: () => ref.invalidate(nearbyProvider),
                      child: const Text('Tekrar dene'),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
