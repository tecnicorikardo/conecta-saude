import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/current_user_provider.dart';

// ─── Mock Data Providers ──────────────────────────────────────────────────────

class _AdminStats {
  final int totalUsuariosAtivos;
  final int totalUsuariosInativos;
  final int totalComunicados;
  final int comunicadosSemLeitura;
  final int totalCanais;
  final int denunciasPendentes;
  final int denunciasResolvidas;
  final Map<String, int> usuariosPorCentro;

  const _AdminStats({
    required this.totalUsuariosAtivos,
    required this.totalUsuariosInativos,
    required this.totalComunicados,
    required this.comunicadosSemLeitura,
    required this.totalCanais,
    required this.denunciasPendentes,
    required this.denunciasResolvidas,
    required this.usuariosPorCentro,
  });
}

final _adminStatsProvider = FutureProvider<_AdminStats>((ref) async {
  // Simula latência de API
  await Future.delayed(const Duration(milliseconds: 600));
  return const _AdminStats(
    totalUsuariosAtivos: 9,
    totalUsuariosInativos: 1,
    totalComunicados: 4,
    comunicadosSemLeitura: 1,
    totalCanais: 9,
    denunciasPendentes: 2,
    denunciasResolvidas: 5,
    usuariosPorCentro: {
      'CCDTI': 3,
      'CCO': 3,
      'CCE': 3,
    },
  );
});

// ─── Page ─────────────────────────────────────────────────────────────────────

class AdministrationPage extends ConsumerWidget {
  const AdministrationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final statsAsync = ref.watch(_adminStatsProvider);

    final currentUser = userAsync.valueOrNull;
    final isDirecao = currentUser?.isDirecao ?? false;

    if (!isDirecao) {
      return Scaffold(
        appBar: AppBar(title: const Text('Administração')),
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
                  'Este painel é exclusivo para a Direção Geral.',
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
        title: const Text('Painel Administrativo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Atualizar dados',
            onPressed: () => ref.invalidate(_adminStatsProvider),
          ),
        ],
      ),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorState(onRetry: () => ref.invalidate(_adminStatsProvider)),
        data: (stats) => _AdminContent(stats: stats, currentUser: currentUser),
      ),
    );
  }
}

// ─── Conteúdo Principal ───────────────────────────────────────────────────────

class _AdminContent extends StatelessWidget {
  final _AdminStats stats;
  final UserEntity? currentUser;

