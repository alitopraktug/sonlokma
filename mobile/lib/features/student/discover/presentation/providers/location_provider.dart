import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../../core/config/env.dart';
import '../../domain/geo_point.dart';

/// Konum neden alınamadı? UI buna göre doğru düğmeyi gösterir.
enum LocationIssue {
  /// Telefonun konum servisi kapalı → konum ayarlarını aç.
  serviceDisabled,

  /// İzin reddedildi ama tekrar sorulabilir → yeniden iste.
  denied,

  /// "Bir daha sorma" → uygulama ayarlarını aç (sistem artık diyalog göstermez).
  deniedForever,

  /// İzin var ama konum zamanında gelmedi (kapalı alan, GPS soğuk).
  unavailable,
}

class LocationReading {
  const LocationReading.ok(GeoPoint this.point) : issue = null;
  const LocationReading.failed(LocationIssue this.issue) : point = null;

  final GeoPoint? point;
  final LocationIssue? issue;
}

class UserLocation {
  const UserLocation(this.point, {this.issue});
  final GeoPoint point;
  final LocationIssue? issue;

  /// true → varsayılan merkez kullanılıyor, UI açıklama göstermeli (KVKK).
  bool get isFallback => issue != null;
}

/// Soyut: testte geolocator platform kanalına gitmeyelim.
abstract class LocationService {
  Future<LocationReading> read();
  Future<void> openSettings(LocationIssue issue);
}

class GeolocatorLocationService implements LocationService {
  @override
  Future<LocationReading> read() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return const LocationReading.failed(LocationIssue.serviceDisabled);
    }
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
    if (perm == LocationPermission.deniedForever) {
      return const LocationReading.failed(LocationIssue.deniedForever);
    }
    if (perm == LocationPermission.denied) {
      return const LocationReading.failed(LocationIssue.denied);
    }
    try {
      final p = await Geolocator.getCurrentPosition(
        // "Yakınımdaki paketler" için ~100 m yeterli; yüksek hassasiyet pil ve süre harcar.
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 8),
        ),
      );
      return LocationReading.ok(GeoPoint(p.latitude, p.longitude));
    } catch (_) {
      // Zaman aşımında son bilinen konum da iş görür.
      final last = await Geolocator.getLastKnownPosition();
      return last == null
          ? const LocationReading.failed(LocationIssue.unavailable)
          : LocationReading.ok(GeoPoint(last.latitude, last.longitude));
    }
  }

  @override
  Future<void> openSettings(LocationIssue issue) async {
    switch (issue) {
      case LocationIssue.serviceDisabled:
        await Geolocator.openLocationSettings();
      case LocationIssue.deniedForever:
        await Geolocator.openAppSettings();
      case LocationIssue.denied:
      case LocationIssue.unavailable:
        break; // ayara gerek yok; provider yenilenince tekrar istenir
    }
  }
}

final defaultCenter = GeoPoint(Env.defaultLat, Env.defaultLng);

final locationServiceProvider = Provider<LocationService>((_) => GeolocatorLocationService());

final userLocationProvider = FutureProvider<UserLocation>((ref) async {
  final r = await ref.watch(locationServiceProvider).read();
  return r.point != null ? UserLocation(r.point!) : UserLocation(defaultCenter, issue: r.issue);
});

/// Banner metni ve düğmesi — saf fonksiyon, test edilir.
({String message, String action}) locationIssueCopy(LocationIssue issue) => switch (issue) {
      LocationIssue.serviceDisabled => (
          message: 'Telefonunun konum servisi kapalı, şehir merkezini gösteriyoruz.',
          action: 'Konumu aç',
        ),
      LocationIssue.denied => (
          message: 'Konum iznin olmadığı için şehir merkezini gösteriyoruz. Konumunu yalnızca '
              'yakındaki paketleri bulmak için kullanırız, kaydetmeyiz.',
          action: 'İzin ver',
        ),
      LocationIssue.deniedForever => (
          message: 'Konum izni kapalı. Yakındaki paketleri görmek için ayarlardan izin verebilirsin; '
              'konumunu kaydetmeyiz.',
          action: 'Ayarları aç',
        ),
      LocationIssue.unavailable => (
          message: 'Konumun şu an alınamadı, şehir merkezini gösteriyoruz.',
          action: 'Tekrar dene',
        ),
    };
