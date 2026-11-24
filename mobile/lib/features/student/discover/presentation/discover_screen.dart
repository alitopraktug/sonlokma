import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/discover_filter_provider.dart';
import 'providers/location_provider.dart';
import 'widgets/filter_sheet.dart';
import 'widgets/package_list_view.dart';
import 'widgets/package_map_view.dart';

enum _Mode { map, list }

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  _Mode _mode = _Mode.map;
  bool _bannerDismissed = false;

  @override
  Widget build(BuildContext context) {
    final filterCount = ref.watch(discoverFilterProvider.select((f) => f.activeCount));
    final isFallback = ref.watch(userLocationProvider).valueOrNull?.isFallback ?? false;

    return Scaffold(
      appBar: AppBar(
        title: SegmentedButton<_Mode>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: _Mode.map, icon: Icon(Icons.map_outlined), label: Text('Harita')),
            ButtonSegment(value: _Mode.list, icon: Icon(Icons.list), label: Text('Liste')),
          ],
          selected: {_mode},
          onSelectionChanged: (s) => setState(() => _mode = s.first),
        ),
        actions: [
          IconButton(
            tooltip: 'Filtreler',
            onPressed: () => FilterSheet.show(context),
            icon: Badge(
              isLabelVisible: filterCount > 0,
              label: Text('$filterCount'),
              child: const Icon(Icons.tune),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (isFallback && !_bannerDismissed)
            MaterialBanner(
              leading: const Icon(Icons.location_off_outlined),
              // KVKK: konumu neden istediğimizi ve reddedince ne olduğunu açıkça söylüyoruz.
              content: const Text(
                'Konum iznin olmadığı için kampüs merkezini gösteriyoruz. Konumunu yalnızca '
                'yakındaki paketleri bulmak için kullanırız, kaydetmeyiz.',
              ),
              actions: [
                TextButton(
                  onPressed: () => setState(() => _bannerDismissed = true),
                  child: const Text('Tamam'),
                ),
                TextButton(
                  onPressed: () => ref.invalidate(userLocationProvider),
                  child: const Text('İzin ver'),
                ),
              ],
            ),
          Expanded(
            // IndexedStack: geçişte harita yeniden oluşturulmaz, kamera konumu korunur.
            child: IndexedStack(
              index: _mode.index,
              children: const [PackageMapView(), PackageListView()],
            ),
          ),
        ],
      ),
    );
  }
}
