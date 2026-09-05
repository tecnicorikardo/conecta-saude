import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/current_user_provider.dart';

// ─── Entidade Mock ────────────────────────────────────────────────────────────

enum ReportStatus { pendente, emAnalise, resolvido, arquivado }

enum ReportCategory { mensagem, comportamento, assedio, irregularidade, outro }

class ReportEntity {
  final String id;
  final String descricao;
  final ReportCategory categoria;
  final ReportStatus status;
  final String denuncianteNome;
  final String denuncianteSetor;
  final DateTime criadoEm;
  final String? observacaoAdmin;

  const ReportEntity({
    required this.id,
    required this.descricao,
    required this.categoria,
    required this.status,
    required this.denuncianteNome,
    required this.denuncianteSetor,
    required this.criadoEm,
    this.observacaoAdmin,
  });
}

// ─── Mock Data ────────────────────────────────────────────────────────────────

final _reportsProvider = FutureProvider<List<ReportEntity>>((ref) async {
  await Future.delayed(const Duration(milliseconds: 500));
  return [
    ReportEntity(
      id: 'rep-001',
      descricao:
          'Mensagem inadequada enviada no canal geral contendo linguagem ofensiva.',
      categoria: ReportCategory.mensagem,
      status: ReportStatus.pendente,
      denuncianteNome: 'Lucas Ribeiro',
      denuncianteSetor: 'CCDTI',
      criadoEm: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    ReportEntity(
      id: 'rep-002',
      descricao:
          'Funcionário relatou pressão inadequada de superior durante plantão noturno.',
      categoria: ReportCategory.assedio,
      status: ReportStatus.pendente,
      denuncianteNome: 'Paula Souza',
      denuncianteSetor: 'CCO',
      criadoEm: DateTime.now().subtract(const Duration(hours: 18)),
    ),
    ReportEntity(
      id: 'rep-003',
      descricao: 'Irregularidade no registro de ponto — ausências não justificadas.',
      categoria: ReportCategory.irregularidade,
      status: ReportStatus.emAnalise,
      denuncianteNome: 'Gabriel Mendes',
      denuncianteSetor: 'CCE',
      criadoEm: DateTime.now().subtract(const Duration(days: 2)),
      observacaoAdmin: 'Em verificação com o RH.',
    ),
    ReportEntity(
      id: 'rep-004',
      descricao: 'Comportamento inapropriado durante reunião de equipe.',
      categoria: ReportCategory.comportamento,
      status: ReportStatus.resolvido,
      denuncianteNome: 'Mariana Lima',
      denuncianteSetor: 'CCDTI',
      criadoEm: DateTime.now().subtract(const Duration(days: 5)),
      observacaoAdmin: 'Conversa realizada com o colaborador. Caso encerrado.',
    ),
    ReportEntity(
      id: 'rep-005',
      descricao: 'Problema técnico reportado — sistema de agendamento fora do ar.',
      categoria: ReportCategory.outro,
      status: ReportStatus.resolvido,
      denuncianteNome: 'Thiago Duarte',
      denuncianteSetor: 'CCO',
      criadoEm: DateTime.now().subtract(const Duration(days: 7)),
      observacaoAdmin: 'TI acionada e problema corrigido.',
    ),
    ReportEntity(
      id: 'rep-006',
      descricao: 'Denúncia arquivada — não foi possível comprovar a ocorrência.',
      categoria: ReportCategory.comportamento,
      status: ReportStatus.arquivado,
      denuncianteNome: 'Larissa Nogueira',
      denuncianteSetor: 'CCE',
      criadoEm: DateTime.now().subtract(const Duration(days: 10)),
      observacaoAdmin: 'Arquivado por falta de evidências.',
    ),
  ];
});

// ─── Page ─────────────────────────────────────────────────────────────────────

class ReportsPage extends ConsumerStatefulWidget {
  const ReportsPage({super.key});

  @override
  ConsumerState<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends ConsumerState<ReportsPage> {
  ReportStatus? _selectedStatus;

  @override
  Widget build(BuildContext context) {
    final reportsAsync = ref.watch(_reportsProvider);
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final isDirecao = currentUser?.isDirecao ?? false;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Denúncias e Ocorrências'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(_reportsProvider),
          ),
        ],
      ),
      body: reportsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              const Text('Erro ao carregar denúncias.'),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar novamente'),
                onPressed: () => ref.invalidate(_reportsProvider),
              ),
            ],
          ),
        ),
        data: (reports) {
          final filtered = _selectedStatus == null
              ? reports
              : reports.where((r) => r.status == _selectedStatus).toList();

          return Column(
            children: [
              // ─── Filtros ──────────────────────────────────────────────
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    _StatusChip(
                      label: 'Todos',
                      isSelected: _selectedStatus == null,
                      color: AppColors.neutral700,
                      onTap: () => setState(() => _selectedStatus = null),
                    ),
                    const SizedBox(width: 8),
                    _StatusChip(
                      label: 'Pendentes',
                      isSelected: _selectedStatus == ReportStatus.pendente,
                      color: AppColors.error,
                      onTap: () => setState(
                          () => _selectedStatus = ReportStatus.pendente),
                    ),
                    const SizedBox(width: 8),
                    _StatusChip(
                      label: 'Em análise',
                      isSelected: _selectedStatus == ReportStatus.emAnalise,
                      color: AppColors.warning,
                      onTap: () => setState(
                          () => _selectedStatus = ReportStatus.emAnalise),
                    ),
                    const SizedBox(width: 8),
                    _StatusChip(
                      label: 'Resolvidos',
                      isSelected: _selectedStatus == ReportStatus.resolvido,
                      color: AppColors.success,
                      onTap: () => setState(
                          () => _selectedStatus = ReportStatus.resolvido),
                    ),
                    const SizedBox(width: 8),
                    _StatusChip(
                      label: 'Arquivados',
                      isSelected: _selectedStatus == ReportStatus.arquivado,
                      color: AppColors.neutral500,
                      onTap: () => setState(
                          () => _selectedStatus = ReportStatus.arquivado),
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
                      '${filtered.length} ocorrência${filtered.length != 1 ? 's' : ''}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.neutral600,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),

              // ─── Lista ───────────────────────────────────────────────
              Expanded(
                child: filtered.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.report_off_rounded,
                                size: 52, color: AppColors.neutral500),
                            SizedBox(height: 12),
                            Text('Nenhuma ocorrência encontrada.'),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final report = filtered[index];
                          return _ReportCard(
                            report: report,
                            isDirecao: isDirecao,
                            onUpdateStatus: isDirecao
                                ? (newStatus, obs) =>
                                    _updateStatus(report, newStatus, obs)
                                : null,
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _updateStatus(
      ReportEntity report, ReportStatus newStatus, String? obs) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Status atualizado para: ${_statusLabel(newStatus)}'),
        backgroundColor: _statusColor(newStatus),
      ),
    );
    ref.invalidate(_reportsProvider);
  }
}

// ─── Widgets ──────────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _StatusChip({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: color.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        color: isSelected ? color : AppColors.neutral700,
      ),
      side: BorderSide(
        color: isSelected ? color : AppColors.outlineVariant,
      ),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final ReportEntity report;
  final bool isDirecao;
  final void Function(ReportStatus, String?)? onUpdateStatus;

  const _ReportCard({
    required this.report,
    required this.isDirecao,
    this.onUpdateStatus,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(report.status);
    final statusLabel = _statusLabel(report.status);
    final categoryLabel = _categoryLabel(report.categoria);
    final categoryIcon = _categoryIcon(report.categoria);

    return Card(
      elevation: 0,
      child: InkWell(
        onTap: () => _showDetail(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabeçalho
              Row(
                children: [
                  Icon(categoryIcon, size: 16, color: AppColors.neutral600),
                  const SizedBox(width: 6),
                  Text(
                    categoryLabel,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.neutral600,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Descrição
              Text(
                report.descricao,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const SizedBox(height: 8),

              // Rodapé
              Row(
                children: [
                  const Icon(Icons.person_outline,
                      size: 13, color: AppColors.neutral500),
                  const SizedBox(width: 4),
                  Text(
                    '${report.denuncianteNome} · ${report.denuncianteSetor}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.neutral500,
                          fontSize: 11,
                        ),
                  ),
                  const Spacer(),
                  Text(
                    _formatDate(report.criadoEm),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.neutral500,
                          fontSize: 11,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (_, controller) => _ReportDetailSheet(
          report: report,
          isDirecao: isDirecao,
          onUpdateStatus: onUpdateStatus,
          scrollController: controller,
        ),
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

class _ReportDetailSheet extends StatefulWidget {
  final ReportEntity report;
  final bool isDirecao;
  final void Function(ReportStatus, String?)? onUpdateStatus;
  final ScrollController scrollController;

  const _ReportDetailSheet({
    required this.report,
    required this.isDirecao,
    this.onUpdateStatus,
    required this.scrollController,
  });

  @override
  State<_ReportDetailSheet> createState() => _ReportDetailSheetState();
}

class _ReportDetailSheetState extends State<_ReportDetailSheet> {
  final _obsController = TextEditingController();

  @override
  void dispose() {
    _obsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.report;
    final statusColor = _statusColor(report.status);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: ListView(
        controller: widget.scrollController,
        padding: const EdgeInsets.all(24),
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.neutral400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Status badge
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _statusLabel(report.status),
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _categoryLabel(report.categoria),
                style: const TextStyle(
                  color: AppColors.neutral600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Descrição
          Text(
            'Descrição da Ocorrência',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.neutral600,
                  letterSpacing: 0.5,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            report.descricao,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 16),

          // Denunciante
          Card(
            elevation: 0,
            color: AppColors.surfaceVariant,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.person_outline,
                      size: 18, color: AppColors.neutral600),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(report.denuncianteNome,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text(
                        report.denuncianteSetor,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.neutral600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          if (report.observacaoAdmin != null) ...[
            const SizedBox(height: 16),
            Text(
              'Observação da Administração',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.neutral600,
                    letterSpacing: 0.5,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              report.observacaoAdmin!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],

          // Ações para Direção
          if (widget.isDirecao && report.status == ReportStatus.pendente) ...[
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 12),
            Text(
              'Atualizar Status',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _obsController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Observação (opcional)',
                hintText: 'Descreva as providências tomadas...',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.archive_outlined, size: 16),
                    label: const Text('Arquivar'),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.neutral600),
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onUpdateStatus?.call(
                          ReportStatus.arquivado, _obsController.text);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.manage_search_rounded, size: 16),
                    label: const Text('Em Análise'),
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onUpdateStatus?.call(
                          ReportStatus.emAnalise, _obsController.text);
                    },
                  ),
                ),
              ],
            ),
          ],

          if (widget.isDirecao &&
              report.status == ReportStatus.emAnalise) ...[
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 12),
            TextField(
              controller: _obsController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Observação da resolução',
                hintText: 'Descreva como a ocorrência foi resolvida...',
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                    backgroundColor: AppColors.success),
                icon: const Icon(Icons.check_circle_rounded),
                label: const Text('Marcar como Resolvida'),
                onPressed: () {
                  Navigator.pop(context);
                  widget.onUpdateStatus?.call(
                      ReportStatus.resolvido, _obsController.text);
                },
              ),
            ),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

Color _statusColor(ReportStatus status) {
  switch (status) {
    case ReportStatus.pendente:
      return AppColors.error;
    case ReportStatus.emAnalise:
      return AppColors.warning;
    case ReportStatus.resolvido:
      return AppColors.success;
    case ReportStatus.arquivado:
      return AppColors.neutral500;
  }
}

String _statusLabel(ReportStatus status) {
  switch (status) {
    case ReportStatus.pendente:
      return 'Pendente';
    case ReportStatus.emAnalise:
      return 'Em Análise';
    case ReportStatus.resolvido:
      return 'Resolvido';
    case ReportStatus.arquivado:
      return 'Arquivado';
  }
}

String _categoryLabel(ReportCategory cat) {
  switch (cat) {
    case ReportCategory.mensagem:
      return 'Mensagem inadequada';
    case ReportCategory.comportamento:
      return 'Comportamento';
    case ReportCategory.assedio:
      return 'Assédio';
    case ReportCategory.irregularidade:
      return 'Irregularidade';
    case ReportCategory.outro:
      return 'Outro';
  }
}

IconData _categoryIcon(ReportCategory cat) {
  switch (cat) {
    case ReportCategory.mensagem:
      return Icons.message_outlined;
    case ReportCategory.comportamento:
      return Icons.sentiment_dissatisfied_outlined;
    case ReportCategory.assedio:
      return Icons.gavel_rounded;
    case ReportCategory.irregularidade:
      return Icons.warning_amber_rounded;
    case ReportCategory.outro:
      return Icons.help_outline_rounded;
  }
}
