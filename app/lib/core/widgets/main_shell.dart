import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import '../auth/permissions_provider.dart';
import '../services/notification_service.dart';
import '../services/web_notification_helper.dart';
import '../../features/chat/domain/entities/conversation_entity.dart';
import '../../features/chat/presentation/providers/chat_provider.dart';
import '../../features/channels/presentation/providers/channels_provider.dart';
import '../../features/announcements/presentation/providers/announcements_provider.dart';
import '../../features/auth/presentation/providers/current_user_provider.dart';
import '../../features/profile/presentation/widgets/shift_end_dialog.dart';

/// Alerta de nova mensagem em primeiro plano
class _InAppNotificationData {
  final String conversationId;
  final String senderName;
  final String messageText;
  final ConversationEntity? conversation;
  final DateTime receivedAt;

  _InAppNotificationData({
    required this.conversationId,
    required this.senderName,
    required this.messageText,
    this.conversation,
    required this.receivedAt,
  });
}

/// Shell principal — bottom navigation fixo adaptado por hierarquia.
///
/// Funcionário    : Início | Conversas | Canais | Comunicados
/// Supervisão     : Início | Conversas | Canais | Comunicados
/// Coordenação    : Início | Conversas | Canais | Comunicados | Admin
/// Direção        : Início | Conversas | Canais | Comunicados | Admin
class MainShell extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell>
    with SingleTickerProviderStateMixin {
  _InAppNotificationData? _activeNotification;
  Timer? _notificationDismissTimer;
  Timer? _shiftMonitorTimer;
  String? _lastShiftEndAlertDate;
  late AnimationController _animController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    ));

    // Inicializar serviço de Push Notifications (FCM Web / Mobile)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationServiceProvider).initialize();
      _checkShiftEnd();
    });

    // Monitorar a cada 20 segundos para disparar quando bater o horário de término (ex: 16:00)
    _shiftMonitorTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      _checkShiftEnd();
    });
  }

  @override
  void dispose() {
    _notificationDismissTimer?.cancel();
    _shiftMonitorTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  void _checkShiftEnd() {
    if (!mounted) return;
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null || !user.ativo) return;

    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    // Evita disparar mais de uma vez no mesmo dia se já foi alertado ou respondido
    if (_lastShiftEndAlertDate == todayStr) return;

    // Verificar se hoje é dia previsto na escala de trabalho
    final dayCodes = {
      1: 'seg',
      2: 'ter',
      3: 'qua',
      4: 'qui',
      5: 'sex',
      6: 'sab',
      7: 'dom',
    };
    final todayCode = dayCodes[now.weekday] ?? 'seg';
    final dias = user.jornadaDias.toLowerCase().split(',').map((d) => d.trim()).toList();
    if (!dias.contains(todayCode)) return;

    // Se o usuário está em horas extras já prorrogadas que ainda estão ativas hoje
    if (user.jornadaEstendidaAte != null && now.isBefore(user.jornadaEstendidaAte!)) {
      return;
    }

    final endParts = user.jornadaFim.split(':').map((e) => int.tryParse(e) ?? 0).toList();
    final startParts = user.jornadaInicio.split(':').map((e) => int.tryParse(e) ?? 0).toList();
    final endMinutes = (endParts.isNotEmpty ? endParts[0] : 16) * 60 +
        (endParts.length > 1 ? endParts[1] : 0);
    final startMinutes = (startParts.isNotEmpty ? startParts[0] : 7) * 60 +
        (startParts.length > 1 ? startParts[1] : 0);
    final nowMinutes = now.hour * 60 + now.minute;

    // Dispara quando atinge o horário de término (ou até 45 min após término)
    bool reachedEnd = false;
    if (endMinutes >= startMinutes) {
      reachedEnd = nowMinutes >= endMinutes && nowMinutes <= (endMinutes + 45);
    } else {
      reachedEnd = nowMinutes >= endMinutes && nowMinutes < startMinutes;
    }

    if (reachedEnd) {
      _lastShiftEndAlertDate = todayStr;
      notifyHospitalUser(
        '🏁 Fim de Expediente (${user.jornadaFim})',
        'Seu turno habitual encerrou. Toque para ir para casa ou prorrogar suas horas.',
        tag: 'shift_end',
        url: '/profile',
      );
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => ShiftEndDialog(
          user: user,
          onDismiss: () {
            // Fechamento normal
          },
        ),
      );
    }
  }

  void _showInAppAlert({
    required String conversationId,
    required String senderName,
    required String messageText,
    ConversationEntity? conversation,
  }) {
    HapticFeedback.heavyImpact();
    _notificationDismissTimer?.cancel();

    setState(() {
      _activeNotification = _InAppNotificationData(
        conversationId: conversationId,
        senderName: senderName,
        messageText: messageText,
        conversation: conversation,
        receivedAt: DateTime.now(),
      );
    });

    _animController.forward(from: 0.0);

    // Permanece visível por 15 segundos para dar tempo do usuário ver e clicar
    _notificationDismissTimer = Timer(const Duration(seconds: 15), () {
      _dismissInAppAlert();
    });
  }

  void _dismissInAppAlert() {
    _animController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _activeNotification = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final perms = ref.watch(permissionsProvider);
    final currentUserId = ref.watch(currentUserIdProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Escutar novas mensagens em tempo real para exibir o banner flutuante superior
    ref.listen<AsyncValue<List<ConversationEntity>>>(conversationsProvider,
        (prev, next) {
      final prevList = prev?.valueOrNull ?? [];
      final nextList = next.valueOrNull ?? [];
      final prevUnread =
          prevList.fold<int>(0, (sum, c) => sum + c.unreadCount.toInt());
      final nextUnread =
          nextList.fold<int>(0, (sum, c) => sum + c.unreadCount.toInt());

      if (nextUnread > prevUnread && nextList.isNotEmpty) {
        final convWithNewMsg = nextList.firstWhere(
          (c) => c.unreadCount > 0,
          orElse: () => nextList.first,
        );

        // Se a mensagem foi enviada pelo próprio usuário logado, não exibe alerta
        if (convWithNewMsg.lastMessage?.remetente.id == currentUserId) {
          return;
        }

        // Se o usuário já está com essa conversa aberta na tela, não exibe alerta sobreposto
        try {
          final currentUri = GoRouterState.of(context).uri.toString();
          if (currentUri.contains(convWithNewMsg.id)) {
            return;
          }
        } catch (_) {}

        // Se o usuário estiver Fora de Serviço com silenciamento ativado, não exibe o banner interno
        final currentUser = ref.read(currentUserProvider).valueOrNull;
        if (currentUser != null &&
            currentUser.silenciarForaJornada &&
            !currentUser.isCurrentlyWorking) {
          return;
        }

        final senderName = convWithNewMsg.displayName(currentUserId);
        final lastMsg =
            convWithNewMsg.lastMessage?.texto ?? 'Nova mensagem institucional';

        _showInAppAlert(
          conversationId: convWithNewMsg.id,
          senderName: senderName,
          messageText: lastMsg,
          conversation: convWithNewMsg,
        );
      }
    });

    // Badges dinâmicos em tempo real
    final convs = ref.watch(conversationsProvider).valueOrNull ?? [];
    final unreadConvs = convs.fold<int>(0, (sum, c) => sum + c.unreadCount);

    final channelsState = ref.watch(channelsProvider);
    final unreadChannels =
        channelsState.channels.fold<int>(0, (sum, c) => sum + c.naoLidas);

    final announcementsState = ref.watch(announcementsProvider);
    final unreadAnnouncements = announcementsState.unreadCount;

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: AppColors.primaryDark,
      statusBarIconBrightness: Brightness.light,
    ));

    // ─── Itens do menu por nível ──────────────────────────────────────────
    final navItems = _buildNavItems(
      perms,
      unreadConvs: unreadConvs,
      unreadChannels: unreadChannels,
      unreadAnnouncements: unreadAnnouncements,
    );

    return Scaffold(
      body: Stack(
        children: [
          widget.navigationShell,

          // ─── Banner Flutuante de Notificação Superior ──────────────────────
          if (_activeNotification != null)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0D253F), Color(0xFF1565C0)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                        border: Border.all(
                          color: const Color(0xFF42A5F5).withValues(alpha: 0.6),
                          width: 1.5,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            final alert = _activeNotification;
                            _dismissInAppAlert();
                            if (alert != null) {
                              context.push(
                                '/chat/${alert.conversationId}',
                                extra: alert.conversation,
                              );
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.chat_bubble_rounded,
                                    color: Color(0xFFFFD54F),
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              _activeNotification!.senderName,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 14,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const Text(
                                            'Agora',
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        _activeNotification!.messageText,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12.5,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: () {
                                    final alert = _activeNotification;
                                    _dismissInAppAlert();
                                    if (alert != null) {
                                      context.push(
                                        '/chat/${alert.conversationId}',
                                        extra: alert.conversation,
                                      );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFFD54F),
                                    foregroundColor: const Color(0xFF0D253F),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    textStyle: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                    ),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  child: const Text('ABRIR'),
                                ),
                                const SizedBox(width: 4),
                                IconButton(
                                  icon: const Icon(Icons.close,
                                      color: Colors.white70, size: 20),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                      minWidth: 28, minHeight: 28),
                                  onPressed: _dismissInAppAlert,
                                  tooltip: 'Fechar',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark
                  ? const Color(0xFF1E3A5F)
                  : AppColors.outlineVariant,
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(
              children: navItems.map((item) {
                return _NavItem(
                  index: item.branchIndex,
                  currentIndex: widget.navigationShell.currentIndex,
                  icon: item.icon,
                  activeIcon: item.activeIcon,
                  label: item.label,
                  badge: item.badge,
                  onTap: () => _goBranch(item.branchIndex),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  List<_NavItemData> _buildNavItems(
    UserPermissions perms, {
    required int unreadConvs,
    required int unreadChannels,
    required int unreadAnnouncements,
  }) {
    final items = <_NavItemData>[
      const _NavItemData(
        branchIndex: 0,
        icon: Icons.home_outlined,
        activeIcon: Icons.home_rounded,
        label: 'Início',
      ),
      _NavItemData(
        branchIndex: 1,
        icon: Icons.chat_bubble_outline_rounded,
        activeIcon: Icons.chat_bubble_rounded,
        label: 'Conversas',
        badge: unreadConvs,
      ),
      _NavItemData(
        branchIndex: 2,
        icon: Icons.campaign_outlined,
        activeIcon: Icons.campaign_rounded,
        label: 'Canais',
        badge: unreadChannels,
      ),
      _NavItemData(
        branchIndex: 3,
        icon: Icons.article_outlined,
        activeIcon: Icons.article_rounded,
        label: 'Comunicados',
        badge: unreadAnnouncements,
      ),
    ];

    // Aba Admin — somente Coordenação e Direção
    if (perms.canAccessAdmin) {
      items.add(
        const _NavItemData(
          branchIndex: 4,
          icon: Icons.admin_panel_settings_outlined,
          activeIcon: Icons.admin_panel_settings_rounded,
          label: 'Admin',
        ),
      );
    }

    return items;
  }

  void _goBranch(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }
}

// ─── Modelo de item de navegação ──────────────────────────────────────────────
class _NavItemData {
  final int branchIndex;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int badge;

  const _NavItemData({
    required this.branchIndex,
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.badge = 0,
  });
}

// ─── Widget de item do nav ────────────────────────────────────────────────────
class _NavItem extends StatelessWidget {
  final int index;
  final int currentIndex;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int badge;
  final VoidCallback onTap;

  const _NavItem({
    required this.index,
    required this.currentIndex,
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.onTap,
    this.badge = 0,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = index == currentIndex;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final activeColor =
        isDark ? AppColors.secondaryLight : AppColors.primary;
    final inactiveColor =
        isDark ? AppColors.onDarkSurfaceVariant : AppColors.neutral600;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isDark
                            ? AppColors.primaryDark
                            : AppColors.primaryContainer)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    isSelected ? activeIcon : icon,
                    color: isSelected ? activeColor : inactiveColor,
                    size: 22,
                  ),
                ),
                if (badge > 0)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          badge > 9 ? '9+' : '$badge',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight:
                    isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? activeColor : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
