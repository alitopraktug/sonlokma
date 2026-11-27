/// Kontrat pagination formatı: `{ items: [...], nextCursor: "..." | null }`.
class CursorPage<T> {
  const CursorPage({required this.items, required this.nextCursor});
  final List<T> items;
  final String? nextCursor;

  bool get isLast => nextCursor == null;

  static CursorPage<T> fromJson<T>(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) itemFromJson,
  ) =>
      CursorPage(
        items: (json['items'] as List)
            .map((e) => itemFromJson(e as Map<String, dynamic>))
            .toList(growable: false),
        nextCursor: json['nextCursor'] as String?,
      );
}
