import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import '../auth/permissions_provider.dart';
import '../../features/chat/domain/entities/conversation_entity.dart';
import '../../features/chat/presentation/providers/chat_provider.dart';
import '../../features/channels/presentation/providers/channels_provider.dart';
import '../../features/announcements/presentation/providers/announcements_provider.dart';

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

class _MainShellState extends ConsumerState<MainShell> {
  @override
  Widget build(BuildContext context) {
    final perms = ref.watch(permissionsProvider);
    final currentUserId = ref.watch(currentUserIdProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Escutar novas mensagens em tempo real para exibir popup persistente com botão de abrir
    ref.listen<AsyncValue<List<ConversationEntity>>>(conversationsProvider, (prev, next) {
      final prevList = prev?.valueOrNull ?? [];
      final nextList = next.valueOrNull ?? [];
      final prevUnread = prevList.fold<int>(0, (sum, c) => sum + c.unreadCount.toInt());
      final nextUnread = nextList.fold<int>(0, (sum, c) => sum + c.unreadCount.toInt());

      if (nextUnread > prevUnread && nextList.isNotEmpty) {
        final convWithNewMsg = nextList.firstWhere(
          (c) => c.unreadCount > 0,
          orElse: () => nextList.first,
        );

        final senderName = convWithNewMsg.displayName(currentUserId);
        final lastMsg = convWithNewMsg.lastMessage?.texto ?? 'Nova mensagem recebida';

        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 8),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.primaryDark,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
            content: Row(
              children: [
                const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        senderName,
                        style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 13.5),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        lastMsg,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            action: SnackBarAction(
              label: 'ABRIR',
              textColor: const Color(0xFFFFD54F),
              onPressed: () {
                context.push(
                  '/chat/${convWithNewMsg.id}',
                  extra: convWithNewMsg,
                );
              },
            ),
          ),
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
      body: widget.navigationShell,
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
      _NavItemData(
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
        _NavItemData(
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
