import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/auth/permissions_provider.dart';
import '../../../employees/presentation/providers/employees_provider.dart';
import '../../../announcements/presentation/providers/announcements_provider.dart';
import '../../../announcements/domain/entities/announcement_entity.dart';
import '../../../reports/presentation/providers/reports_provider.dart';
import '../../../reports/data/repositories/reports_repository.dart' show ReportStatus;
import 'audit_logs_page.dart';

class AdministrationPage extends ConsumerWidget {
  const AdministrationPage({super.key});

  void _showReadingReportsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _ReadingReportsSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perms = ref.watch(permissionsProvider);

    // Guard — sem permissão redireciona
    if (!perms.canAccessAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Administração')),
        body: _NoAccessView(),
      );
    }

    // ─── Dados dinâmicos para os cards de resumo ──────────────────────────
    // 1. Funcionários
    final employeesState = ref.watch(employeesProvider);
    final totalEmployees = employeesState.users.isNotEmpty
        ? employeesState.users.length
        : employeesState.visibleUsers.length;
    final activeEmployees = employeesState.users.isNotEmpty
        ? employeesState.users.where((u) => u.ativo).length
        : employeesState.visibleUsers.where((u) => u.ativo).length;

    final empValue = totalEmployees > 0
        ? '$totalEmployees'
        : (employeesState.isLoading ? '...' : '0');
    final empSub = totalEmployees > 0
        ? '$activeEmployees ativos'
        : (employeesState.isLoading ? 'Carregando...' : '0 ativos');

    // 2. Comunicados
    final announcementsState = ref.watch(announcementsProvider);
    final totalAnnouncements = announcementsState.announcements.length;
    final annValue = announcementsState.isLoading && totalAnnouncements == 0
        ? '...'
        : '$totalAnnouncements';

    // 3. Denúncias
    final pendingReportsAsync = perms.canViewReports
        ? ref.watch(allReportsProvider(ReportStatus.pendente))
        : null;
    final pendingReportsCount = pendingReportsAsync?.valueOrNull?.length ?? 0;
    final repValue = pendingReportsAsync?.isLoading == true
        ? '...'
        : '$pendingReportsCount';

    // 4. Auditoria (logs criados hoje sincronizados com o banco real)
    final auditLogsAsync =
        perms.canViewAudit ? ref.watch(auditLogsListProvider) : null;
    final todayLogs = auditLogsAsync?.valueOrNull?.where((l) {
      final now = DateTime.now();
      return l.criadoEm.year == now.year &&
          l.criadoEm.month == now.month &&
          l.criadoEm.day == now.day;
    }).toList();
    final todayAuditCount = todayLogs?.length ?? 0;
    final auditValue = auditLogsAsync?.isLoading == true
        ? '...'
        : '$todayAuditCount';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Administração'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            tooltip: 'Atualizar dados',
            onPressed: () {
              ref.invalidate(employeesProvider);
              ref.invalidate(announcementsProvider);
              if (perms.canViewReports) ref.invalidate(allReportsProvider);
              if (perms.canViewAudit) ref.invalidate(auditLogsListProvider);
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.push(AppRoutes.notifications),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Cards de resumo ─────────────────────────────────────────
            Text(
              'Resumo do Sistema',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.neutral600,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    icon: Icons.people_outline,
                    label: 'Funcionários',
                    value: empValue,
                    sub: empSub,
                    color: AppColors.primary,
                    onTap: perms.canManageEmployees
                        ? () => context.push(AppRoutes.employees)
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryCard(
                    icon: Icons.article_outlined,
                    label: 'Comunicados',
                    value: annValue,
                    sub: 'Publicados',
                    color: const Color(0xFF2E7D32),
                    onTap: () => context.push(AppRoutes.announcements),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    icon: Icons.flag_outlined,
                    label: 'Denúncias',
                    value: repValue,
                    sub: 'Pendentes',
                    color: AppColors.error,
                    onTap: perms.canViewReports
                        ? () => context.push(AppRoutes.reports)
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryCard(
                    icon: Icons.history_outlined,
                    label: 'Auditoria',
                    value: auditValue,
                    sub: 'Hoje',
                    color: const Color(0xFFE65100),
                    onTap: perms.canViewAudit
                        ? () => context.push(AppRoutes.auditLogs)
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ─── Ações rápidas ────────────────────────────────────────────
            Text(
              'Ações',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.neutral600,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
            ),
            const SizedBox(height: 12),

            if (perms.canManageEmployees)
              _ActionCard(
                icon: Icons.person_add_outlined,
                title: 'Gerenciar Funcionários',
                subtitle: 'Cadastrar, editar e ativar/desativar funcionários.',
                color: AppColors.primary,
                onTap: () => context.push(AppRoutes.employees),
              ),
            if (perms.canViewReports) ...[
              const SizedBox(height: 10),
              _ActionCard(
                icon: Icons.flag_outlined,
                title: 'Denúncias',
                subtitle: 'Analisar e resolver denúncias pendentes.',
                color: AppColors.error,
                onTap: () => context.push(AppRoutes.reports),
              ),
            ],
            if (perms.canViewAudit) ...[
              const SizedBox(height: 10),
              _ActionCard(
                icon: Icons.history_outlined,
                title: 'Logs de Auditoria',
                subtitle: 'Visualizar registro de ações administrativas.',
                color: AppColors.neutral700,
                onTap: () => context.push(AppRoutes.auditLogs),
              ),
            ],
            const SizedBox(height: 10),
            _ActionCard(
              icon: Icons.bar_chart_outlined,
              title: 'Relatórios de Leitura',
              subtitle: 'Taxa de leitura dos comunicados publicados.',
              color: const Color(0xFF2E7D32),
              onTap: () => _showReadingReportsModal(context),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _NoAccessView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_outline,
              size: 56, color: AppColors.neutral400),
          const SizedBox(height: 16),
          Text(
            'Acesso restrito',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Você não tem permissão para acessar esta área.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.neutral500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String sub;
  final Color color;
  final VoidCallback? onTap;

  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.sub,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: color,
                )),
            Text(label,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600)),
            Text(sub,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.neutral500)),
          ],
        ),
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: card,
      );
    }
    return card;
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.neutral600)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right,
                  color: AppColors.neutral500),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReadingReportsSheet extends ConsumerWidget {
  const _ReadingReportsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(announcementsProvider);
    final announcements = state.announcements;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 16, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.bar_chart_outlined,
                      color: Color(0xFF2E7D32),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Relatórios de Leitura',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.neutral900,
                          ),
                        ),
                        Text(
                          'Taxa de confirmação de leitura por servidores',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.neutral600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: state.isLoading && announcements.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : announcements.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(40),
                            child: Text(
                              'Nenhum comunicado disponível no momento.',
                              style: TextStyle(color: AppColors.neutral600),
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          shrinkWrap: true,
                          itemCount: announcements.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final item = announcements[index];
                            final percent = item.percentualLeitura;
                            final dateStr = DateFormat('dd/MM/yyyy HH:mm')
                                .format(item.publicadoEm);

                            return Card(
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: Colors.grey.shade200),
                              ),
                              child: InkWell(
                                onTap: () {
                                  Navigator.of(context).pop();
                                  context.push('/announcements/${item.id}');
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              item.titulo,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 14,
                                                color: AppColors.neutral900,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: item.prioridade == AnnouncementPriority.urgente
                                                  ? AppColors.emergencyLight
                                                  : (item.prioridade == AnnouncementPriority.alta
                                                      ? AppColors.warningLight
                                                      : AppColors.primaryContainer),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              item.prioridade.label,
                                              style: TextStyle(
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.bold,
                                                color: item.prioridade == AnnouncementPriority.urgente
                                                    ? AppColors.emergency
                                                    : (item.prioridade == AnnouncementPriority.alta
                                                        ? AppColors.warning
                                                        : AppColors.primary),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Publicado em $dateStr por ${item.criadorNome}',
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          color: AppColors.neutral500,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            '${item.totalLeituras} de ${item.totalUsuarios} servidores leram',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.neutral700,
                                            ),
                                          ),
                                          Text(
                                            '$percent%',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xFF2E7D32),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: item.totalUsuarios > 0
                                              ? item.totalLeituras / item.totalUsuarios
                                              : 0.0,
                                          minHeight: 6,
                                          backgroundColor: Colors.grey.shade200,
                                          valueColor: const AlwaysStoppedAnimation<Color>(
                                            Color(0xFF2E7D32),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      const Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          Text(
                                            'Ver detalhes e confirmações',
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                          SizedBox(width: 4),
                                          Icon(
                                            Icons.arrow_forward_ios,
                                            size: 11,
                                            color: AppColors.primary,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
