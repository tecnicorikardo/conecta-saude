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
import '../../../chat/domain/entities/conversation_entity.dart';
import '../../../chat/domain/entities/message_entity.dart';
import '../../../chat/presentation/widgets/conversation_avatar.dart';
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
    final tokens = context.appTokens;
    final nomeCompleto = user?.nome ?? 'Usuário';
    final saudacaoNome = _formatGreetingName(nomeCompleto);
    final cargo = user?.cargo ?? '';
    final setor = user?.setorNome ?? '';
    final announcementsState = ref.watch(announcementsProvider);
    final recentAnnouncements = announcementsState.filteredAnnouncements.take(3).toList();
    final convsAsync = ref.watch(conversationsProvider);
    final allConvs = convsAsync.valueOrNull ?? [];
    final recentConvs = allConvs.take(3).toList();
    final currentUserId = ref.watch(currentUserIdProvider);

    return RefreshIndicator(
      color: tokens.primary,
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
            // ─── Card de boas-vindas com badge de nível e status ────────
            _WelcomeCard(
              nome: saudacaoNome,
              nomeCompleto: nomeCompleto,
              cargo: cargo,
              setor: setor,
              perms: perms,
              user: user,
            ),
            const SizedBox(height: 16),

            // ─── Emergência (surge automaticamente apenas se houver protocolo ativo) ───
            _EmergencyBanner(
                onTap: () => context.push(AppRoutes.emergency)),

            // ─── Acesso Rápido ───────────────────────────────────────────
            Text(
              'Acesso Rápido',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: tokens.textSecondary,
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

            // ─── Mensagens Recentes ──────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Mensagens Recentes',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: tokens.textSecondary,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                ),
                TextButton(
                  onPressed: () => context.go(AppRoutes.conversations),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Ver todas',
                    style: TextStyle(
                      fontSize: 12,
                      color: tokens.themeAccentColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (convsAsync.isLoading && recentConvs.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: tokens.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: tokens.border, width: 1),
                ),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: tokens.primary,
                    ),
                  ),
                ),
              )
            else if (recentConvs.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: tokens.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: tokens.border, width: 1),
                ),
                child: Center(
                  child: Text(
                    'Nenhuma mensagem recente.',
                    style: TextStyle(fontSize: 13, color: tokens.textSecondary),
                  ),
                ),
              )
            else
              ...recentConvs.map(
                (conv) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _RecentMessageCard(
                    conv: conv,
                    currentUserId: currentUserId,
                    onTap: () => context.push('/chat/${conv.id}', extra: conv),
                  ),
                ),
              ),
            const SizedBox(height: 20),

            // ─── Comunicados recentes ────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Comunicados Recentes',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: tokens.textSecondary,
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
                  child: Text(
                    'Ver todos',
                    style: TextStyle(
                      fontSize: 12,
                      color: tokens.themeAccentColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (announcementsState.isLoading && recentAnnouncements.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: tokens.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: tokens.border, width: 1),
                ),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: tokens.primary,
                    ),
                  ),
                ),
              )
            else if (recentAnnouncements.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: tokens.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: tokens.border, width: 1),
                ),
                child: Center(
                  child: Text(
                    'Nenhum comunicado disponível no momento.',
                    style: TextStyle(fontSize: 13, color: tokens.textSecondary),
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

  static String _formatGreetingName(String fullName) {
    final trimmed = fullName.trim();
    if (trimmed.isEmpty) return 'Usuário';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.isEmpty) return 'Usuário';

    final titles = {
      'dr.', 'dr', 'dra.', 'dra', 'enf.', 'enf',
      'enfermeiro', 'enfermeira', 'prof.', 'prof',
      'profa.', 'profa', 'tec.', 'tec', 'técnico', 'técnica',
      'sr.', 'sr', 'sra.', 'sra', 'med.', 'médico', 'médica'
    };
    final firstLower = parts.first.toLowerCase();
    if (titles.contains(firstLower) && parts.length > 1) {
      return '${parts[0]} ${parts[1]}';
    }
    return parts.first;
  }

  static String _extractInitials(String name) {
    final clean = name.trim();
    if (clean.isEmpty) return 'U';
    final parts = clean.split(RegExp(r'\s+'));
    final titles = {
      'dr.', 'dr', 'dra.', 'dra', 'enf.', 'enf',
      'enfermeiro', 'enfermeira', 'prof.', 'prof',
      'profa.', 'profa', 'tec.', 'tec', 'técnico', 'técnica',
      'sr.', 'sr', 'sra.', 'sra', 'med.', 'médico', 'médica'
    };
    if (parts.isNotEmpty && titles.contains(parts.first.toLowerCase()) && parts.length > 1) {
      if (parts.length >= 3) {
        return '${parts[1][0]}${parts[2][0]}'.toUpperCase();
      }
      return parts[1][0].toUpperCase();
    }
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts.isNotEmpty && parts[0].isNotEmpty ? parts[0][0].toUpperCase() : 'U';
  }

  String _initials(String name) => _extractInitials(name);
}

