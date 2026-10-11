import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:conecta_saude/core/errors/failures.dart';
import 'package:conecta_saude/core/services/http_service.dart';
import 'package:conecta_saude/features/employees/data/repositories/employees_repository_impl.dart';
import 'package:conecta_saude/features/emergency/data/repositories/emergency_repository_impl.dart';

class ResponseHttp implements HttpService {
  dynamic body;
  Object? error;
  @override
  Future<Response<T>> get<T>(String path,
      {Map<String, dynamic>? queryParameters}) async {
    if (error != null) throw error!;
    return Response<T>(
        requestOptions: RequestOptions(path: path), data: body as T);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  for (final status in [401, 403, 500]) {
    test('Falha HTTP $status não retorna funcionários de demonstração',
        () async {
      final http = ResponseHttp();
      final options = RequestOptions(path: '/users');
      http.error = DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          response: Response(requestOptions: options, statusCode: status));
      final result = await EmployeesRepositoryImpl(http).listUsers();
      expect(result.isLeft(), isTrue);
    });
  }
  test('Offline informa erro de conexão ao consultar colaboradores', () async {
    final http = ResponseHttp()
      ..error = DioException(
          requestOptions: RequestOptions(path: '/users'),
          type: DioExceptionType.connectionError);
    final result = await EmployeesRepositoryImpl(http).listUsers();
    expect(
        result.fold((failure) => failure, (_) => null), isA<NetworkFailure>());
  });
  test(
      'Resposta inesperada não vira lista fictícia nem lista vazia bem-sucedida',
      () async {
    final result =
        await EmployeesRepositoryImpl(ResponseHttp()..body = {'success': false})
            .listUsers();
    expect(result.isLeft(), isTrue);
  });
  test('Lista vazia confirmada pela API continua válida', () async {
    final result = await EmployeesRepositoryImpl(ResponseHttp()
          ..body = {
            'success': true,
            'data': {'items': [], 'total': 0, 'hasMore': false}
          })
        .listUsers();
    expect(result.isRight(), isTrue);
    expect(result.fold((_) => -1, (data) => data.total), 0);
  });
  test('Ausência de emergência somente é confirmada com resposta válida',
      () async {
    final repo = EmergencyRepositoryImpl(
        ResponseHttp()..body = {'success': true, 'data': null});
    expect(await repo.getActiveEmergency(), isNull);
  });
  test('Erro de rede na emergência não retorna ausência de alerta', () async {
    final repo =
        EmergencyRepositoryImpl(ResponseHttp()..error = Exception('offline'));
    await expectLater(repo.getActiveEmergency(), throwsException);
  });
  test('Resposta incompleta de emergência não retorna ausência de alerta',
      () async {
    final repo =
        EmergencyRepositoryImpl(ResponseHttp()..body = {'success': true});
    await expectLater(repo.getActiveEmergency(), throwsException);
  });
}
