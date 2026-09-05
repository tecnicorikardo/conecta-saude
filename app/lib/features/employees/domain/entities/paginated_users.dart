import 'package:equatable/equatable.dart';
import '../../../auth/domain/entities/user_entity.dart';

/// Representação paginada da lista de usuários.
class PaginatedUsers extends Equatable {
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

  @override
  List<Object?> get props => [items, total, page, limit, hasMore];
}
