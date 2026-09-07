import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/user_entity.dart';
import 'auth_provider.dart';

class CurrentUserNotifier extends StateNotifier<AsyncValue<UserEntity?>> {
  final Ref _ref;
  StreamSubscription<UserEntity?>? _sub;

  CurrentUserNotifier(this._ref) : super(const AsyncValue.loading()) {
    _init();
  }

  void _init() {
    final repository = _ref.read(authRepositoryProvider);
    _sub = repository.authStateChanges.listen(
      (user) {
        if (mounted) {
          state = AsyncValue.data(user);
        }
      },
      onError: (err, stack) {
        if (mounted) {
          state = const AsyncValue.data(null);
        }
      },
    );
  }

  void setUser(UserEntity? user) {
    if (mounted) {
      state = AsyncValue.data(user);
    }
  }

  void clear() {
    if (mounted) {
      state = const AsyncValue.data(null);
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final currentUserProvider =
    StateNotifierProvider<CurrentUserNotifier, AsyncValue<UserEntity?>>((ref) {
  return CurrentUserNotifier(ref);
});
