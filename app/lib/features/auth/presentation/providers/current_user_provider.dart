import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/user_entity.dart';
import 'auth_provider.dart';

/// Provider do usuário autenticado atual.
/// Observa o stream de autenticação e expõe o UserEntity.
final currentUserProvider = StreamProvider<UserEntity?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});
