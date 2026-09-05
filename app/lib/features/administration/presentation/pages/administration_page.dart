import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/auth/permissions_provider.dart';

class AdministrationPage extends ConsumerWidget {
  const AdministrationPage({super.key});

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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Administração'),
        actions: [
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
            const Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    icon: Icons.people_outline,
                    label: 'Funcionários',
                    value: '11',
                    sub: '10 ativos',
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _SummaryCard(
                    icon: Icons.article_outlined,
                    label: 'Comunicados',
                    value: '3',
                    sub: 'Este mês',
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    icon: Icons.flag_outlined,
                    label: 'Denúncias',
                    value: '0',
                    sub: 'Pendentes',
                    color: AppColors.error,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _SummaryCard(
                    icon: Icons.history_outlined,
                    label: 'Auditoria',
                    value: '24',
                    sub: 'Hoje',
                    color: Color(0xFFE65100),
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
                onTap: () {},
              ),
            ],
            const SizedBox(height: 10),
            _ActionCard(
              icon: Icons.bar_chart_outlined,
              title: 'Relatórios de Leitura',
              subtitle: 'Taxa de leitura dos comunicados publicados.',
              color: const Color(0xFF2E7D32),
              onTap: () {},
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

  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.sub,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
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
