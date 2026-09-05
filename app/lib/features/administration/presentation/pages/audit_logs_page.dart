import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/current_user_provider.dart';

// ─── Entidade Mock ────────────────────────────────────────────────────────────

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

// ─── Mock Data ────────────────────────────────────────────────────────────────

final _auditLogsProvider = FutureProvider<List<AuditLogEntity>>((ref) async {
  await Future.delayed(const Duration(milliseconds: 500));
  return [
    AuditLogEntity(
      id: 'log-001',
      acao: AuditAction.userCreated,
      atorNome: 'Carlos Eduardo Mendes',
      atorSetor: 'Direção Geral',
      alvoNome: 'Larissa Nogueira',
      descricao: 'Novo funcionário cadastrado: Larissa Nogueira (CCE).',
      criadoEm: DateTime.now().subtract(const Duration(hours: 1)),
      ip: '192.168.1.10',
    ),
    AuditLogEntity(
      id: 'log-002',
      acao: AuditAction.announcementCreated,
      atorNome: 'Dra. Juliana Moreira',
      atorSetor: 'CCDTI',
      descricao: 'Comunicado "Manutenção do Tomógrafo" publicado.',
      criadoEm: DateTime.now().subtract(const Duration(hours: 3)),
      ip: '192.168.1.22',
    ),
    AuditLogEntity(
      id: 'log-003',
      acao: AuditAction.userDeactivated,
      atorNome: 'Carlos Eduardo Mendes',
      atorSetor: 'Direção Geral',
      alvoNome: 'Funcionário Inativo',
      descricao: 'Conta desativada por inatividade prolongada.',
      criadoEm: DateTime.now().subtract(const Duration(hours: 6)),
      ip: '192.168.1.10',
    ),
    AuditLogEntity(
      id: 'log-004',
      acao: AuditAction.messageDeleted,
      atorNome: 'Carlos Eduardo Mendes',
      atorSetor: 'Direção Geral',
      descricao: 'Mensagem removida por violação das diretrizes de uso.',
      criadoEm: DateTime.now().subtract(const Duration(hours: 10)),
      ip: '192.168.1.10',
    ),
    AuditLogEntity(
      id: 'log-005',
      acao: AuditAction.reportUpdated,
      atorNome: 'Carlos Eduardo Mendes',
      atorSetor: 'Direção Geral',
      descricao: 'Denúncia #rep-003 movida para "Em Análise".',
      criadoEm: DateTime.now().subtract(const Duration(hours: 14)),
      ip: '192.168.1.10',
    ),
    AuditLogEntity(
      id: 'log-006',
      acao: AuditAction.loginSuccess,
      atorNome: 'Dr. Roberto Vasconcelos',
      atorSetor: 'CCO',
      descricao: 'Login realizado com sucesso.',
      criadoEm: DateTime.now().subtract(const Duration(hours: 16)),
      ip: '192.168.1.45',
    ),
    AuditLogEntity(
      id: 'log-007',
      acao: AuditAction.loginFailed,
      atorNome: 'Desconhecido',
      atorSetor: '—',
      descricao: 'Tentativa de login falhou — credenciais inválidas.',
      criadoEm: DateTime.now().subtract(const Duration(hours: 20)),
      ip: '177.34.10.201',
    ),
    AuditLogEntity(
      id: 'log-008',
      acao: AuditAction.userUpdated,
      atorNome: 'Carlos Eduardo Mendes',
      atorSetor: 'Direção Geral',
      alvoNome: 'Gabriel Mendes',
      descricao: 'Cargo atualizado: Assistente de Regulação → Coordenador Assistente.',
      criadoEm: DateTime.now().subtract(const Duration(days: 1)),
      ip: '192.168.1.10',
    ),
    AuditLogEntity(
      id: 'log-009',
      acao: AuditAction.messageEdited,
      atorNome: 'Paula Souza',
      atorSetor: 'CCO',
      descricao: 'Mensagem editada dentro do prazo de 5 minutos.',
      criadoEm: DateTime.now().subtract(const Duration(days: 1, hours: 4)),
      ip: '192.168.1.33',
    ),
    AuditLogEntity(
      id: 'log-010',
      acao: AuditAction.userReactivated,
      atorNome: 'Carlos Eduardo Mendes',
      atorSetor: 'Direção Geral',
      alvoNome: 'Ex-Funcionário',
      descricao: 'Conta reativada a pedido do RH.',
      criadoEm: DateTime.now().subtract(const Duration(days: 2)),
      ip: '192.168.1.10',
    ),
  ];
});

// ─── Page ─────────────────────────────────────────────────────────────────────

class AuditLogsPage extends ConsumerStatefulWidget {
  const AuditLogsPage({super.key});

  @override
  ConsumerState<AuditLogsPage> createState() => _AuditLogsPageState();
}

class _AuditLogsPageState extends ConsumerState<AuditLogsPage> {
  AuditAction? _selectedAction;

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final isDirecao = currentUser?.isDirecao ?? false;
    final logsAsync = ref.watch(_auditLogsProvider);

