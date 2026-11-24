import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../../core/config/env.dart';
import '../../domain/geo_point.dart';

class UserLocation {
  const UserLocation(this.point, {required this.isFallback});
  final GeoPoint point;

  /// true → izin yok/konum kapalı; kampüs merkezi kullanılıyor, UI açıklama göstermeli (KVKK).
  final bool isFallback;
}

/// Soyut: testte geolocator platform kanalına gitmeyelim.
abstract class LocationService {
  Future<GeoPoint?> currentPosition();
}

class GeolocatorLocationService implements LocationService {
  @override
  Future<GeoPoint?> currentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) return null;
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
    if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
      return null;
    }
    try {
      final p = await Geolocator.getCurrentPosition(
        // "Yakınımdaki paketler" için ~100 m yeterli; yüksek hassasiyet pil ve süre harcar.
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 8),
        ),
      );
      return GeoPoint(p.latitude, p.longitude);
    } catch (_) {
      return null; // zaman aşımı vb. → kampüs merkezine düş
    }
  }
}

final campusCenter = GeoPoint(Env.campusLat, Env.campusLng);

final locationServiceProvider = Provider<LocationService>((_) => GeolocatorLocationService());

final userLocationProvider = FutureProvider<UserLocation>((ref) async {
  final p = await ref.watch(locationServiceProvider).currentPosition();
  return p == null ? UserLocation(campusCenter, isFallback: true) : UserLocation(p, isFallback: false);
});
