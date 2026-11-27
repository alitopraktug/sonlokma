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

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> with WidgetsBindingObserver {
  _Mode _mode = _Mode.map;
  bool _bannerDismissed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Kullanıcı ayarlardan izin verip geri dönünce konumu yeniden dene.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    final loc = ref.read(userLocationProvider).valueOrNull;
    if (loc != null && loc.isFallback) ref.invalidate(userLocationProvider);
  }

  Future<void> _fixLocation(LocationIssue issue) async {
    if (issue == LocationIssue.denied || issue == LocationIssue.unavailable) {
      ref.invalidate(userLocationProvider); // sistem izin diyaloğu tekrar açılır
    } else {
      await ref.read(locationServiceProvider).openSettings(issue);
      // dönüşte didChangeAppLifecycleState yeniden dener
    }
  }

  @override
  Widget build(BuildContext context) {
    final filterCount = ref.watch(discoverFilterProvider.select((f) => f.activeCount));
    final issue = ref.watch(userLocationProvider).valueOrNull?.issue;

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
          if (issue != null && !_bannerDismissed)
            Builder(builder: (_) {
              final copy = locationIssueCopy(issue);
              return MaterialBanner(
                key: const Key('location_banner'),
                leading: const Icon(Icons.location_off_outlined),
                // KVKK: konumu neden istediğimizi ve reddedince ne olduğunu açıkça söylüyoruz.
                content: Text(copy.message),
                actions: [
                  TextButton(
                    onPressed: () => setState(() => _bannerDismissed = true),
                    child: const Text('Tamam'),
                  ),
                  TextButton(onPressed: () => _fixLocation(issue), child: Text(copy.action)),
                ],
              );
            }),
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
