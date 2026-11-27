import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/auth_controller.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/utils/formatters.dart';
import '../data/profile_repository_impl.dart';
import '../domain/profile.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _deleteAccount(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Hesabını sil'),
        content: const Text(
          'Hesabın silinecek ve kişisel verilerin anonimleştirilecek (KVKK). '
          'Bu işlem geri alınamaz.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Vazgeç')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(c).colorScheme.error),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(profileRepositoryProvider).deleteAccount();
      await ref.read(authControllerProvider.notifier).logout();
    } on ApiError catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.userMessage)));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(profileProvider);
    final t = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: TextButton(
            onPressed: () => ref.invalidate(profileProvider),
            child: Text('${e is ApiError ? e.userMessage : 'Profil yüklenemedi.'} Tekrar dene'),
          ),
        ),
        data: (p) => RefreshIndicator(
          onRefresh: () => ref.refresh(profileProvider.future),
          child: ListView(padding: const EdgeInsets.all(16), children: [
            ListTile(
              leading: CircleAvatar(child: Text(p.user.name.isEmpty ? '?' : p.user.name[0])),
              title: Text(p.user.name, style: t.textTheme.titleLarge),
              subtitle: Text(p.user.email),
            ),
            const SizedBox(height: 16),
            Text('Sosyal etki', style: t.textTheme.titleMedium),
            const SizedBox(height: 8),
            _ImpactGrid(p.impact),
            const SizedBox(height: 24),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Çıkış yap'),
              onTap: () => ref.read(authControllerProvider.notifier).logout(),
            ),
            ListTile(
              leading: Icon(Icons.delete_forever_outlined, color: t.colorScheme.error),
              title: Text('Hesabımı sil', style: TextStyle(color: t.colorScheme.error)),
              onTap: () => _deleteAccount(context, ref),
            ),
          ]),
        ),
      ),
    );
  }
}

class _ImpactGrid extends StatelessWidget {
  const _ImpactGrid(this.i);
  final Impact i;

  @override
  Widget build(BuildContext context) => GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.4,
        children: [
          _ImpactTile(Icons.shopping_bag_outlined, 'kurtarılan paket', i.packagesSaved.toDouble(),
              (v) => v.round().toString()),
          _ImpactTile(Icons.scale_outlined, 'israf önlendi', i.kgSaved,
              (v) => '${v.toStringAsFixed(1).replaceAll('.', ',')} kg'),
          _ImpactTile(Icons.savings_outlined, 'tasarruf', i.moneySaved.toDouble(),
              (v) => Fmt.kurus(v.round())),
          _ImpactTile(Icons.cloud_outlined, 'CO₂e önlendi (yaklaşık)', i.co2Kg,
              (v) => '${v.toStringAsFixed(1).replaceAll('.', ',')} kg'),
        ],
      );
}

/// 0'dan hedefe sayan basit animasyon (rol dosyası: "basit bir animasyon ekle").
class _ImpactTile extends StatelessWidget {
  const _ImpactTile(this.icon, this.label, this.value, this.format);
  final IconData icon;
  final String label;
  final double value;
  final String Function(double) format;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Card(
      color: t.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: value),
          duration: const Duration(milliseconds: 1200),
          curve: Curves.easeOutCubic,
          builder: (_, v, __) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: t.colorScheme.onPrimaryContainer),
              Text(format(v),
                  style: t.textTheme.headlineSmall
                      ?.copyWith(color: t.colorScheme.onPrimaryContainer)),
              Text(label,
                  style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onPrimaryContainer)),
            ],
          ),
        ),
      ),
    );
  }
}
