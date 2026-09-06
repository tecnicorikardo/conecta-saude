import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/http_service.dart';

enum AuditAction {
  userCreated,
  userUpdated,
  userDeactivated,
  userReactivated,
  messageDeleted,
  messageEdited,
  announcementCreated,
  reportUpdated,
  loginSuccess,
  loginFailed,
}

class AuditLogEntity {
  final String id;
  final AuditAction acao;
  final String atorNome;
  final String atorSetor;
  final String? alvoNome;
  final String descricao;
  final DateTime criadoEm;
  final String ip;

  const AuditLogEntity({
    required this.id,
    required this.acao,
    required this.atorNome,
    required this.atorSetor,
    required this.descricao,
    required this.criadoEm,
    required this.ip,
    this.alvoNome,
  });
}

class AuditRepository {
  final HttpService _http;

  AuditRepository(this._http);

  Future<List<AuditLogEntity>> listAuditLogs({
    int page = 1,
    int limit = 50,
    String? acao,
    String? userId,
  }) async {
    try {
      final response = await _http.get(
        '/admin/audit-logs',
        queryParameters: {
          'page': page,
          'limit': limit,
          if (acao != null) 'acao': acao,
          if (userId != null) 'userId': userId,
        },
      );

      final data = response.data['data'] as Map<String, dynamic>? ?? {};
      final items = data['items'] as List? ?? [];

      return items.map((j) => _fromJson(j as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  static AuditAction _parseAction(String acao) {
    switch (acao.toLowerCase()) {
      case 'criar_usuario':
      case 'usercreated':
        return AuditAction.userCreated;
      case 'editar_usuario':
      case 'userupdated':
        return AuditAction.userUpdated;
      case 'desativar_usuario':
      case 'userdeactivated':
        return AuditAction.userDeactivated;
      case 'ativar_usuario':
      case 'userreactivated':
        return AuditAction.userReactivated;
      case 'excluir_mensagem_moderacao':
      case 'messagedeleted':
        return AuditAction.messageDeleted;
      case 'editar_mensagem':
      case 'messageedited':
        return AuditAction.messageEdited;
      case 'criar_comunicado':
      case 'announcementcreated':
        return AuditAction.announcementCreated;
      case 'criar_canal':
      case 'reportupdated':
        return AuditAction.reportUpdated;
      case 'login_sucesso':
      case 'loginsuccess':
        return AuditAction.loginSuccess;
      default:
        return AuditAction.userUpdated;
    }
  }

  static AuditLogEntity _fromJson(Map<String, dynamic> j) {
    final user = j['user'] as Map<String, dynamic>?;
    final acaoStr = j['acao'] as String? ?? '';
    final entidade = j['entidade'] as String? ?? '';

    return AuditLogEntity(
      id: j['id'] as String,
      acao: _parseAction(acaoStr),
      atorNome: user?['nome'] as String? ?? 'Sistema',
      atorSetor: user?['cargo'] as String? ?? 'Direção Geral',
      descricao: 'Ação: $acaoStr sobre $entidade (${j['entidadeId'] ?? ''})',
      criadoEm: DateTime.tryParse(j['criadoEm'] as String? ?? '')?.toLocal() ?? DateTime.now(),
      ip: j['ip'] as String? ?? '127.0.0.1',
    );
  }

  Exception _handleError(DioException e) {
    final msg = e.response?.data?['error'] as String?;
    final status = e.response?.statusCode;
    if (status == 401) return Exception('Sessão expirada.');
    if (status == 403) return Exception(msg ?? 'Acesso exclusivo da Direção Geral.');
    return Exception(msg ?? 'Erro ao carregar logs de auditoria.');
  }
}

final auditRepositoryProvider = Provider<AuditRepository>((ref) {
  final http = ref.watch(httpServiceProvider);
  return AuditRepository(http);
});
