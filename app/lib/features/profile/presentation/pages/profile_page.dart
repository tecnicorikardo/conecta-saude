import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../main.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/providers/current_user_provider.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Meu Perfil')),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              const Text('Não foi possível carregar o perfil.'),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => ref.invalidate(currentUserProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
        data: (user) {
          if (user == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Nenhum usuário autenticado.'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => context.go(AppRoutes.login),
                    child: const Text('Ir para Login'),
                  ),
                ],
              ),
            );
          }

          final initials = user.nome.trim().split(' ')
              .take(2)
              .map((e) => e.isNotEmpty ? e[0].toUpperCase() : '')
              .join();

          final themeMode = ref.watch(themeModeProvider);

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              children: [
                // ─── Avatar ────────────────────────────────────────────
                CircleAvatar(
                  radius: 46,
                  backgroundColor: AppColors.primary,
                  backgroundImage: (user.fotoUrl != null && user.fotoUrl!.isNotEmpty)
                      ? NetworkImage(user.fotoUrl!)
                      : null,
                  child: (user.fotoUrl == null || user.fotoUrl!.isEmpty)
                      ? Text(
                          initials,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 14),

                // ─── Nome e cargo ─────────────────────────────────────
                Text(
                  user.nome,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  user.cargo,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppColors.neutral600),
                ),
                const SizedBox(height: 8),

                // ─── Badge de hierarquia ──────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    user.hierarquiaNome.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onPrimaryContainer,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // ─── Informações ──────────────────────────────────────
                _InfoCard(children: [
                  _InfoRow(
                    icon: Icons.email_outlined,
                    label: 'E-mail',
                    value: user.email,
                  ),
                  const Divider(height: 1),
                  _InfoRow(
                    icon: Icons.apartment_rounded,
                    label: 'Setor',
                    value: user.setorNome.isNotEmpty
                        ? user.setorNome
                        : 'Não definido',
                  ),
                  const Divider(height: 1),
                  _InfoRow(
                    icon: Icons.shield_outlined,
                    label: 'Hierarquia',
                    value: user.hierarquiaNome,
                  ),
                ]),
                const SizedBox(height: 16),

                // ─── Tema ─────────────────────────────────────────────
                _InfoCard(children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.palette_outlined,
                                size: 18, color: AppColors.primary),
                            SizedBox(width: 12),
                            Text('Tema',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500)),
                          ],
                        ),
                        DropdownButton<ThemeMode>(
                          value: themeMode,
                          underline: const SizedBox(),
                          borderRadius: BorderRadius.circular(12),
                          items: const [
                            DropdownMenuItem(
                              value: ThemeMode.system,
                              child: Text('Sistema'),
                            ),
                            DropdownMenuItem(
                              value: ThemeMode.light,
                              child: Text('Claro'),
                            ),
                            DropdownMenuItem(
                              value: ThemeMode.dark,
                              child: Text('Escuro'),
                            ),
                          ],
                          onChanged: (mode) {
                            if (mode == null) return;
                            ref.read(themeModeProvider.notifier).state =
                                mode;
                            final prefs =
                                ref.read(sharedPreferencesProvider);
                            final value = mode == ThemeMode.dark
                                ? 'dark'
                                : mode == ThemeMode.light
                                    ? 'light'
                                    : 'system';
                            prefs.setString(
                                AppConstants.keyThemeMode, value);
                          },
                        ),
                      ],
                    ),
                  ),
                ]),
                const SizedBox(height: 24),

                // ─── Versão ──────────────────────────────────────────
                Text(
                  '${AppConstants.appName} v${AppConstants.appVersion}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.neutral500),
                ),
                const SizedBox(height: 24),

                // ─── Logout ───────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Sair da Conta',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15)),
                    onPressed: () => _confirmSignOut(context, ref),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _confirmSignOut(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Encerrar sessão'),
        content: const Text(
            'Deseja realmente sair da sua conta no Conecta Saúde?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style:
                FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final repo = ref.read(authRepositoryProvider);
              await repo.signOut();
              if (context.mounted) context.go(AppRoutes.login);
            },
            child: const Text('Sair'),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.neutral600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.neutral600)),
                const SizedBox(height: 2),
                Text(value,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
