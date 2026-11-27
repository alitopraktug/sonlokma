import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/utils/formatters.dart';
import '../../domain/nearby_package.dart';
import '../providers/discover_filter_provider.dart';

/// Taslak bir kopya üzerinde çalışır, "Uygula"ya basınca tek seferde yazar.
/// Böylece her chip tıklaması ayrı bir API isteği tetiklemez.
class FilterSheet extends ConsumerStatefulWidget {
  const FilterSheet({super.key});

  static Future<void> show(BuildContext context) => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => const FilterSheet(),
      );

  @override
  ConsumerState<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<FilterSheet> {
  static const _priceSteps = [5000, 10000, 15000, 20000]; // kuruş
  late DiscoverFilter _draft = ref.read(discoverFilterProvider);

  void _set(DiscoverFilter f) => setState(() => _draft = f);

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Filtreler', style: t.textTheme.titleLarge),
            const SizedBox(height: 16),
            Text('Kategori', style: t.textTheme.titleSmall),
            Wrap(spacing: 8, children: [
              ChoiceChip(
                label: const Text('Tümü'),
                selected: _draft.category == null,
                onSelected: (_) => _set(_copy(category: null)),
              ),
              for (final c in BusinessCategory.values)
                ChoiceChip(
                  label: Text(c.label),
                  selected: _draft.category == c,
                  onSelected: (_) => _set(_copy(category: c)),
                ),
            ]),
            const SizedBox(height: 16),
            Text('Mesafe', style: t.textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<int>(
              segments: [
                for (final km in DiscoverFilter.radiusOptionsKm)
                  ButtonSegment(value: km, label: Text('$km km')),
              ],
              selected: {_draft.radiusKm},
              onSelectionChanged: (s) => _set(_copy(radiusKm: s.first)),
            ),
            const SizedBox(height: 16),
            Text('En fazla fiyat', style: t.textTheme.titleSmall),
            Wrap(spacing: 8, children: [
              ChoiceChip(
                label: const Text('Farketmez'),
                selected: _draft.maxPrice == null,
                onSelected: (_) => _set(_copy(maxPrice: null)),
              ),
              for (final p in _priceSteps)
                ChoiceChip(
                  label: Text(Fmt.kurus(p)),
                  selected: _draft.maxPrice == p,
                  onSelected: (_) => _set(_copy(maxPrice: p)),
                ),
            ]),
            const SizedBox(height: 16),
            Text('Teslim saati', style: t.textTheme.titleSmall),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.schedule),
              title: Text(_draft.pickupAfter == null
                  ? 'Farketmez'
                  : '${_draft.pickupAfter!.format(context)} ve sonrası'),
              trailing: _draft.pickupAfter == null
                  ? null
                  : IconButton(
                      tooltip: 'Temizle',
                      icon: const Icon(Icons.close),
                      onPressed: () => _set(_copy(pickupAfter: null)),
                    ),
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: _draft.pickupAfter ?? TimeOfDay.now(),
                );
                if (picked != null) _set(_copy(pickupAfter: picked));
              },
            ),
            const SizedBox(height: 16),
            Row(children: [
              TextButton(
                onPressed: () => _set(const DiscoverFilter()),
                child: const Text('Temizle'),
              ),
              const Spacer(),
              FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size(140, 48)),
                onPressed: () {
                  ref.read(discoverFilterProvider.notifier).apply(_draft);
                  Navigator.pop(context);
                },
                child: const Text('Uygula'),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  static const _keep = Object();
  DiscoverFilter _copy({
    Object? category = _keep,
    int? radiusKm,
    Object? maxPrice = _keep,
    Object? pickupAfter = _keep,
  }) =>
      DiscoverFilter(
        category: identical(category, _keep) ? _draft.category : category as BusinessCategory?,
        radiusKm: radiusKm ?? _draft.radiusKm,
        maxPrice: identical(maxPrice, _keep) ? _draft.maxPrice : maxPrice as int?,
        pickupAfter:
            identical(pickupAfter, _keep) ? _draft.pickupAfter : pickupAfter as TimeOfDay?,
      );
}
