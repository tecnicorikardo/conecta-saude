import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/auth/permissions_provider.dart';
import '../../../auth/presentation/providers/current_user_provider.dart';
import '../../../auth/domain/entities/user_entity.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: AppColors.primaryDark,
      statusBarIconBrightness: Brightness.light,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final perms = ref.watch(permissionsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context, userAsync.value, perms),
      body: userAsync.when(
        data: (user) => _buildBody(context, user, perms),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
      ),
    );
  }

  // ─── AppBar com badge de hierarquia ────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(
      BuildContext context, UserEntity? user, UserPermissions perms) {
    return AppBar(
      backgroundColor: AppColors.primary,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: AppColors.primaryDark,
        statusBarIconBrightness: Brightness.light,
      ),
      title: Row(
        children: [
          Container(
            height: 32,
            width: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
            child: Image.asset('assets/images/logo_sus.png', fit: BoxFit.contain),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Conecta Saúde',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'SUS — Comunicação Institucional',
                  style: TextStyle(color: Colors.white70, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        // Notificações
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: Colors.white),
          onPressed: () => context.push(AppRoutes.notifications),
          tooltip: 'Notificações',
        ),
        // Avatar + badge de hierarquia
        GestureDetector(
          onTap: () => context.push(AppRoutes.profile),
          child: Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircleAvatar(
                  radius: 17,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  child: Text(
                    _initials(user?.nome ?? 'U'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                // Ponto colorido indicando nível
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Color(perms.levelColorHex),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── Body adaptado por hierarquia ──────────────────────────────────────────
  Widget _buildBody(
      BuildContext context, UserEntity? user, UserPermissions perms) {
    final nome = user?.nome ?? 'Usuário';
    final primeiroNome = nome.split(' ').first;
    final cargo = user?.cargo ?? '';
    final setor = user?.setorNome ?? '';

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {},
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Card de boas-vindas com badge de nível ──────────────────
            _WelcomeCard(
              nome: primeiroNome,
              cargo: cargo,
              setor: setor,
              perms: perms,
            ),
            const SizedBox(height: 16),

            // ─── Emergência (todos veem, mas só liderança posta) ─────────
            _EmergencyBanner(
                onTap: () => context.push(AppRoutes.emergency)),
            const SizedBox(height: 20),

            // ─── Acesso Rápido ───────────────────────────────────────────
            Text(
              'Acesso Rápido',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.neutral600,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
            ),
            const SizedBox(height: 12),

            // Cards de acesso — filtrados por permissão
            _buildQuickAccess(context, perms),
            const SizedBox(height: 20),

            // ─── Painel Admin (somente Coord+ ) ──────────────────────────
            if (perms.isAdmin) ...[
              _AdminPanel(perms: perms),
              const SizedBox(height: 20),
            ],

            // ─── Comunicados recentes ────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Comunicados Recentes',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.neutral600,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                ),
                TextButton(
                  onPressed: () => context.push(AppRoutes.announcements),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Ver todos',
                      style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _AnnouncementCard(
              titulo: 'Reunião Geral — Planejamento',
              descricao: 'Haverá reunião geral amanhã às 14h no auditório.',
              prioridade: 'alta',
              tempo: 'Hoje, 10:32',
              onTap: () => context.push(AppRoutes.announcements),
            ),
            const SizedBox(height: 8),
            _AnnouncementCard(
              titulo: 'Protocolo de Higienização',
              descricao: 'Reforçamos o cumprimento do protocolo POP-HIG-001.',
              prioridade: 'urgente',
              tempo: '1h atrás',
              onTap: () => context.push(AppRoutes.announcements),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAccess(BuildContext context, UserPermissions perms) {
    final cards = <_QuickCard>[];

    // Todos têm acesso
    cards.add(_QuickCard(
      icon: Icons.chat_bubble_outline_rounded,
      label: 'Conversas',
      badge: 2,
      color: AppColors.primary,
      onTap: () => context.go(AppRoutes.conversations),
    ));

    cards.add(_QuickCard(
      icon: Icons.campaign_outlined,
      label: 'Canais',
      color: const Color(0xFF0277BD),
      onTap: () => context.go(AppRoutes.channels),
    ));

    cards.add(_QuickCard(
      icon: Icons.article_outlined,
      label: 'Comunicados',
      badge: 1,
      color: const Color(0xFF2E7D32),
      onTap: () => context.go(AppRoutes.announcements),
    ));

    // Notificações — todos
    cards.add(_QuickCard(
      icon: Icons.notifications_active_outlined,
      label: 'Notificações',
      color: const Color(0xFFE65100),
      onTap: () => context.push(AppRoutes.notifications),
    ));

    // Funcionários — somente Direção
    if (perms.canManageEmployees) {
      cards.add(_QuickCard(
        icon: Icons.people_outlined,
        label: 'Funcionários',
        color: const Color(0xFF6A5ACD),
        onTap: () => context.push(AppRoutes.employees),
      ));
    }

    // Denúncias — Admin+
    if (perms.canViewReports) {
      cards.add(_QuickCard(
        icon: Icons.flag_outlined,
        label: 'Denúncias',
        badge: 0,
        color: const Color(0xFFB71C1C),
        onTap: () => context.push(AppRoutes.reports),
      ));
    }

    // Grid de 2 colunas
    final rows = <Widget>[];
    for (int i = 0; i < cards.length; i += 2) {
      final hasSecond = i + 1 < cards.length;
      rows.add(
        Row(
          children: [
            Expanded(child: _QuickAccessCard(data: cards[i])),
            const SizedBox(width: 12),
            hasSecond
                ? Expanded(child: _QuickAccessCard(data: cards[i + 1]))
                : const Expanded(child: SizedBox()),
          ],
        ),
      );
      if (i + 2 < cards.length) rows.add(const SizedBox(height: 12));
    }

    return Column(children: rows);
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'U';
  }
}

// ─── Card de boas-vindas ──────────────────────────────────────────────────────
class _WelcomeCard extends StatelessWidget {
  final String nome;
  final String cargo;
  final String setor;
  final UserPermissions perms;

  const _WelcomeCard({
    required this.nome,
    required this.cargo,
    required this.setor,
    required this.perms,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 26,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            child: Text(
              nome.isNotEmpty ? nome[0].toUpperCase() : 'U',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Olá, $nome',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (cargo.isNotEmpty || setor.isNotEmpty)
                  Text(
                    [cargo, setor]
                        .where((s) => s.isNotEmpty)
                        .join(' · '),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          // Badge de hierarquia
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.4)),
            ),
            child: Text(
              perms.hierarquiaLabel,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Painel administrativo (somente admin) ────────────────────────────────────
class _AdminPanel extends StatelessWidget {
  final UserPermissions perms;
  const _AdminPanel({required this.perms});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.admin_panel_settings_outlined,
                  color: AppColors.primary, size: 18),
              SizedBox(width: 8),
              Text(
                'Painel Administrativo',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (perms.canManageEmployees)
                _AdminChip(
                  icon: Icons.people_outline,
                  label: 'Funcionários',
                  onTap: () => context.push(AppRoutes.employees),
                ),
              if (perms.canViewReports)
                _AdminChip(
                  icon: Icons.flag_outlined,
                  label: 'Denúncias',
                  onTap: () => context.push(AppRoutes.reports),
                ),
              if (perms.canViewAudit)
                _AdminChip(
                  icon: Icons.history_outlined,
                  label: 'Auditoria',
                  onTap: () => context.push(AppRoutes.auditLogs),
                ),
              _AdminChip(
                icon: Icons.bar_chart_outlined,
                label: 'Relatórios',
                onTap: () => context.push(AppRoutes.administration),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdminChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _AdminChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Modelo de card ───────────────────────────────────────────────────────────
class _QuickCard {
  final IconData icon;
  final String label;
  final int badge;
  final Color color;
  final VoidCallback onTap;

  const _QuickCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.badge = 0,
  });
}

// ─── Card de acesso rápido ────────────────────────────────────────────────────
class _QuickAccessCard extends StatelessWidget {
  final _QuickCard data;
  const _QuickAccessCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: data.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: data.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(data.icon, color: data.color, size: 20),
                  ),
                  if (data.badge > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${data.badge}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                data.label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Banner de emergência ─────────────────────────────────────────────────────
class _EmergencyBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _EmergencyBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.emergencyLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: AppColors.emergency.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: AppColors.emergency,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.warning_amber_rounded,
                  color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🚨  Canal de Emergência',
                    style: TextStyle(
                      color: AppColors.emergencyDark,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Acesso rápido para comunicações urgentes.',
                    style: TextStyle(
                        color: AppColors.emergency, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: AppColors.emergency, size: 20),
          ],
        ),
      ),
    );
  }
}

// ─── Card de comunicado ───────────────────────────────────────────────────────
class _AnnouncementCard extends StatelessWidget {
  final String titulo;
  final String descricao;
  final String prioridade;
  final String tempo;
  final VoidCallback onTap;

  const _AnnouncementCard({
    required this.titulo,
    required this.descricao,
    required this.prioridade,
    required this.tempo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isUrgente = prioridade == 'urgente';
    final badgeColor = isUrgente ? AppColors.error : AppColors.warning;
    final badgeLabel = isUrgente ? 'URGENTE' : 'ALTA';

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.article_outlined,
                    color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            titulo,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: badgeColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            badgeLabel,
                            style: TextStyle(
                              color: badgeColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      descricao,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.neutral600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      tempo,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.neutral500),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