// ─── Card de boas-vindas ──────────────────────────────────────────────────────
class _WelcomeCard extends StatelessWidget {
  final String nome;
  final String nomeCompleto;
  final String cargo;
  final String setor;
  final UserPermissions perms;
  final UserEntity? user;

  const _WelcomeCard({
    required this.nome,
    required this.nomeCompleto,
    required this.cargo,
    required this.setor,
    required this.perms,
    this.user,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.appTokens;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: tokens.border, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          if (tokens.identityRainbow.isNotEmpty)
            tokens.buildHorizontalAccent(height: 2.5),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                tokens.buildVerticalStripe(width: 3.5),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: tokens.iconContainerColor,
                              child: Text(
                                _HomePageState._extractInitials(nomeCompleto),
                                style: TextStyle(
                                  color: tokens.themeAccentColor,
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
                                    style: TextStyle(
                                      color: tokens.textPrimary,
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
                                      style: TextStyle(
                                        color: tokens.textSecondary,
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
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                                  decoration: BoxDecoration(
                                    color: tokens.iconContainerColor,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: tokens.themeAccentColor.withValues(alpha: 0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    perms.hierarquiaLabel.toUpperCase(),
                                    style: TextStyle(
                                      color: tokens.themeAccentColor,
                                      fontSize: 9.0,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                ),
                                if (user != null) ...[
                                  const SizedBox(height: 5),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: user!.workStatusColor.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: user!.workStatusColor.withValues(alpha: 0.35),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 6.5,
                                          height: 6.5,
                                          decoration: BoxDecoration(
                                            color: user!.workStatusColor,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          user!.workStatusLabel,
                                          style: TextStyle(
                                            color: user!.workStatusColor,
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.2,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                        if (user != null && user!.workStatusLabel == 'Fora de Serviço') ...[
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF8E1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFFFE082), width: 0.8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.nightlight_round, size: 14, color: Color(0xFFD97706)),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Fora de Serviço • Plantão: ${user!.jornadaInicio} às ${user!.jornadaFim} (Mensagens silenciadas)',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF92400E),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
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
    final tokens = context.appTokens;

    return Container(
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: tokens.border, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            tokens.buildVerticalStripe(width: 3.5, overrideColor: tokens.primaryDark),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.admin_panel_settings_outlined,
                            color: tokens.themeAccentColor, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Painel Administrativo',
                          style: TextStyle(
                            color: tokens.textPrimary,
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
                            semanticLabel: 'Painel Administrativo: Gestão de Funcionários',
                            onTap: () => context.push(AppRoutes.employees),
                          ),
                        if (perms.canViewReports)
                          _AdminChip(
                            icon: Icons.flag_outlined,
                            label: 'Denúncias',
                            semanticLabel: 'Painel Administrativo: Gestão de Denúncias',
                            onTap: () => context.push(AppRoutes.reports),
                          ),
                        if (perms.canViewAudit)
                          _AdminChip(
                            icon: Icons.history_outlined,
                            label: 'Auditoria',
                            semanticLabel: 'Painel Administrativo: Registros de Auditoria',
                            onTap: () => context.push(AppRoutes.auditLogs),
                          ),
                        _AdminChip(
                          icon: Icons.bar_chart_outlined,
                          label: 'Relatórios',
                          semanticLabel: 'Painel Administrativo: Relatórios e Estatísticas',
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
  final String? semanticLabel;
  final VoidCallback onTap;

  const _AdminChip({
    required this.icon,
    required this.label,
    this.semanticLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.appTokens;

    return Semantics(
      label: semanticLabel ?? 'Painel Administrativo: $label',
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: tokens.iconContainerColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: tokens.border, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: tokens.themeAccentColor),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: tokens.textPrimary,
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
    final tokens = context.appTokens;
    final isEmergency = data.color == AppColors.emergency;
    final iconBg = isEmergency ? const Color(0xFFFFEBEE) : tokens.iconContainerColor;
    final iconColor = isEmergency ? tokens.critical : tokens.themeAccentColor;
    final badgeBg = isEmergency ? tokens.critical : tokens.themeAccentColor;

    return Semantics(
      label: 'Acesso rápido: ${data.label}',
      button: true,
      child: Card(
        elevation: 0,
        color: tokens.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: tokens.border, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: data.onTap,
          borderRadius: BorderRadius.circular(10),
          child: Column(
            children: [
              if (!isEmergency)
                tokens.buildHorizontalAccent(height: 2.5),
              Padding(
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
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: tokens.textPrimary,
                      ),
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

// ─── Banner de emergência ─────────────────────────────────────────────────────
class _EmergencyBanner extends ConsumerWidget {
  final VoidCallback onTap;
  const _EmergencyBanner({required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.appTokens;
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
              color: tokens.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: tokens.critical, width: 1.5),
            ),
            clipBehavior: Clip.antiAlias,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  tokens.buildVerticalStripe(width: 4, overrideColor: tokens.critical),
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
                            child: Icon(Icons.error_outline_rounded,
                                color: tokens.critical, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '🚨 PROTOCOLO CRÍTICO: ${activeAlert.tipo.shortLabel.toUpperCase()}',
                                  style: TextStyle(
                                    color: tokens.critical,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '📍 ${activeAlert.localizacao} • ${activeAlert.criadorNome}',
                                  style: TextStyle(
                                    color: tokens.textPrimary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right, color: tokens.critical, size: 22),
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

// ─── Card de mensagem recente ─────────────────────────────────────────────────
class _RecentMessageCard extends StatelessWidget {
  final ConversationEntity conv;
  final String currentUserId;
  final VoidCallback onTap;

  const _RecentMessageCard({
    required this.conv,
    required this.currentUserId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.appTokens;
    final isGroup = conv.isGroup;
    final displayName = conv.displayName(currentUserId);
    final photoUrl = conv.displayPhoto(currentUserId);
    final lastMsg = conv.lastMessage;
    final hasUnread = conv.unreadCount > 0;

    return Container(
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: hasUnread ? tokens.themeAccentColor.withValues(alpha: 0.5) : tokens.border,
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Column(
            children: [
              if (tokens.identityRainbow.isNotEmpty)
                tokens.buildHorizontalAccent(height: 2.0),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    tokens.buildVerticalStripe(
                      width: 3.5,
                      overrideColor: hasUnread ? null : tokens.border.withValues(alpha: 0.5),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Row(
                          children: [
                            ConversationAvatar(
                              name: displayName,
                              photoUrl: photoUrl,
                              isGroup: isGroup,
                              size: 40,
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
                                          displayName,
                                          style: TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w600,
                                            color: tokens.textPrimary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (lastMsg != null) ...[
                                        const SizedBox(width: 6),
                                        Text(
                                          _formatMsgDate(lastMsg.criadoEm),
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: tokens.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _getMessagePreview(lastMsg),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: hasUnread ? tokens.textPrimary : tokens.textSecondary,
                                            fontWeight: hasUnread ? FontWeight.w500 : FontWeight.w400,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (hasUnread) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: tokens.themeAccentColor,
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            '${conv.unreadCount}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
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
            ],
          ),
        ),
      ),
    );
  }

  String _getMessagePreview(MessageEntity? msg) {
    if (msg == null) return 'Nenhuma mensagem ainda';
    if (msg.tipo == MessageType.audio) return '🎤 Mensagem de voz';
    if (msg.tipo == MessageType.image) return '📷 Imagem';
    return msg.texto.isNotEmpty ? msg.texto : 'Mensagem';
  }

  String _formatMsgDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes <= 0 ? 1 : diff.inMinutes}min';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h';
    } else {
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}';
    }
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
    final tokens = context.appTokens;
    final isUrgente = prioridade == 'urgente';
    final isAlta = prioridade == 'alta';
    final overrideStripe = isUrgente
        ? tokens.critical
        : (isAlta ? tokens.warning : null);

    return Container(
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: tokens.border, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Column(
            children: [
              if (!isUrgente && !isAlta && tokens.identityRainbow.isNotEmpty)
                tokens.buildHorizontalAccent(height: 2.0),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    tokens.buildVerticalStripe(
                      width: 3.5,
                      overrideColor: overrideStripe,
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
                                color: tokens.iconContainerColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.article_outlined,
                                  color: tokens.themeAccentColor, size: 20),
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
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: tokens.textPrimary,
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
                                                  ? tokens.critical.withValues(alpha: 0.3)
                                                  : tokens.warning.withValues(alpha: 0.3),
                                              width: 0.8,
                                            ),
                                          ),
                                          child: Text(
                                            isUrgente ? 'URGENTE' : 'ALTA',
                                            style: TextStyle(
                                              color: isUrgente
                                                  ? tokens.critical
                                                  : tokens.warning,
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
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: tokens.textSecondary,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    tempo,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: tokens.textSecondary,
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
            ],
          ),
        ),
      ),
    );
  }
}
