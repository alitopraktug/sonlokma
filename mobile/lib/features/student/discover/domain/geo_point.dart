import 'dart:math' as math;

/// Domain kendi koordinat tipini kullanır; google_maps'in LatLng'ine bağımlı olmasın.
class GeoPoint {
  const GeoPoint(this.lat, this.lng);
  final double lat;
  final double lng;

  /// Haversine, metre cinsinden.
  double distanceTo(GeoPoint o) {
    const r = 6371000.0;
    double rad(double d) => d * math.pi / 180;
    final dLat = rad(o.lat - lat);
    final dLng = rad(o.lng - lng);
    final a = math.pow(math.sin(dLat / 2), 2) +
        math.cos(rad(lat)) * math.cos(rad(o.lat)) * math.pow(math.sin(dLng / 2), 2);
    return 2 * r * math.asin(math.sqrt(a));
  }

  @override
  bool operator ==(Object other) => other is GeoPoint && other.lat == lat && other.lng == lng;
  @override
  int get hashCode => Object.hash(lat, lng);
  @override
  String toString() => 'GeoPoint($lat, $lng)';
}
