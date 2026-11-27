import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Sunumdaki "istek sayısı önce/sonra" ölçümü için: yol başına istek sayar.
/// Maliyeti bir Map artırımı; prod'da da zararsız ama rozet yalnızca BENCH_OVERLAY ile görünür.
class RequestMetrics extends Interceptor {
  final counts = ValueNotifier<Map<String, int>>(const {});

  int countFor(String path) => counts.value[path] ?? 0;

  void reset() => counts.value = const {};

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final m = Map.of(counts.value);
    m[options.path] = (m[options.path] ?? 0) + 1;
    counts.value = m;
    handler.next(options);
  }
}

/// Tekil: hem ApiClient hem rozet aynı örneği görsün.
final requestMetrics = RequestMetrics();