    if (!isDirecao) {
      return Scaffold(
        appBar: AppBar(title: const Text('Log de Auditoria')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline, size: 56, color: AppColors.neutral500),
                SizedBox(height: 16),
                Text(
                  'Acesso Restrito',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.neutral800,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Os logs de auditoria são exclusivos para a Direção Geral.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.neutral600),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Log de Auditoria'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(_auditLogsProvider),
          ),
        ],
      ),
      body: logsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              const Text('Erro ao carregar logs.'),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar novamente'),
                onPressed: () => ref.invalidate(_auditLogsProvider),
              ),
            ],
          ),
        ),
        data: (logs) {
          final filtered = _selectedAction == null
              ? logs
              : logs.where((l) => l.acao == _selectedAction).toList();

          return Column(
            children: [
              // ─── Filtros ─────────────────────────────────────────────
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    _ActionChip(
                      label: 'Todos',
                      isSelected: _selectedAction == null,
                      onTap: () => setState(() => _selectedAction = null),
                    ),
                    ...{
                      AuditAction.userCreated: 'Usuário criado',
                      AuditAction.userDeactivated: 'Desativado',
                      AuditAction.messageDeleted: 'Msg excluída',
                      AuditAction.loginFailed: 'Login falho',
                    }.entries.map(
                          (e) => Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: _ActionChip(
                              label: e.value,
                              isSelected: _selectedAction == e.key,
                              onTap: () =>
                                  setState(() => _selectedAction = e.key),
                            ),
                          ),
                        ),
                  ],
                ),
              ),

              // ─── Contador ────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text(
                      '${filtered.length} registro${filtered.length != 1 ? 's' : ''}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.neutral600,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),

              // ─── Timeline ────────────────────────────────────────────
              Expanded(
                child: filtered.isEmpty
                    ? const Center(
                        child: Text('Nenhum log encontrado.'),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          return _AuditLogTile(log: filtered[index]);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─── Widgets ──────────────────────────────────────────────────────────────────

class _ActionChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ActionChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primary.withValues(alpha: 0.12),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        color: isSelected ? AppColors.primary : AppColors.neutral700,
      ),
      side: BorderSide(
        color:
            isSelected ? AppColors.primary : AppColors.outlineVariant,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}

class _AuditLogTile extends StatelessWidget {
  final AuditLogEntity log;

  const _AuditLogTile({required this.log});

  @override
  Widget build(BuildContext context) {
    final color = _actionColor(log.acao);
    final icon = _actionIcon(log.acao);
    final label = _actionLabel(log.acao);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ícone na linha do tempo
          Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 17, color: color),
              ),
              Container(
                width: 1.5,
                height: 28,
                color: AppColors.outlineVariant,
              ),
            ],
          ),
          const SizedBox(width: 12),

          // Conteúdo
          Expanded(
            child: Card(
              elevation: 0,
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: color,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _formatDate(log.criadoEm),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.neutral500,
                                    fontSize: 10,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      log.descricao,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.neutral800,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.person_outline,
                            size: 11, color: AppColors.neutral500),
                        const SizedBox(width: 3),
                        Text(
                          '${log.atorNome} · ${log.atorSetor}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.neutral500,
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.router_outlined,
                            size: 11, color: AppColors.neutral500),
                        const SizedBox(width: 3),
                        Text(
                          log.ip,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.neutral500,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inHours < 1) return 'há ${diff.inMinutes}min';
    if (diff.inHours < 24) return 'há ${diff.inHours}h';
    return 'há ${diff.inDays}d';
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

Color _actionColor(AuditAction action) {
  switch (action) {
    case AuditAction.userCreated:
    case AuditAction.userReactivated:
      return AppColors.success;
    case AuditAction.userDeactivated:
    case AuditAction.messageDeleted:
    case AuditAction.loginFailed:
      return AppColors.error;
    case AuditAction.userUpdated:
    case AuditAction.messageEdited:
    case AuditAction.reportUpdated:
      return AppColors.warning;
    case AuditAction.announcementCreated:
    case AuditAction.loginSuccess:
      return AppColors.primary;
  }
}

IconData _actionIcon(AuditAction action) {
  switch (action) {
    case AuditAction.userCreated:
      return Icons.person_add_rounded;
    case AuditAction.userUpdated:
      return Icons.edit_rounded;
    case AuditAction.userDeactivated:
      return Icons.person_off_rounded;
    case AuditAction.userReactivated:
      return Icons.person_add_alt_1_rounded;
    case AuditAction.messageDeleted:
      return Icons.delete_rounded;
    case AuditAction.messageEdited:
      return Icons.edit_note_rounded;
    case AuditAction.announcementCreated:
      return Icons.campaign_rounded;
    case AuditAction.reportUpdated:
      return Icons.report_rounded;
    case AuditAction.loginSuccess:
      return Icons.login_rounded;
    case AuditAction.loginFailed:
      return Icons.no_accounts_rounded;
  }
}

String _actionLabel(AuditAction action) {
  switch (action) {
    case AuditAction.userCreated:
      return 'USUÁRIO CRIADO';
    case AuditAction.userUpdated:
      return 'USUÁRIO EDITADO';
    case AuditAction.userDeactivated:
      return 'DESATIVADO';
    case AuditAction.userReactivated:
      return 'REATIVADO';
    case AuditAction.messageDeleted:
      return 'MSG EXCLUÍDA';
    case AuditAction.messageEdited:
      return 'MSG EDITADA';
    case AuditAction.announcementCreated:
      return 'COMUNICADO';
    case AuditAction.reportUpdated:
      return 'DENÚNCIA';
    case AuditAction.loginSuccess:
      return 'LOGIN OK';
    case AuditAction.loginFailed:
      return 'LOGIN FALHO';
  }
}
