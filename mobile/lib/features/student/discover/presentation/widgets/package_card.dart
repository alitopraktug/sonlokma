import 'package:flutter/material.dart';

import '../../../../../core/utils/formatters.dart';
import '../../domain/nearby_package.dart';

class PackageCard extends StatelessWidget {
  const PackageCard({super.key, required this.package, required this.onTap});
  final NearbyPackage package;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = package;
    final t = Theme.of(context);
    final lowStock = p.availableQuantity <= 2;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            SizedBox.square(
              dimension: 96,
              child: p.imageUrl == null
                  ? ColoredBox(
                      color: t.colorScheme.surfaceContainerHighest,
                      child: const Icon(Icons.shopping_bag_outlined),
                    )
                  : Image.network(
                      p.imageUrl!,
                      fit: BoxFit.cover,
                      cacheWidth: 192, // liste performansı: tam boy görseli decode etme
                      errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined),
                    ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.businessName, style: t.textTheme.labelMedium),
                    Text(p.title,
                        style: t.textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(
                      '${Fmt.timeRange(p.pickupStart, p.pickupEnd)} · ${Fmt.distance(p.distanceMeters)}',
                      style: t.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(Fmt.kurus(p.price),
                            style: t.textTheme.titleMedium?.copyWith(color: t.colorScheme.primary)),
                        const SizedBox(width: 6),
                        Text(Fmt.kurus(p.originalPrice),
                            style: t.textTheme.bodySmall
                                ?.copyWith(decoration: TextDecoration.lineThrough)),
                        const Spacer(),
                        if (lowStock)
                          Text('Son ${p.availableQuantity}!',
                              style: t.textTheme.labelMedium?.copyWith(color: t.colorScheme.error))
                        else
                          Text('%${p.discountPercent}', style: t.textTheme.labelLarge),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
