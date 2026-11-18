/// Danh sách phân trang offset `{ items, total, page, pageSize }` (spec §5.5, G12).
class Paginated<T> {
  const Paginated({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  factory Paginated.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) item,
  ) => Paginated(
    items: [
      for (final e in json['items'] as List) item(e as Map<String, dynamic>),
    ],
    total: json['total'] as int,
    page: json['page'] as int,
    pageSize: json['pageSize'] as int,
  );

  final List<T> items;
  final int total;
  final int page;
  final int pageSize;

  bool get hasMore => page * pageSize < total;
}
