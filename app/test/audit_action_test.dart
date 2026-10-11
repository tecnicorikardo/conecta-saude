import 'package:flutter_test/flutter_test.dart';
import 'package:conecta_saude/features/administration/data/repositories/audit_repository.dart';
import 'api_failure_feedback_test.dart' show ResponseHttp;

void main() {
  test('auditoria distingue canal, denúncia, login falho e ação desconhecida',
      () async {
    final repo = AuditRepository(ResponseHttp()..body = {
      'data': {
        'items': [
          'criar_canal',
          'REPORT_CREATED',
          'REPORT_STATUS_UPDATED',
          'login_falha',
          'limpar_conversa_local'
        ]
            .map((action) => {
                  'id': action,
                  'acao': action,
                  'criadoEm': '2026-10-11T12:00:00Z'
                })
            .toList()
      }
    });
    final logs = await repo.listAuditLogs();
    expect(logs.map((e) => e.acao), [
      AuditAction.channelCreated,
      AuditAction.reportUpdated,
      AuditAction.reportUpdated,
      AuditAction.loginFailed,
      AuditAction.other
    ]);
    expect(logs.last.descricao, contains('limpar_conversa_local'));
  });
}
