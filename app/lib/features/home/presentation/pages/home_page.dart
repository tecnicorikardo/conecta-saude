import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme_provider.dart';
import '../../../../core/auth/permissions_provider.dart';
import '../../../auth/presentation/providers/current_user_provider.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../chat/presentation/providers/chat_provider.dart';
import '../../../channels/presentation/providers/channels_provider.dart';
import '../../../announcements/presentation/providers/announcements_provider.dart';
import '../../../emergency/presentation/providers/emergency_provider.dart';
import '../../../emergency/domain/entities/emergency_entity.dart';

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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
    final tokens = context.appTokens;

    return AppBar(
      backgroundColor: tokens.primaryDark,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: tokens.primaryDark,
        statusBarIconBrightness: Brightness.light,
      ),
      bottom: tokens.identityRainbow.isNotEmpty
          ? PreferredSize(
              preferredSize: const Size.fromHeight(3.0),
              child: Row(
                children: tokens.identityRainbow
                    .map((c) => Expanded(child: Container(height: 3, color: c)))
                    .toList(),
              ),
            )
          : (tokens.accent != null
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(2.5),
                  child: Container(height: 2.5, color: tokens.accent),
                )
              : null),
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
    final announcementsState = ref.watch(announcementsProvider);
    final recentAnnouncements = announcementsState.filteredAnnouncements.take(3).toList();

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        ref.invalidate(currentUserProvider);
        ref.invalidate(announcementsProvider);
        ref.invalidate(conversationsProvider);
      },
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

            // ─── Emergência (surge automaticamente apenas se houver protocolo ativo) ───
            _EmergencyBanner(
                onTap: () => context.push(AppRoutes.emergency)),

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
            _buildQuickAccess(context, perms, announcementsState.unreadCount),
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
            if (recentAnnouncements.isEmpty)
              Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppColors.outlineVariant),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: Text(
                      'Nenhum comunicado disponível no momento.',
                      style: TextStyle(fontSize: 13, color: AppColors.neutral600),
                    ),
                  ),
                ),
              )
            else
              ...recentAnnouncements.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _AnnouncementCard(
                    titulo: item.titulo,
                    descricao: item.mensagem,
                    prioridade: item.prioridade.name,
                    tempo: _formatDate(item.publicadoEm),
                    onTap: () => context.push('/announcements/${item.id}'),
                  ),
                ),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes <= 0 ? 1 : diff.inMinutes}min atrás';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h atrás';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d atrás';
    } else {
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    }
  }

  Widget _buildQuickAccess(BuildContext context, UserPermissions perms, int unreadAnnouncements) {
    final convs = ref.watch(conversationsProvider).valueOrNull ?? [];
    final unreadConvs = convs.fold<int>(0, (sum, c) => sum + c.unreadCount);

    final channelsState = ref.watch(channelsProvider);
    final unreadChannels =
        channelsState.channels.fold<int>(0, (sum, c) => sum + c.naoLidas);

    final cards = <_QuickCard>[];

    // Todos têm acesso — paleta institucional padronizada
    cards.add(_QuickCard(
      icon: Icons.chat_bubble_outline_rounded,
      label: 'Conversas',
      badge: unreadConvs,
      color: AppColors.primary,
      onTap: () => context.go(AppRoutes.conversations),
    ));

    cards.add(_QuickCard(
      icon: Icons.campaign_outlined,
      label: 'Canais',
      badge: unreadChannels,
      color: AppColors.primary,
      onTap: () => context.go(AppRoutes.channels),
    ));

    cards.add(_QuickCard(
      icon: Icons.article_outlined,
      label: 'Comunicados',
      badge: unreadAnnouncements,
      color: AppColors.primary,
      onTap: () => context.go(AppRoutes.announcements),
    ));

    // Notificações — todos
    cards.add(_QuickCard(
      icon: Icons.notifications_none_rounded,
      label: 'Notificações',
      color: AppColors.primary,
      onTap: () => context.push(AppRoutes.notifications),
    ));

    // Emergência — todos (vermelho de estado crítico)
    cards.add(_QuickCard(
      icon: Icons.local_hospital_outlined,
      label: 'Emergência',
      color: AppColors.emergency,
      onTap: () => context.push(AppRoutes.emergency),
    ));

    // Funcionários — somente Direção
    if (perms.canManageEmployees) {
      cards.add(_QuickCard(
        icon: Icons.people_outline_rounded,
        label: 'Funcionários',
        color: AppColors.primary,
        onTap: () => context.push(AppRoutes.employees),
      ));
    }

    // Ouvidoria / Denúncias
    cards.add(_QuickCard(
      icon: Icons.shield_outlined,
      label: perms.isDirecao ? 'Ouvidoria / Moderação' : 'Ouvidoria',
      badge: 0,
      color: AppColors.primary,
      onTap: () => context.push(AppRoutes.reports),
    ));

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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Faixa lateral institucional azul SUS
            Container(
              width: 3.5,
              color: AppColors.primary,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    // Avatar clínico institucional
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.softBlue,
                      child: Text(
                        nome.isNotEmpty ? nome[0].toUpperCase() : 'U',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Olá, $nome',
                            style: const TextStyle(
                              color: AppColors.navy,
                              fontSize: 16.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (cargo.isNotEmpty || setor.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              [cargo, setor]
                                  .where((s) => s.isNotEmpty)
                                  .join(' • '),
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Badge de hierarquia institucional
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.softBlue,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.25),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        perms.hierarquiaLabel.toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 3.5,
              color: AppColors.primaryDeep,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.admin_panel_settings_outlined,
                            color: AppColors.primaryDeep, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Painel Administrativo',
                          style: TextStyle(
                            color: AppColors.navy,
                            fontSize: 13.5,
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
              ),
            ),
          ],
        ),
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
          color: AppColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border, width: 1),
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
                color: AppColors.navy,
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
    final isEmergency = data.color == AppColors.emergency;
    final iconBg = isEmergency ? const Color(0xFFFFEBEE) : AppColors.softBlue;
    final iconColor = isEmergency ? AppColors.emergency : AppColors.primary;
    final badgeBg = isEmergency ? AppColors.emergency : AppColors.primary;

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: AppColors.border, width: 1),
      ),
      child: InkWell(
        onTap: data.onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(data.icon, color: iconColor, size: 20),
                  ),
                  if (data.badge > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: badgeBg,
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
              const SizedBox(height: 12),
              Text(
                data.label,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.navy,
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
class _EmergencyBanner extends ConsumerWidget {
  final VoidCallback onTap;
  const _EmergencyBanner({required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emergencyState = ref.watch(emergencyProvider);
    final activeAlert = emergencyState.activeAlert;
    final isAtivo = activeAlert != null && activeAlert.isAtivo;

    if (isAtivo) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.emergency, width: 1.5),
            ),
            clipBehavior: Clip.antiAlias,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 4,
                    color: AppColors.emergency,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFEBEE),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.error_outline_rounded,
                                color: AppColors.emergency, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '🚨 PROTOCOLO CRÍTICO: ${activeAlert.tipo.shortLabel.toUpperCase()}',
                                  style: const TextStyle(
                                    color: AppColors.emergency,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '📍 ${activeAlert.localizacao} • ${activeAlert.criadorNome}',
                                  style: const TextStyle(
                                    color: AppColors.navy,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: AppColors.emergency, size: 22),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Estado normal (sem emergência) -> não ocupa espaço na Home
    return const SizedBox.shrink();
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
    final isAlta = prioridade == 'alta';
    final stripeColor = isUrgente
        ? AppColors.emergency
        : (isAlta ? AppColors.warning : AppColors.border);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Faixa lateral de prioridade
                Container(
                  width: 3.5,
                  color: stripeColor,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.softBlue,
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
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.navy,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (isUrgente || isAlta) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isUrgente
                                            ? const Color(0xFFFFEBEE)
                                            : const Color(0xFFFFF3E0),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: isUrgente
                                              ? AppColors.emergency.withValues(alpha: 0.3)
                                              : AppColors.warning.withValues(alpha: 0.3),
                                          width: 0.8,
                                        ),
                                      ),
                                      child: Text(
                                        isUrgente ? 'URGENTE' : 'ALTA',
                                        style: TextStyle(
                                          color: isUrgente
                                              ? AppColors.emergency
                                              : AppColors.warning,
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                descricao,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                tempo,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
