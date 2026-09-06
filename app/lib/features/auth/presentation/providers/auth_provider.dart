import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../data/repositories/auth_repository_impl.dart';

// ─── Repository provider ─────────────────────────────────────────────────────
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(ref);
});

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
class LoginNotifier extends StateNotifier<LoginState> {
  final Ref _ref;
  LoginNotifier(this._ref) : super(const LoginInitial());

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const LoginLoading();

    final repository = _ref.read(authRepositoryProvider);
    final result = await repository.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    if (!mounted) return;
    result.fold(
      (failure) => state = LoginError(failure.message),
      (user) => state = LoginSuccess(user),
    );
  }

  void reset() {
    if (mounted) state = const LoginInitial();
  }
}

final loginNotifierProvider =
    StateNotifierProvider.autoDispose<LoginNotifier, LoginState>((ref) {
  return LoginNotifier(ref);
});

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

class ForgotPasswordNotifier extends StateNotifier<ForgotPasswordState> {
  final Ref _ref;
  ForgotPasswordNotifier(this._ref) : super(const ForgotPasswordInitial());

  Future<void> sendResetEmail(String email) async {
    state = const ForgotPasswordLoading();

    final repository = _ref.read(authRepositoryProvider);
    final result = await repository.sendPasswordResetEmail(email: email.trim());

    if (!mounted) return;
    result.fold(
      (failure) => state = ForgotPasswordError(failure.message),
      (_) => state = const ForgotPasswordSuccess(),
    );
  }

  void reset() {
    if (mounted) state = const ForgotPasswordInitial();
  }
}

final forgotPasswordNotifierProvider = StateNotifierProvider.autoDispose<
    ForgotPasswordNotifier, ForgotPasswordState>((ref) {
  return ForgotPasswordNotifier(ref);
});

// ─── RegisterNotifier ────────────────────────────────────────────────────────
sealed class RegisterState {
  const RegisterState();
}

class RegisterInitial extends RegisterState {
  const RegisterInitial();
}

class RegisterLoading extends RegisterState {
  const RegisterLoading();
}

class RegisterSuccess extends RegisterState {
  final String message;
  final String nome;
  final String email;
  final String setorNome;
  const RegisterSuccess({
    required this.message,
    required this.nome,
    required this.email,
    required this.setorNome,
  });
}

class RegisterError extends RegisterState {
  final String message;
  const RegisterError(this.message);
}

class RegisterNotifier extends StateNotifier<RegisterState> {
  final Ref _ref;
  RegisterNotifier(this._ref) : super(const RegisterInitial());

  Future<void> register({
    required String nome,
    required String email,
    required String password,
    required String cargo,
    required String setorId,
    String? matricula,
  }) async {
    state = const RegisterLoading();
    final repository = _ref.read(authRepositoryProvider);
    final result = await repository.register(
      nome: nome,
      email: email,
      password: password,
      cargo: cargo,
      setorId: setorId,
      matricula: matricula,
    );

    if (!mounted) return;
    result.fold(
      (failure) => state = RegisterError(failure.message),
      (data) {
        final userData = data['data'] as Map<String, dynamic>? ?? {};
        state = RegisterSuccess(
          message: data['message'] as String? ?? 'Cadastro realizado com sucesso!',
          nome: userData['nome'] as String? ?? nome,
          email: userData['email'] as String? ?? email,
          setorNome: userData['setorNome'] as String? ?? '',
        );
      },
    );
  }

  void reset() {
    if (mounted) state = const RegisterInitial();
  }
}

final registerNotifierProvider =
    StateNotifierProvider.autoDispose<RegisterNotifier, RegisterState>((ref) {
  return RegisterNotifier(ref);
});

// ─── Usuário atual ────────────────────────────────────────────────────────────
final authStateProvider = StreamProvider<UserEntity?>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return repository.authStateChanges;
});
