import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import '../auth/permissions_provider.dart';

/// Shell principal — bottom navigation fixo adaptado por hierarquia.
///
/// Funcionário    : Início | Conversas | Canais | Comunicados
/// Supervisão     : Início | Conversas | Canais | Comunicados
/// Coordenação    : Início | Conversas | Canais | Comunicados | Admin
/// Direção        : Início | Conversas | Canais | Comunicados | Admin
class MainShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perms = ref.watch(permissionsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: AppColors.primaryDark,
      statusBarIconBrightness: Brightness.light,
    ));

    // ─── Itens do menu por nível ──────────────────────────────────────────
    final navItems = _buildNavItems(perms);

    return Scaffold(
      body: navigationShell,
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
                  currentIndex: navigationShell.currentIndex,
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

  List<_NavItemData> _buildNavItems(UserPermissions perms) {
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
        badge: 2,
      ),
      _NavItemData(
        branchIndex: 2,
        icon: Icons.campaign_outlined,
        activeIcon: Icons.campaign_rounded,
        label: 'Canais',
      ),
      _NavItemData(
        branchIndex: 3,
        icon: Icons.article_outlined,
        activeIcon: Icons.article_rounded,
        label: 'Comunicados',
        badge: 1,
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
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
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
