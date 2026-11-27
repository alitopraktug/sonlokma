import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/auth_repository.dart';
import '../../../../core/network/api_client.dart';
import '../domain/profile.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl(this._api);
  final ApiClient _api;

  @override
  Future<Profile> me() async {
    final j = await _api.get<Map<String, dynamic>>('/users/me');
    return Profile(
      user: AppUser.fromJson(j),
      impact: Impact.fromJson((j['impact'] as Map?)?.cast<String, dynamic>() ?? const {}),
    );
  }

  @override
  Future<void> deleteAccount() => _api.delete<dynamic>('/users/me');
}

final profileRepositoryProvider =
    Provider<ProfileRepository>((ref) => ProfileRepositoryImpl(ref.watch(apiClientProvider)));

final profileProvider =
    FutureProvider.autoDispose<Profile>((ref) => ref.watch(profileRepositoryProvider).me());
