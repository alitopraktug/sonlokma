import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/network/api_error.dart';
import '../../../../../core/router/app_router.dart';
import '../../../../../core/ui/skeleton.dart';
import '../providers/nearby_provider.dart';
import 'package_card.dart';

class PackageListView extends ConsumerStatefulWidget {
  const PackageListView({super.key});

  @override
  ConsumerState<PackageListView> createState() => _PackageListViewState();
}

class _PackageListViewState extends ConsumerState<PackageListView> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      // Sona 600 px kala bir sonraki sayfayı iste; kullanıcı spinner görmeden veri gelsin.
      if (_scroll.position.extentAfter < 600) ref.read(nearbyProvider.notifier).loadMore();
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(nearbyProvider);
    final data = async.valueOrNull;

    if (data == null) {
      return async.hasError
          ? _Message(
              icon: Icons.cloud_off,
              text: (async.error is ApiError)
                  ? (async.error! as ApiError).userMessage
                  : 'Paketler yüklenemedi.',
              action: () => ref.invalidate(nearbyProvider),
            )
          : const SkeletonList();
    }

    if (data.items.isEmpty) {
      return const _Message(
        icon: Icons.search_off,
        text: 'Yakınında şu an paket yok.\nMesafeyi artırmayı ya da filtreleri temizlemeyi dene.',
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.refresh(nearbyProvider.future),
      child: ListView.builder(
        controller: _scroll,
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
        itemCount: data.items.length + 1,
        itemBuilder: (_, i) {
          if (i < data.items.length) {
            final p = data.items[i];
            return PackageCard(
              key: ValueKey(p.id),
              package: p,
              onTap: () => context.push(Routes.packageDetail(p.id)),
            );
          }
          // footer
          if (data.isLoadingMore) {
            return const Padding(
                padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()));
          }
          if (data.loadMoreError != null) {
            return TextButton.icon(
              onPressed: () => ref.read(nearbyProvider.notifier).loadMore(),
              icon: const Icon(Icons.refresh),
              label: Text('${data.loadMoreError!.userMessage} Tekrar dene'),
            );
          }
          return const SizedBox(height: 16);
        },
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text, this.action});
  final IconData icon;
  final String text;
  final VoidCallback? action;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 48),
            const SizedBox(height: 12),
            Text(text, textAlign: TextAlign.center),
            if (action != null) ...[
              const SizedBox(height: 12),
              OutlinedButton(onPressed: action, child: const Text('Tekrar dene')),
            ],
          ]),
        ),
      );
}