  const _AdminContent({required this.stats, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {},
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: [
          // ─── Saudação ────────────────────────────────────────────────────
          if (currentUser != null) ...[
            Text(
              'Olá, ${currentUser!.nome.split(' ').first}!',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.neutral900,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              'Visão geral do sistema Conecta Saúde',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.neutral600),
            ),
            const SizedBox(height: 20),
          ],

          // ─── Métricas de Usuários ─────────────────────────────────────
          _SectionTitle(title: 'Usuários do Sistema'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  icon: Icons.people_rounded,
                  label: 'Ativos',
                  value: stats.totalUsuariosAtivos.toString(),
                  color: AppColors.success,
                  bgColor: AppColors.successLight,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  icon: Icons.person_off_rounded,
                  label: 'Inativos',
                  value: stats.totalUsuariosInativos.toString(),
                  color: AppColors.error,
                  bgColor: AppColors.errorLight,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  icon: Icons.groups_rounded,
                  label: 'Total',
                  value: (stats.totalUsuariosAtivos +
                          stats.totalUsuariosInativos)
                      .toString(),
                  color: AppColors.primary,
                  bgColor: AppColors.primaryContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ─── Distribuição por Centro ──────────────────────────────────
          _SectionTitle(title: 'Usuários por Centro'),
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: stats.usuariosPorCentro.entries.map((entry) {
                  final total = stats.totalUsuariosAtivos;
                  final fraction = total > 0 ? entry.value / total : 0.0;
                  return _CenterBar(
                    label: entry.key,
                    count: entry.value,
                    fraction: fraction,
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ─── Comunicados ──────────────────────────────────────────────
          _SectionTitle(title: 'Comunicados'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  icon: Icons.campaign_rounded,
                  label: 'Total',
                  value: stats.totalComunicados.toString(),
                  color: AppColors.info,
                  bgColor: AppColors.infoLight,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  icon: Icons.mark_email_unread_rounded,
                  label: 'Não confirmados',
                  value: stats.comunicadosSemLeitura.toString(),
                  color: AppColors.warning,
                  bgColor: AppColors.warningLight,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  icon: Icons.hub_rounded,
                  label: 'Canais',
                  value: stats.totalCanais.toString(),
                  color: AppColors.secondary,
                  bgColor: AppColors.secondaryContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ─── Denúncias ────────────────────────────────────────────────
          _SectionTitle(title: 'Denúncias e Ocorrências'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  icon: Icons.warning_amber_rounded,
                  label: 'Pendentes',
                  value: stats.denunciasPendentes.toString(),
                  color: AppColors.warning,
                  bgColor: AppColors.warningLight,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  icon: Icons.check_circle_rounded,
                  label: 'Resolvidas',
                  value: stats.denunciasResolvidas.toString(),
                  color: AppColors.success,
                  bgColor: AppColors.successLight,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  icon: Icons.report_rounded,
                  label: 'Total',
                  value: (stats.denunciasPendentes +
                          stats.denunciasResolvidas)
                      .toString(),
                  color: AppColors.neutral600,
                  bgColor: AppColors.surfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ─── Ações Rápidas ────────────────────────────────────────────
          _SectionTitle(title: 'Ações Rápidas'),
          const SizedBox(height: 12),
          _QuickActions(),
          const SizedBox(height: 20),

          // ─── Alertas e Avisos ─────────────────────────────────────────
          if (stats.denunciasPendentes > 0) ...[
            _AlertBanner(
              icon: Icons.warning_amber_rounded,
              message:
                  '${stats.denunciasPendentes} denúncia(s) aguardando análise.',
              color: AppColors.warning,
              bgColor: AppColors.warningLight,
              onTap: () => context.push(AppRoutes.reports),
            ),
            const SizedBox(height: 10),
          ],
          if (stats.comunicadosSemLeitura > 0) ...[
            _AlertBanner(
              icon: Icons.campaign_rounded,
              message:
                  '${stats.comunicadosSemLeitura} comunicado(s) com baixa taxa de leitura.',
              color: AppColors.info,
              bgColor: AppColors.infoLight,
              onTap: () => context.push(AppRoutes.announcements),
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ─── Widgets Auxiliares ───────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.neutral700,
            letterSpacing: 0.3,
          ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final Color bgColor;

  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: color,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.neutral600,
                    fontSize: 11,
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _CenterBar extends StatelessWidget {
  final String label;
  final int count;
  final double fraction;

  const _CenterBar({
    required this.label,
    required this.count,
    required this.fraction,
  });

  Color get _barColor {
    switch (label) {
      case 'CCDTI':
        return AppColors.primary;
      case 'CCO':
        return AppColors.secondary;
      case 'CCE':
        return AppColors.success;
      default:
        return AppColors.neutral500;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.neutral700,
                    ),
              ),
              Text(
                '$count usuário${count != 1 ? 's' : ''}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.neutral500,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 8,
              backgroundColor: AppColors.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(_barColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.6,
      children: [
        _QuickActionTile(
          icon: Icons.people_rounded,
          label: 'Funcionários',
          color: AppColors.primary,
          onTap: () => context.push(AppRoutes.employees),
        ),
        _QuickActionTile(
          icon: Icons.campaign_rounded,
          label: 'Comunicados',
          color: AppColors.info,
          onTap: () => context.push(AppRoutes.announcements),
        ),
        _QuickActionTile(
          icon: Icons.report_rounded,
          label: 'Denúncias',
          color: AppColors.warning,
          onTap: () => context.push(AppRoutes.reports),
        ),
        _QuickActionTile(
          icon: Icons.history_rounded,
          label: 'Auditoria',
          color: AppColors.neutral700,
          onTap: () => context.push(AppRoutes.auditLogs),
        ),
        _QuickActionTile(
          icon: Icons.hub_rounded,
          label: 'Canais',
          color: AppColors.secondary,
          onTap: () => context.push(AppRoutes.channels),
        ),
        _QuickActionTile(
          icon: Icons.emergency_rounded,
          label: 'Emergência',
          color: AppColors.emergency,
          onTap: () => context.push(AppRoutes.emergency),
        ),
      ],
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.neutral800,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(Icons.chevron_right, size: 16, color: AppColors.neutral500),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlertBanner extends StatelessWidget {
  final IconData icon;
  final String message;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  const _AlertBanner({
    required this.icon,
    required this.message,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 13, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Error State ──────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            const Text(
              'Não foi possível carregar os dados.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
