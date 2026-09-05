import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../data/repositories/auth_repository_impl.dart';

part 'auth_provider.g.dart';

// ─── Repository provider ─────────────────────────────────────────────────────
@riverpod
AuthRepository authRepository(Ref ref) {
  return AuthRepositoryImpl(ref);
}

// ─── Estado do login ─────────────────────────────────────────────────────────
sealed class LoginState {
  const LoginState();
}

class LoginInitial extends LoginState {
  const LoginInitial();
}

class LoginLoading extends LoginState {
  const LoginLoading();
}

class LoginSuccess extends LoginState {
  final UserEntity user;
  const LoginSuccess(this.user);
}

class LoginError extends LoginState {
  final String message;
  const LoginError(this.message);
}

// ─── LoginNotifier ────────────────────────────────────────────────────────────
@riverpod
class LoginNotifier extends _$LoginNotifier {
  @override
  LoginState build() => const LoginInitial();

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const LoginLoading();

    final repository = ref.read(authRepositoryProvider);
    final result = await repository.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    result.fold(
      (failure) => state = LoginError(failure.message),
      (user) => state = LoginSuccess(user),
    );
  }

  void reset() => state = const LoginInitial();
}

// ─── ForgotPasswordNotifier ───────────────────────────────────────────────────
sealed class ForgotPasswordState {
  const ForgotPasswordState();
}

class ForgotPasswordInitial extends ForgotPasswordState {
  const ForgotPasswordInitial();
}

class ForgotPasswordLoading extends ForgotPasswordState {
  const ForgotPasswordLoading();
}

class ForgotPasswordSuccess extends ForgotPasswordState {
  const ForgotPasswordSuccess();
}

class ForgotPasswordError extends ForgotPasswordState {
  final String message;
  const ForgotPasswordError(this.message);
}

@riverpod
class ForgotPasswordNotifier extends _$ForgotPasswordNotifier {
  @override
  ForgotPasswordState build() => const ForgotPasswordInitial();

  Future<void> sendResetEmail(String email) async {
    state = const ForgotPasswordLoading();

    final repository = ref.read(authRepositoryProvider);
    final result = await repository.sendPasswordResetEmail(email: email.trim());

    result.fold(
      (failure) => state = ForgotPasswordError(failure.message),
      (_) => state = const ForgotPasswordSuccess(),
    );
  }

  void reset() => state = const ForgotPasswordInitial();
}

// ─── Usuário atual ────────────────────────────────────────────────────────────
@riverpod
Stream<UserEntity?> authState(Ref ref) {
  final repository = ref.watch(authRepositoryProvider);
  return repository.authStateChanges;
}
