import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/current_user_provider.dart';
import '../../domain/entities/announcement_entity.dart';
import '../providers/announcements_provider.dart';
import '../widgets/announcement_form_dialog.dart';

class AnnouncementsPage extends ConsumerWidget {
  const AnnouncementsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(announcementsProvider);
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final canCreate = currentUser != null && currentUser.hierarquiaNivel <= 2;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Comunicados'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Recarregar',
            onPressed: () =>
                ref.read(announcementsProvider.notifier).loadAnnouncements(),
          ),
        ],
      ),
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => const AnnouncementFormDialog(),
                );
              },
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text(
                'Novo Comunicado',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            )
          : null,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () =>
            ref.read(announcementsProvider.notifier).loadAnnouncements(),
        child: Column(
          children: [
            // ─── Header & Filtros ──────────────────────────────────────────
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Campo de Busca
                  TextField(
                    onChanged: (val) => ref
                        .read(announcementsProvider.notifier)
                        .setSearchQuery(val),
                    decoration: InputDecoration(
                      hintText: 'Buscar comunicado ou autor...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      filled: true,
                      fillColor: AppColors.surfaceVariant,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Chips de Filtro
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip(
                          label: 'Todos',
                          count: state.announcements.length,
                          isSelected: state.filter == AnnouncementFilter.todos,
                          onTap: () => ref
                              .read(announcementsProvider.notifier)
                              .setFilter(AnnouncementFilter.todos),
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          label: 'Não lidos',
                          count: state.unreadCount,
                          highlight: state.unreadCount > 0,
                          isSelected: state.filter == AnnouncementFilter.naoLidos,
                          onTap: () => ref
                              .read(announcementsProvider.notifier)
                              .setFilter(AnnouncementFilter.naoLidos),
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          label: 'Urgentes',
                          count: state.announcements
                              .where((a) => a.prioridade == AnnouncementPriority.urgente)
                              .length,
                          isUrgent: true,
                          isSelected: state.filter == AnnouncementFilter.urgentes,
                          onTap: () => ref
                              .read(announcementsProvider.notifier)
                              .setFilter(AnnouncementFilter.urgentes),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // ─── Lista de Comunicados ───────────────────────────────────────
            Expanded(
              child: state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : state.filteredAnnouncements.isEmpty
                      ? _buildEmptyState(state)
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 80),
                          itemCount: state.filteredAnnouncements.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final item = state.filteredAnnouncements[index];
                            return _buildAnnouncementCard(context, item);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required int count,
    required bool isSelected,
    required VoidCallback onTap,
    bool highlight = false,
    bool isUrgent = false,
  }) {
    Color selectedColor = AppColors.primary;
    if (isUrgent) selectedColor = AppColors.emergency;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? selectedColor : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? selectedColor
                : highlight
                    ? AppColors.primaryLight
                    : AppColors.outlineVariant,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.neutral800,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.25)
                      : (isUrgent
                          ? AppColors.emergencyLight
                          : AppColors.primaryContainer),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? Colors.white
                        : (isUrgent
                            ? AppColors.emergency
                            : AppColors.primary),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAnnouncementCard(BuildContext context, AnnouncementEntity item) {
    Color priorityColor;
    Color priorityBg;
    String priorityText;
    IconData priorityIcon;

    switch (item.prioridade) {
      case AnnouncementPriority.urgente:
        priorityColor = AppColors.emergency;
        priorityBg = AppColors.emergencyLight;
        priorityText = 'URGENTE';
        priorityIcon = Icons.error_outline_rounded;
        break;
      case AnnouncementPriority.alta:
        priorityColor = AppColors.warning;
        priorityBg = AppColors.warningLight;
        priorityText = 'ALTA';
        priorityIcon = Icons.warning_amber_rounded;
        break;
      case AnnouncementPriority.normal:
        priorityColor = AppColors.primary;
        priorityBg = AppColors.primaryContainer;
        priorityText = 'COMUNICADO';
        priorityIcon = Icons.info_outline_rounded;
        break;
    }

    final dateStr = DateFormat('dd/MM/yyyy • HH:mm').format(item.publicadoEm);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 0,
      child: InkWell(
        onTap: () => context.push(
          AppRoutes.announcementDetail.replaceAll(':id', item.id),
        ),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: !item.lido
                  ? priorityColor.withValues(alpha: 0.4)
                  : AppColors.outlineVariant,
              width: !item.lido ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Linha Superior: Badge de Prioridade + Status Lido/Não Lido
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: priorityBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(priorityIcon, size: 13, color: priorityColor),
                        const SizedBox(width: 4),
                        Text(
                          priorityText,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: priorityColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (!item.lido)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 3.5,
                            backgroundColor: AppColors.primary,
                          ),
                          SizedBox(width: 5),
                          Text(
                            'Pendente de leitura',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_outline_rounded,
                          size: 14,
                          color: AppColors.success,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Lido',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 10),

              // Título
              Text(
                item.titulo,
                style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.neutral900,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 6),

              // Prévia da Mensagem
              Text(
                item.mensagem,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.neutral600,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 12),

              // Rodapé: Autor e Data
              Row(
                children: [
                  const Icon(
                    Icons.account_circle_outlined,
                    size: 14,
                    color: AppColors.neutral500,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      '${item.criadorNome} • ${item.criadorCargo}',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.neutral600,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    dateStr,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.neutral500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(AnnouncementsState state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.campaign_outlined,
                size: 40,
                color: AppColors.neutral500,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Nenhum comunicado encontrado',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.neutral800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              state.searchQuery.isNotEmpty
                  ? 'Nenhum resultado corresponde à sua busca.'
                  : 'Nenhum comunicado cadastrado para o filtro selecionado.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.neutral600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
