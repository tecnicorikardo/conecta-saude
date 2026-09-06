import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/auth/permissions_provider.dart';
import '../../data/repositories/reports_repository.dart';
import '../providers/reports_provider.dart';

class ReportsPage extends ConsumerStatefulWidget {
  const ReportsPage({super.key});

  @override
  ConsumerState<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends ConsumerState<ReportsPage> {
  ReportStatus? _selectedStatus;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      final perms = ref.read(permissionsProvider);
      if (perms.isDirecao) {
        ref.invalidate(allReportsProvider(_selectedStatus));
      } else {
        ref.invalidate(myReportsProvider);
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final perms = ref.watch(permissionsProvider);
    final isDirecao = perms.isDirecao;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isDirecao
            ? 'Ouvidoria & Moderação'
            : 'Ouvidoria & Canal de Denúncias'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Atualizar',
            onPressed: () {
              if (isDirecao) {
                ref.invalidate(allReportsProvider(_selectedStatus));
              } else {
                ref.invalidate(myReportsProvider);
              }
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showNewReportModal(context),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_moderator_outlined),
        label: const Text('Nova Denúncia',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body:
          isDirecao ? _buildDirecaoView(context) : _buildEmployeeView(context),
    );
  }

  // ─── VISÃO DA DIREÇÃO GERAL (INVESTIGAÇÃO & MODERAÇÃO) ──────────────────────
  Widget _buildDirecaoView(BuildContext context) {
    final reportsAsync = ref.watch(allReportsProvider(_selectedStatus));

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        ref.invalidate(allReportsProvider(_selectedStatus));
      },
      child: Column(
        children: [
          // Banner de Identificação de Nível Direção
          Container(
            width: double.infinity,
            color: AppColors.primary.withValues(alpha: 0.08),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: const Row(
              children: [
                Icon(Icons.shield_outlined, size: 18, color: AppColors.primary),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'PAINEL DA DIREÇÃO GERAL · Investigação e Tratamento Sigiloso',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Filtros por Status
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                _StatusChip(
                  label: 'Todas',
                  isSelected: _selectedStatus == null,
                  color: AppColors.neutral700,
                  onTap: () => setState(() => _selectedStatus = null),
                ),
                const SizedBox(width: 8),
                _StatusChip(
                  label: 'Pendentes',
                  isSelected: _selectedStatus == ReportStatus.pendente,
                  color: AppColors.error,
                  onTap: () =>
                      setState(() => _selectedStatus = ReportStatus.pendente),
                ),
                const SizedBox(width: 8),
                _StatusChip(
                  label: 'Em Análise',
                  isSelected: _selectedStatus == ReportStatus.emAnalise,
                  color: AppColors.warning,
                  onTap: () =>
                      setState(() => _selectedStatus = ReportStatus.emAnalise),
                ),
                const SizedBox(width: 8),
                _StatusChip(
                  label: 'Resolvidas',
                  isSelected: _selectedStatus == ReportStatus.resolvido,
                  color: AppColors.success,
                  onTap: () =>
                      setState(() => _selectedStatus = ReportStatus.resolvido),
                ),
                const SizedBox(width: 8),
                _StatusChip(
                  label: 'Arquivadas',
                  isSelected: _selectedStatus == ReportStatus.arquivado,
                  color: AppColors.neutral500,
                  onTap: () =>
                      setState(() => _selectedStatus = ReportStatus.arquivado),
                ),
              ],
            ),
          ),

          // Lista
          Expanded(
            child: reportsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: AppColors.error),
                    const SizedBox(height: 12),
                    Text('$e', textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text('Tentar novamente'),
                      onPressed: () =>
                          ref.invalidate(allReportsProvider(_selectedStatus)),
                    ),
                  ],
                ),
              ),
              data: (reports) {
                if (reports.isEmpty) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.4,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.assignment_turned_in_outlined,
                                  size: 56, color: AppColors.neutral400),
                              const SizedBox(height: 12),
                              Text(
                                _selectedStatus == null
                                    ? 'Nenhuma denúncia registrada.'
                                    : 'Nenhuma denúncia com status "${_statusLabel(_selectedStatus!)}".',
                                style: const TextStyle(
                                    color: AppColors.neutral600, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                }

                return ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(
                      left: 16, right: 16, top: 8, bottom: 80),
                  itemCount: reports.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final report = reports[index];
                    return _DirecaoReportCard(
                      report: report,
                      onTap: () => _showInvestigationSheet(context, report),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ─── VISÃO DO COLABORADOR / OUVIDORIA GERAL ─────────────────────────────────
  Widget _buildEmployeeView(BuildContext context) {
    final myReportsAsync = ref.watch(myReportsProvider);

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        ref.invalidate(myReportsProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding:
            const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner de Privacidade & Sigilo
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withValues(alpha: 0.85),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.verified_user_rounded,
                          color: Colors.white, size: 24),
                      SizedBox(width: 10),
                      Text(
                        'Canal Sigiloso e Seguro SUS',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Este espaço é reservado para relatos de assédio, desvios éticos, problemas de infraestrutura ou riscos assistenciais. Todas as manifestações vão diretamente para a Direção Geral, sem passar por chefias imediatas.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.add_moderator_rounded, size: 18),
                      label: const Text(
                        'Registrar Nova Denúncia ou Relato',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      onPressed: () => _showNewReportModal(context),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Título de Seção
            const Row(
              children: [
                Icon(Icons.history_edu_rounded,
                    size: 20, color: AppColors.neutral700),
                SizedBox(width: 8),
                Text(
                  'Minhas Manifestações Registradas',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.neutral800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Lista de manifestações do usuário
            myReportsAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (e, _) => Center(
                child: Text('Erro ao carregar relatos: $e',
                    style: const TextStyle(color: AppColors.error)),
              ),
              data: (reports) {
                if (reports.isEmpty) {
                  return Card(
                    elevation: 0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: AppColors.outlineVariant),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.inbox_outlined,
                                size: 44, color: AppColors.neutral400),
                            SizedBox(height: 8),
                            Text(
                              'Você ainda não registrou nenhuma ocorrência.',
                              style: TextStyle(
                                  color: AppColors.neutral600, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: reports.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final report = reports[index];
                    return _EmployeeReportCard(report: report);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ─── Modal de Nova Denúncia ─────────────────────────────────────────────────
  void _showNewReportModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _NewReportSheet(
        onSubmitted: () {
          ref.invalidate(myReportsProvider);
          ref.invalidate(allReportsProvider(_selectedStatus));
        },
      ),
    );
  }

  // ─── Modal de Investigação (Direção Geral) ───────────────────────────────────
  void _showInvestigationSheet(BuildContext context, ReportEntity report) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _InvestigationSheet(
        report: report,
        onUpdated: () {
          ref.invalidate(allReportsProvider(_selectedStatus));
          ref.invalidate(myReportsProvider);
        },
      ),
    );
  }
}

// ─── CHIP DE STATUS ───────────────────────────────────────────────────────────
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}

// ─── CARD DE DENÚNCIA - DIREÇÃO GERAL ─────────────────────────────────────────
class _DirecaoReportCard extends StatelessWidget {
  final ReportEntity report;
  final VoidCallback onTap;

  const _DirecaoReportCard({
    required this.report,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(report.status);
    final statusLabel = _statusLabel(report.status);
    final categoryLabel = _categoryLabel(report.categoria);
    final categoryIcon = _categoryIcon(report.categoria);

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabeçalho: Categoria + Status
              Row(
                children: [
                  Icon(categoryIcon, size: 16, color: AppColors.neutral600),
                  const SizedBox(width: 6),
                  Text(
                    categoryLabel,
                    style: const TextStyle(
                      color: AppColors.neutral700,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
              if (report.titulo != null && report.titulo!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  report.titulo!,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.neutral900,
                  ),
                ),
              ],
              const SizedBox(height: 6),

              // Descrição
              Text(
                report.descricao,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.neutral800,
                ),
              ),
              const SizedBox(height: 10),

              // Rodapé: Denunciante + Data
              Row(
                children: [
                  if (report.isAnonimo) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF673AB7).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.shield_outlined,
                              size: 12, color: Color(0xFF673AB7)),
                          SizedBox(width: 4),
                          Text(
                            'Anônima',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF673AB7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    const Icon(Icons.person_outline,
                        size: 13, color: AppColors.neutral500),
                    const SizedBox(width: 4),
                    Text(
                      '${report.denuncianteNome} (${report.denuncianteSetor ?? 'SUS'})',
                      style: const TextStyle(
                        color: AppColors.neutral600,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  const Spacer(),
                  Text(
                    _formatDate(report.criadoEm),
                    style: const TextStyle(
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
}

// ─── CARD DE DENÚNCIA - COLABORADOR ───────────────────────────────────────────
class _EmployeeReportCard extends StatelessWidget {
  final ReportEntity report;

  const _EmployeeReportCard({required this.report});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(report.status);
    final statusLabel = _statusLabel(report.status);
    final categoryLabel = _categoryLabel(report.categoria);
    final categoryIcon = _categoryIcon(report.categoria);

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(categoryIcon, size: 16, color: AppColors.neutral600),
                const SizedBox(width: 6),
                Text(
                  categoryLabel,
                  style: const TextStyle(
                    color: AppColors.neutral700,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                if (report.isAnonimo) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF673AB7).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      '🔒 Anônimo',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF673AB7),
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
            if (report.titulo != null && report.titulo!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                report.titulo!,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 6),
            Text(
              report.descricao,
              style: const TextStyle(fontSize: 13, color: AppColors.neutral800),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.access_time_rounded,
                    size: 13, color: AppColors.neutral500),
                const SizedBox(width: 4),
                Text(
                  'Enviado ${_formatDate(report.criadoEm)}',
                  style: const TextStyle(
                    color: AppColors.neutral500,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            if (report.resposta != null && report.resposta!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.rate_review_outlined,
                            size: 14, color: AppColors.success),
                        SizedBox(width: 6),
                        Text(
                          'Parecer da Direção Geral:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      report.resposta!,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.neutral800),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── BOTTOM SHEET: NOVA DENÚNCIA (COLABORADOR / GERAL) ─────────────────────────
class _NewReportSheet extends ConsumerStatefulWidget {
  final VoidCallback onSubmitted;

  const _NewReportSheet({required this.onSubmitted});

  @override
  ConsumerState<_NewReportSheet> createState() => _NewReportSheetState();
}

class _NewReportSheetState extends ConsumerState<_NewReportSheet> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String _selectedMotivo = 'assedio';
  bool _isAnonimo = true;
  bool _isSubmitting = false;

  final _motivos = const [
    {
      'key': 'assedio',
      'label': 'Assédio Moral / Sexual',
      'icon': Icons.gavel_rounded
    },
    {
      'key': 'desvio_conduta',
      'label': 'Desvio de Conduta / Ética',
      'icon': Icons.sentiment_very_dissatisfied_rounded
    },
    {
      'key': 'infraestrutura_risco',
      'label': 'Infraestrutura / Risco Hospitalar',
      'icon': Icons.warning_amber_rounded
    },
    {
      'key': 'fraude_recursos',
      'label': 'Fraude / Mau Uso de Recursos',
      'icon': Icons.monetization_on_outlined
    },
    {
      'key': 'outro',
      'label': 'Outro / Sugestão',
      'icon': Icons.help_outline_rounded
    },
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final desc = _descController.text.trim();
    if (desc.length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Por favor, detalhe o ocorrido com pelo menos 5 caracteres.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await ref.read(reportsRepositoryProvider).createReport(
            motivo: _selectedMotivo,
            descricao: desc,
            titulo: _titleController.text.trim().isNotEmpty
                ? _titleController.text.trim()
                : null,
            anonimo: _isAnonimo,
          );

      if (mounted) {
        Navigator.pop(context);
        widget.onSubmitted();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isAnonimo
                ? '🔒 Denúncia anônima registrada com sucesso. Seu sigilo está garantido.'
                : '✅ Denúncia registrada com sucesso. A Direção Geral analisará o caso.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao enviar denúncia: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
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
            const SizedBox(height: 16),

            const Row(
              children: [
                Icon(Icons.add_moderator_rounded,
                    color: AppColors.primary, size: 24),
                SizedBox(width: 8),
                Text(
                  'Registrar Manifestação / Denúncia',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.neutral900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Categoria
            const Text(
              'Tipo de Ocorrência',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.neutral800,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _motivos.map((m) {
                final isSel = _selectedMotivo == m['key'];
                return ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(m['icon'] as IconData,
                          size: 14,
                          color: isSel ? Colors.white : AppColors.neutral700),
                      const SizedBox(width: 6),
                      Text(m['label'] as String),
                    ],
                  ),
                  selected: isSel,
                  onSelected: (_) =>
                      setState(() => _selectedMotivo = m['key'] as String),
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                    color: isSel ? Colors.white : AppColors.neutral800,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Título (opcional)
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Assunto / Resumo (opcional)',
                hintText: 'Ex: Conduta inadequada no plantão',
              ),
            ),
            const SizedBox(height: 12),

            // Descrição (obrigatória)
            TextField(
              controller: _descController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Detalhes da Ocorrência *',
                hintText:
                    'Descreva o que aconteceu, data aproximada, local ou setor e detalhes relevantes...',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),

            // Card do Switch Anônimo
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isAnonimo
                    ? const Color(0xFF673AB7).withValues(alpha: 0.08)
                    : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isAnonimo
                      ? const Color(0xFF673AB7).withValues(alpha: 0.3)
                      : AppColors.outlineVariant,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isAnonimo ? Icons.shield_rounded : Icons.person_outline,
                    color: _isAnonimo
                        ? const Color(0xFF673AB7)
                        : AppColors.neutral600,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isAnonimo
                              ? 'Denúncia 100% Anônima'
                              : 'Denúncia Identificada',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _isAnonimo
                                ? const Color(0xFF673AB7)
                                : AppColors.neutral800,
                          ),
                        ),
                        Text(
                          _isAnonimo
                              ? 'Seu nome e setor não serão revelados a ninguém.'
                              : 'Seu nome será visível apenas para a Direção Geral.',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.neutral600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isAnonimo,
                    activeThumbColor: const Color(0xFF673AB7),
                    onChanged: (val) => setState(() => _isAnonimo = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Botão Enviar
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                onPressed: _isSubmitting ? null : _submit,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_rounded),
                label: Text(
                  _isSubmitting ? 'Enviando...' : 'Enviar Manifestação',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── BOTTOM SHEET: INVESTIGAÇÃO & TRATAMENTO (DIREÇÃO GERAL) ──────────────────
class _InvestigationSheet extends ConsumerStatefulWidget {
  final ReportEntity report;
  final VoidCallback onUpdated;

  const _InvestigationSheet({
    required this.report,
    required this.onUpdated,
  });

  @override
  ConsumerState<_InvestigationSheet> createState() =>
      _InvestigationSheetState();
}

class _InvestigationSheetState extends ConsumerState<_InvestigationSheet> {
  final _respostaController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _respostaController.text = widget.report.resposta ?? '';
  }

  @override
  void dispose() {
    _respostaController.dispose();
    super.dispose();
  }

  Future<void> _updateStatus(ReportStatus newStatus) async {
    setState(() => _isSaving = true);
    try {
      await ref.read(reportsRepositoryProvider).updateReportStatus(
            widget.report.id,
            newStatus,
            resposta: _respostaController.text.trim().isNotEmpty
                ? _respostaController.text.trim()
                : null,
          );

      if (mounted) {
        Navigator.pop(context);
        widget.onUpdated();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status atualizado para: ${_statusLabel(newStatus)}'),
            backgroundColor: _statusColor(newStatus),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar ocorrência: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.report;
    final statusColor = _statusColor(report.status);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
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
            const SizedBox(height: 16),

            // Cabeçalho
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
                    color: AppColors.neutral700,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                Text(
                  _formatDate(report.criadoEm),
                  style: const TextStyle(
                    color: AppColors.neutral500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (report.titulo != null && report.titulo!.isNotEmpty) ...[
              Text(
                report.titulo!,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.neutral900,
                ),
              ),
              const SizedBox(height: 8),
            ],

            // Descrição da Denúncia
            const Text(
              'Descrição do Fato',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.neutral600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                report.descricao,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.neutral900, height: 1.4),
              ),
            ),
            const SizedBox(height: 16),

            // Informações do Denunciante
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: report.isAnonimo
                    ? const Color(0xFF673AB7).withValues(alpha: 0.08)
                    : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: report.isAnonimo
                      ? const Color(0xFF673AB7).withValues(alpha: 0.2)
                      : AppColors.outlineVariant,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    report.isAnonimo
                        ? Icons.shield_outlined
                        : Icons.person_outline,
                    size: 20,
                    color: report.isAnonimo
                        ? const Color(0xFF673AB7)
                        : AppColors.neutral700,
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report.denuncianteNome,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: report.isAnonimo
                              ? const Color(0xFF673AB7)
                              : AppColors.neutral900,
                        ),
                      ),
                      Text(
                        'Setor: ${report.denuncianteSetor ?? 'SUS'}',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.neutral600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            const Divider(),
            const SizedBox(height: 12),

            // Parecer / Resolução da Direção
            const Text(
              'Parecer e Resolução da Direção Geral',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.neutral900,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _respostaController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Providências / Parecer oficial',
                hintText:
                    'Descreva as investigações, reuniões ou providências tomadas...',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),

            // Ações de Mudança de Status
            const Text(
              'Ações de Investigação:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.neutral700,
              ),
            ),
            const SizedBox(height: 10),

            if (_isSaving)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(),
                ),
              )
            else ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.archive_outlined, size: 16),
                      label: const Text('Arquivar'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.neutral700,
                      ),
                      onPressed: () => _updateStatus(ReportStatus.arquivado),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      icon: const Icon(Icons.manage_search_rounded, size: 16),
                      label: const Text('Em Análise'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.warning,
                      ),
                      onPressed: () => _updateStatus(ReportStatus.emAnalise),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.success,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.check_circle_rounded),
                  label: const Text('Concluir e Marcar como Resolvida',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  onPressed: () => _updateStatus(ReportStatus.resolvido),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── HELPERS ──────────────────────────────────────────────────────────────────

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
    case ReportCategory.assedio:
      return 'Assédio Moral / Sexual';
    case ReportCategory.desvioConduta:
      return 'Desvio de Conduta / Ética';
    case ReportCategory.infraestruturaRisco:
      return 'Infraestrutura / Risco Hospitalar';
    case ReportCategory.fraudeRecursos:
      return 'Fraude / Mau Uso de Recursos';
    case ReportCategory.outro:
      return 'Outro / Sugestão';
  }
}

IconData _categoryIcon(ReportCategory cat) {
  switch (cat) {
    case ReportCategory.assedio:
      return Icons.gavel_rounded;
    case ReportCategory.desvioConduta:
      return Icons.sentiment_very_dissatisfied_rounded;
    case ReportCategory.infraestruturaRisco:
      return Icons.warning_amber_rounded;
    case ReportCategory.fraudeRecursos:
      return Icons.monetization_on_outlined;
    case ReportCategory.outro:
      return Icons.help_outline_rounded;
  }
}

String _formatDate(DateTime date) {
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 60) {
    return '${diff.inMinutes <= 0 ? 1 : diff.inMinutes}min atrás';
  } else if (diff.inHours < 24) {
    return '${diff.inHours}h atrás';
  } else if (diff.inDays < 7) {
    return '${diff.inDays}d atrás';
  } else {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}


