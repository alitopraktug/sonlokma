import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/network/api_error.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/utils/formatters.dart';
import '../../discover/domain/nearby_package.dart' show BusinessCategoryTr;
import '../data/package_detail_repository_impl.dart';
import '../domain/package_detail.dart';

class PackageDetailScreen extends ConsumerWidget {
  const PackageDetailScreen({super.key, required this.packageId});
  final String packageId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(packageDetailProvider(packageId));
    return Scaffold(
      appBar: AppBar(title: const Text('Paket detayı')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(e is ApiError ? e.userMessage : 'Paket yüklenemedi.'),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => ref.invalidate(packageDetailProvider(packageId)),
              child: const Text('Tekrar dene'),
            ),
          ]),
        ),
        data: (p) => RefreshIndicator(
          onRefresh: () => ref.refresh(packageDetailProvider(packageId).future),
          child: _Body(p),
        ),
      ),
      bottomNavigationBar: async.valueOrNull == null ? null : _BuyBar(async.requireValue),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body(this.p);
  final PackageDetail p;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final loc = LatLng(p.business.location.lat, p.business.location.lng);
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: p.imageUrl == null
              ? ColoredBox(
                  color: t.colorScheme.surfaceContainerHighest,
                  child: const Icon(Icons.shopping_bag_outlined, size: 64))
              : Image.network(p.imageUrl!, fit: BoxFit.cover),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${p.business.name} · ${p.business.category.label}', style: t.textTheme.labelLarge),
            const SizedBox(height: 4),
            Text(p.title, style: t.textTheme.headlineSmall),
            const SizedBox(height: 12),
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(Fmt.kurus(p.price),
                  style: t.textTheme.headlineMedium?.copyWith(color: t.colorScheme.primary)),
              const SizedBox(width: 8),
              Text(Fmt.kurus(p.originalPrice),
                  style: t.textTheme.titleMedium?.copyWith(decoration: TextDecoration.lineThrough)),
              const SizedBox(width: 8),
              Chip(label: Text('%${p.discountPercent} indirim')),
            ]),
            const SizedBox(height: 12),
            _InfoRow(Icons.schedule, 'Teslim: ${Fmt.timeRange(p.pickupStart, p.pickupEnd)}'),
            _InfoRow(
              Icons.inventory_2_outlined,
              p.availableQuantity > 0
                  ? 'Kalan: ${p.availableQuantity} / ${p.totalQuantity}'
                  : 'Tükendi',
              color: p.availableQuantity <= 2 ? t.colorScheme.error : null,
            ),
            _InfoRow(Icons.place_outlined, p.business.address),
            if (p.description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(p.description),
            ],
            const SizedBox(height: 8),
            Text('Sürpriz paketin içeriği günün ürünlerine göre değişir.',
                style: t.textTheme.bodySmall),
          ]),
        ),
        SizedBox(
          height: 180,
          // liteMode: statik görüntü, kaydırma yok, liste içinde ucuz.
          child: GoogleMap(
            liteModeEnabled: true,
            initialCameraPosition: CameraPosition(target: loc, zoom: 15),
            markers: {Marker(markerId: const MarkerId('b'), position: loc)},
            zoomControlsEnabled: false,
            mapToolbarEnabled: true, // Android: "yol tarifi" düğmesi
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.icon, this.text, {this.color});
  final IconData icon;
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(color: color))),
        ]),
      );
}

class _BuyBar extends StatelessWidget {
  const _BuyBar(this.p);
  final PackageDetail p;

  @override
  Widget build(BuildContext context) {
    final canBuy = p.canBuy(DateTime.now());
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: FilledButton(
          key: const Key('buy_button'),
          onPressed: canBuy ? () => context.push(Routes.checkout(p.id)) : null,
          child: Text(canBuy ? 'Satın al · ${Fmt.kurus(p.price)}' : 'Şu an satın alınamaz'),
        ),
      ),
    );
  }
}
