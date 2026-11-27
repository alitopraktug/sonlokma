import '../../../../core/auth/auth_repository.dart';

class Impact {
  const Impact({required this.packagesSaved, required this.kgSaved, required this.moneySaved});
  final int packagesSaved;
  final double kgSaved;
  final int moneySaved; // kuruş

  // ⚠️ KONTRAT: kgSaved'in tipi (number) ve moneySaved'in kuruş olduğu varsayıldı
  // (para kuralı gereği). openapi.yaml'da netleştirilmeli.
  factory Impact.fromJson(Map<String, dynamic> j) => Impact(
        packagesSaved: (j['packagesSaved'] as num?)?.toInt() ?? 0,
        kgSaved: (j['kgSaved'] as num?)?.toDouble() ?? 0,
        moneySaved: (j['moneySaved'] as num?)?.toInt() ?? 0,
      );

  /// Yaygın kullanılan yaklaşık katsayı: 1 kg gıda israfı ≈ 2,5 kg CO₂e. Sadece gösterim.
  double get co2Kg => kgSaved * 2.5;
}

class Profile {
  const Profile({required this.user, required this.impact});
  final AppUser user;
  final Impact impact;
}

abstract class ProfileRepository {
  Future<Profile> me();

  /// KVKK: DELETE /users/me (soft delete + anonimleştirme).
  Future<void> deleteAccount();
}
