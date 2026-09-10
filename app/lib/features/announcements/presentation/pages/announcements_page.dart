import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme_provider.dart';
import '../../domain/entities/announcement_entity.dart';
import '../providers/announcements_provider.dart';

class AnnouncementsPage extends ConsumerWidget {
  const AnnouncementsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(announcementsProvider);
    final tokens = context.appTokens;

    return Scaffold(
      backgroundColor: tokens.background,
      appBar: AppBar(
        title: const Text(
          'Comunicados Oficiais',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            letterSpacing: 0.2,
          ),
        ),
        backgroundColor: tokens.primaryDark,
        foregroundColor: Colors.white,
        bottom: tokens.identityRainbow.isNotEmpty
            ? PreferredSize(
                preferredSize: const Size.fromHeight(3.0),
                child: tokens.buildHorizontalAccent(height: 3.0),
              )
            : (tokens.accent != null
                ? PreferredSize(
                    preferredSize: const Size.fromHeight(2.5),
                    child: tokens.buildHorizontalAccent(height: 2.5),
                  )
                : null),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: tokens.primaryDark,
          statusBarIconBrightness: Brightness.light,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(announcementsProvider.notifier).loadAnnouncements(),
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.errorMessage != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: AppColors.emergency),
                    const SizedBox(height: 12),
                    Text(
                      state.errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: tokens.textPrimary),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () => ref.read(announcementsProvider.notifier).loadAnnouncements(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              ),
            );
          }
          final items = state.filteredAnnouncements;
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.campaign_outlined,
                    size: 64,
                    color: tokens.border,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhum comunicado no momento.',
                    style: TextStyle(
                      fontSize: 15,
                      color: tokens.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final a = items[index];

              final overrideStripe = a.prioridade == AnnouncementPriority.urgente
                  ? tokens.critical
                  : (a.prioridade == AnnouncementPriority.alta
                      ? tokens.warning
                      : null);

              return Material(
                color: tokens.surface,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  onTap: () => context.push('/announcements/${a.id}'),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: tokens.border,
                        width: 1,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Faixa lateral de prioridade adaptada ao tema
                          tokens.buildVerticalStripe(
                            width: 4,
                            overrideColor: overrideStripe,
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      if (a.prioridade != AnnouncementPriority.normal) ...[
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: a.prioridade == AnnouncementPriority.urgente
                                                ? const Color(0xFFFFEBEE)
                                                : const Color(0xFFFFF3E0),
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(
                                              color: a.prioridade == AnnouncementPriority.urgente
                                                  ? tokens.critical.withValues(alpha: 0.3)
                                                  : tokens.warning.withValues(alpha: 0.3),
                                              width: 0.8,
                                            ),
                                          ),
                                          child: Text(
                                            a.prioridade.label.toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: a.prioridade == AnnouncementPriority.urgente
                                                  ? tokens.critical
                                                  : tokens.warning,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                      ],
                                      Expanded(
                                        child: Text(
                                          a.titulo,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15,
                                            color: tokens.textPrimary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Icon(
                                        Icons.chevron_right,
                                        size: 18,
                                        color: tokens.textSecondary,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    a.mensagem,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: tokens.textSecondary,
                                      height: 1.35,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.schedule,
                                        size: 13,
                                        color: tokens.textSecondary,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        DateFormat('dd/MM/yyyy HH:mm').format(a.publicadoEm),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: tokens.textSecondary,
                                        ),
                                      ),
                                      if (a.criadorNome.isNotEmpty) ...[
                                        const SizedBox(width: 8),
                                        Text(
                                          '•',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: tokens.textSecondary,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            a.criadorNome,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: tokens.textSecondary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
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
            },
          );
        },
      ),
    );
  }
}
