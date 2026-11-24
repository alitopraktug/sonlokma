import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_error.dart';
import '../data/orders_repository_impl.dart';
import '../domain/order.dart';

final orderProvider = FutureProvider.autoDispose.family<Order, String>(
  (ref, id) => ref.watch(ordersRepositoryProvider).getOrder(id),
);

class MyOrdersState {
  const MyOrdersState(this.items, this.nextCursor, {this.isLoadingMore = false, this.error});
  final List<Order> items;
  final String? nextCursor;
  final bool isLoadingMore;
  final ApiError? error;
}

class MyOrdersController extends AsyncNotifier<MyOrdersState> {
  @override
  Future<MyOrdersState> build() async {
    final page = await ref.read(ordersRepositoryProvider).myOrders();
    return MyOrdersState(page.items, page.nextCursor);
  }

  Future<void> loadMore() async {
    final s = state.valueOrNull;
    if (s == null || s.isLoadingMore || s.nextCursor == null) return;
    state = AsyncData(MyOrdersState(s.items, s.nextCursor, isLoadingMore: true));
    try {
      final page = await ref.read(ordersRepositoryProvider).myOrders(cursor: s.nextCursor);
      state = AsyncData(MyOrdersState([...s.items, ...page.items], page.nextCursor));
    } on ApiError catch (e) {
      state = AsyncData(MyOrdersState(s.items, s.nextCursor, error: e));
    }
  }
}

final myOrdersProvider =
    AsyncNotifierProvider<MyOrdersController, MyOrdersState>(MyOrdersController.new);
