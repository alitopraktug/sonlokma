import 'package:flutter/material.dart';

/// Paketsiz, hafif "iskelet" yükleme görünümü. Altındaki tüm [SkeletonBox]'lar
/// tek bir animasyonla birlikte nefes alır (her kutu ayrı controller açmaz).
class SkeletonScope extends StatefulWidget {
  const SkeletonScope({super.key, required this.child});
  final Widget child;

  @override
  State<SkeletonScope> createState() => _SkeletonScopeState();
}

class _SkeletonScopeState extends State<SkeletonScope> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Yükleniyor',
        child: ExcludeSemantics(
          child: FadeTransition(
            opacity: Tween<double>(begin: 0.45, end: 1).animate(_c),
            child: widget.child,
          ),
        ),
      );
}

class SkeletonBox extends StatelessWidget {
  const SkeletonBox({super.key, this.width, required this.height, this.radius = 8});
  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(radius),
        ),
      );
}

/// Paket kartı / sipariş satırı biçiminde iskelet liste.
class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, this.count = 6, this.thumbnail = true});
  final int count;
  final bool thumbnail;

  @override
  Widget build(BuildContext context) => SkeletonScope(
        child: ListView.builder(
          key: const Key('skeleton_list'),
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
          itemCount: count,
          itemBuilder: (_, __) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(children: [
              if (thumbnail) ...[
                const SkeletonBox(width: 96, height: 96),
                const SizedBox(width: 12),
              ],
              const Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  SkeletonBox(width: 90, height: 12),
                  SizedBox(height: 8),
                  SkeletonBox(height: 16),
                  SizedBox(height: 8),
                  SkeletonBox(width: 140, height: 12),
                  SizedBox(height: 8),
                  SkeletonBox(width: 70, height: 16),
                ]),
              ),
            ]),
          ),
        ),
      );
}
