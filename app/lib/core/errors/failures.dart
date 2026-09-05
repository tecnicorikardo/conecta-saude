import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Sem conexão com a internet.']);
}

class ServerFailure extends Failure {
  final int? statusCode;
  const ServerFailure(super.message, {this.statusCode});

  @override
  List<Object> get props => [message, statusCode ?? 0];
}

class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

class UserInactiveFailure extends Failure {
  const UserInactiveFailure()
      : super('Seu acesso está inativo. Entre em contato com o RH.');
}

class UserNotFoundFailure extends Failure {
  const UserNotFoundFailure()
      : super('Usuário não encontrado no sistema.');
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure()
      : super('Você não tem permissão para realizar esta ação.');
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Erro ao acessar dados locais.']);
}

class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'Ocorreu um erro inesperado.']);
}
