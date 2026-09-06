import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/http_service.dart';

enum ReportStatus { pendente, emAnalise, resolvido, arquivado }

enum ReportCategory {
  assedio,
  desvioConduta,
  infraestruturaRisco,
  fraudeRecursos,
  outro,
}

class ReportEntity {
  final String id;
  final String? titulo;
  final String descricao;
  final ReportCategory categoria;
  final String motivoRaw;
  final ReportStatus status;
  final bool anonimo;
  final String denuncianteNome;
  final String? denuncianteCargo;
  final String? denuncianteSetor;
  final String? reportedUserNome;
  final String? resposta;
  final String? resolvidoNome;
  final DateTime criadoEm;
  final DateTime? resolvidoEm;

  const ReportEntity({
    required this.id,
    this.titulo,
    required this.descricao,
    required this.categoria,
    required this.motivoRaw,
    required this.status,
    required this.anonimo,
    required this.denuncianteNome,
    this.denuncianteCargo,
    this.denuncianteSetor,
    this.reportedUserNome,
    this.resposta,
    this.resolvidoNome,
    required this.criadoEm,
    this.resolvidoEm,
  });

  bool get isAnonimo => anonimo;
}

class ReportsRepository {
  final HttpService _http;

  ReportsRepository(this._http);

  /// Listar denúncias para a Direção Geral (painel de moderação)
  Future<List<ReportEntity>> listReports({ReportStatus? status}) async {
    try {
      final statusStr = status != null ? _statusToString(status) : null;
      final response = await _http.get(
        '/reports',
        queryParameters: {
          if (statusStr != null) 'status': statusStr,
        },
      );

      final items = response.data['data'] as List? ?? [];
      return items.map((j) => _fromJson(j as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Listar denúncias submetidas pelo próprio usuário logado
  Future<List<ReportEntity>> getMyReports() async {
    try {
      final response = await _http.get('/reports/my');
      final items = response.data['data'] as List? ?? [];
      return items.map((j) => _fromJson(j as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Registrar nova denúncia ou manifestação
  Future<String> createReport({
    required String motivo,
    required String descricao,
    String? titulo,
    String? reportedUserId,
    String? messageId,
    bool anonimo = false,
  }) async {
    try {
      final response = await _http.post('/reports', data: {
        'motivo': motivo,
        'descricao': descricao,
        if (titulo != null && titulo.isNotEmpty) 'titulo': titulo,
        if (reportedUserId != null && reportedUserId.isNotEmpty)
          'reportedUserId': reportedUserId,
        if (messageId != null && messageId.isNotEmpty) 'messageId': messageId,
        'anonimo': anonimo,
      });
      return response.data['data']['id'] as String;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Atualizar status e resposta da denúncia (Direção Geral)
  Future<void> updateReportStatus(
    String id,
    ReportStatus status, {
    String? resposta,
  }) async {
    try {
      await _http.patch('/reports/$id/status', data: {
        'status': _statusToString(status),
        if (resposta != null && resposta.isNotEmpty) 'resposta': resposta,
      });
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  static String _statusToString(ReportStatus s) {
    switch (s) {
      case ReportStatus.pendente:
        return 'pendente';
      case ReportStatus.emAnalise:
        return 'em_analise';
      case ReportStatus.resolvido:
        return 'resolvido';
      case ReportStatus.arquivado:
        return 'arquivado';
    }
  }

  static ReportStatus _stringToStatus(String s) {
    switch (s) {
      case 'em_analise':
        return ReportStatus.emAnalise;
      case 'resolvido':
        return ReportStatus.resolvido;
      case 'arquivado':
        return ReportStatus.arquivado;
      default:
        return ReportStatus.pendente;
    }
  }

  static ReportCategory _stringToCategory(String m) {
    switch (m) {
      case 'assedio':
        return ReportCategory.assedio;
      case 'desvio_conduta':
      case 'comunicacao_impropria':
      case 'comportamento':
        return ReportCategory.desvioConduta;
      case 'infraestrutura_risco':
        return ReportCategory.infraestruturaRisco;
      case 'fraude_recursos':
      case 'irregularidade':
        return ReportCategory.fraudeRecursos;
      default:
        return ReportCategory.outro;
    }
  }

  static ReportEntity _fromJson(Map<String, dynamic> j) {
    final reporter = j['reporter'] as Map<String, dynamic>?;
    final reporterSetor = reporter?['setor'] as Map<String, dynamic>?;
    final reported = j['reportedUser'] as Map<String, dynamic>?;
    final resolvido = j['resolvido'] as Map<String, dynamic>?;
    final isAnonimo = j['anonimo'] as bool? ?? false;

    return ReportEntity(
      id: j['id'] as String,
      titulo: j['titulo'] as String?,
      descricao: j['descricao'] as String? ?? 'Sem descrição.',
      categoria: _stringToCategory(j['motivo'] as String? ?? 'outro'),
      motivoRaw: j['motivo'] as String? ?? 'outro',
      status: _stringToStatus(j['status'] as String? ?? 'pendente'),
      anonimo: isAnonimo,
      denuncianteNome: isAnonimo
          ? 'Denunciante Anônimo'
          : (reporter?['nome'] as String? ?? 'Servidor'),
      denuncianteCargo: isAnonimo ? 'Sigiloso' : reporter?['cargo'] as String?,
      denuncianteSetor: isAnonimo
          ? 'Identidade Ocultada'
          : (reporterSetor?['nome'] as String? ?? 'SUS'),
      reportedUserNome: reported?['nome'] as String?,
      resposta: j['resposta'] as String?,
      resolvidoNome: resolvido?['nome'] as String?,
      criadoEm:
          DateTime.tryParse(j['criadoEm'] as String? ?? '')?.toLocal() ??
              DateTime.now(),
      resolvidoEm: j['resolvidoEm'] != null
          ? DateTime.tryParse(j['resolvidoEm'] as String)?.toLocal()
          : null,
    );
  }

  Exception _handleError(DioException e) {
    final msg = e.response?.data?['error'] as String? ??
        e.response?.data?['message'] as String?;
    final status = e.response?.statusCode;
    if (status == 401) return Exception('Sessão expirada.');
    if (status == 403) {
      return Exception(msg ??
          'Acesso restrito à Direção Geral para proteção do sigilo das denúncias.');
    }
    return Exception(msg ?? 'Erro ao comunicar com o servidor.');
  }
}

final reportsRepositoryProvider = Provider<ReportsRepository>((ref) {
  final http = ref.watch(httpServiceProvider);
  return ReportsRepository(http);
});

