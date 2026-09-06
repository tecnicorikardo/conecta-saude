import '../../../auth/domain/entities/user_entity.dart';

class PaginatedUsers {
  final List<UserEntity> items;
  final int total;
  final int page;
  final int limit;
  final bool hasMore;

  const PaginatedUsers({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
    required this.hasMore,
  });
}
