import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../domain/package_detail.dart';
import 'package_detail_dto.dart';

class PackageDetailRepositoryImpl implements PackageDetailRepository {
  PackageDetailRepositoryImpl(this._api);
  final ApiClient _api;

  @override
  Future<PackageDetail> getById(String id) async =>
      PackageDetailDto.fromJson(await _api.get<Map<String, dynamic>>('/packages/$id')).toEntity();
}

final packageDetailRepositoryProvider = Provider<PackageDetailRepository>(
  (ref) => PackageDetailRepositoryImpl(ref.watch(apiClientProvider)),
);

/// autoDispose: ekrandan çıkınca bellekten düşer, tekrar girince güncel stok çekilir.
final packageDetailProvider = FutureProvider.autoDispose.family<PackageDetail, String>(
  (ref, id) => ref.watch(packageDetailRepositoryProvider).getById(id),
);
