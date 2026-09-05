import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/channel_entity.dart';
import '../providers/channels_provider.dart';

class ChannelsPage extends ConsumerWidget {
  const ChannelsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(channelsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Canais de Comunicação'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Atualizar',
            onPressed: () => ref.read(channelsProvider.notifier).loadChannels(),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => ref.read(channelsProvider.notifier).loadChannels(),
        child: Column(
          children: [
            // ─── Busca e Abas ──────────────────────────────────────────────
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Campo de Busca
                  TextField(
                    onChanged: (val) => ref
                        .read(channelsProvider.notifier)
                        .setSearchQuery(val),
                    decoration: InputDecoration(
                      hintText: 'Buscar canal por nome ou setor...',
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

                  // Abas dos Centros Oficiais: CCD (esquerda), CCO (meio), CCE (direita)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildCategoryChip(
                          label: 'CCD (CCDTI)',
                          sublabel: 'Imagem e Diagnóstico',
                          isSelected: state.selectedTab == ChannelTab.ccd,
                          onTap: () => ref
                              .read(channelsProvider.notifier)
                              .setTab(ChannelTab.ccd),
                        ),
                        const SizedBox(width: 8),
                        _buildCategoryChip(
                          label: 'CCO',
                          sublabel: 'Centro do Olho',
                          isSelected: state.selectedTab == ChannelTab.cco,
                          onTap: () => ref
                              .read(channelsProvider.notifier)
                              .setTab(ChannelTab.cco),
                        ),
                        const SizedBox(width: 8),
                        _buildCategoryChip(
                          label: 'CCE',
                          sublabel: 'Especialidades',
                          isSelected: state.selectedTab == ChannelTab.cce,
                          onTap: () => ref
                              .read(channelsProvider.notifier)
                              .setTab(ChannelTab.cce),
                        ),
                        const SizedBox(width: 8),
                        _buildCategoryChip(
                          label: '🚨 Emergência',
                          isSelected: state.selectedTab == ChannelTab.emergencia,
                          isUrgent: true,
                          onTap: () => ref
                              .read(channelsProvider.notifier)
                              .setTab(ChannelTab.emergencia),
                        ),
                        const SizedBox(width: 8),
                        _buildCategoryChip(
                          label: 'Todos',
                          isSelected: state.selectedTab == ChannelTab.todos,
                          onTap: () => ref
                              .read(channelsProvider.notifier)
                              .setTab(ChannelTab.todos),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // ─── Lista de Canais ───────────────────────────────────────────
            Expanded(
              child: state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
                      children: [
                        // Banner Destaque Emergência
                        if (state.selectedTab == ChannelTab.emergencia &&
                            state.emergencyChannel != null &&
                            state.searchQuery.isEmpty) ...[
                          _buildEmergencyBanner(
                            context,
                            state.emergencyChannel!,
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Lista Filtrada
                        if (state.filteredChannels.isEmpty)
                          _buildEmptyState(state)
                        else
                          ...state.filteredChannels.map((channel) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _buildChannelCard(context, channel),
                            );
                          }),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip({
    required String label,
    String? sublabel,
    required bool isSelected,
    required VoidCallback onTap,
    bool isUrgent = false,
  }) {
    Color selectedColor = AppColors.primary;
    if (isUrgent) selectedColor = AppColors.emergency;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? selectedColor : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? selectedColor : AppColors.outlineVariant,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.neutral800,
              ),
            ),
            if (sublabel != null)
              Text(
                sublabel,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.85)
                      : AppColors.neutral600,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyBanner(BuildContext context, ChannelEntity channel) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.emergency,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.emergency.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => context.push(AppRoutes.emergency),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.warning_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'CANAL DE EMERGÊNCIA',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                            ),
                          ),
                          const Spacer(),
                          if (channel.naoLidas > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${channel.naoLidas} novo(s)',
                                style: const TextStyle(
                                  color: AppColors.emergency,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        channel.descricao ?? 'Canal prioritário hospitalar',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 12,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white70,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChannelCard(BuildContext context, ChannelEntity channel) {
    IconData icon = Icons.forum_rounded;
    Color iconBg = AppColors.surfaceVariant;
    Color iconColor = AppColors.neutral700;

    switch (channel.tipo) {
      case ChannelType.institucional:
        icon = Icons.campaign_rounded;
        iconBg = AppColors.primaryContainer;
        iconColor = AppColors.primary;
        break;
      case ChannelType.setor:
        icon = Icons.groups_rounded;
        iconBg = const Color(0xFFE0F2F1);
        iconColor = const Color(0xFF00695C);
        break;
      case ChannelType.emergencia:
        icon = Icons.local_hospital_rounded;
        iconBg = AppColors.emergencyLight;
        iconColor = AppColors.emergency;
        break;
      case ChannelType.geral:
        icon = Icons.forum_rounded;
        iconBg = AppColors.surfaceVariant;
        iconColor = AppColors.neutral700;
        break;
    }

    String timeStr = '';
    if (channel.ultimaMensagemHora != null) {
      timeStr = DateFormat('HH:mm').format(channel.ultimaMensagemHora!);
    }

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // Navega para a lista de conversas/chat correspondente
          context.push(AppRoutes.conversations);
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.outlineVariant),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ícone do Canal
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),

              // Informações do Canal
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            channel.nome,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.neutral900,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (timeStr.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(
                            timeStr,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.neutral500,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),

                    // Setor / Descrição
                    if (channel.setorNome != null) ...[
                      Text(
                        channel.setorNome!,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                    ],

                    // Última mensagem
                    if (channel.ultimaMensagem != null)
                      Text(
                        channel.ultimaMensagem!,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.neutral600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 6),

                    // Rodapé: Membros + Tipo
                    Row(
                      children: [
                        const Icon(
                          Icons.person_outline_rounded,
                          size: 13,
                          color: AppColors.neutral500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${channel.totalMembros} membros',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.neutral500,
                          ),
                        ),
                        const Spacer(),
                        if (channel.naoLidas > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${channel.naoLidas}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
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

  Widget _buildEmptyState(ChannelsState state) {
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
                Icons.search_off_rounded,
                size: 40,
                color: AppColors.neutral500,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Nenhum canal encontrado',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.neutral800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              state.searchQuery.isNotEmpty
                  ? 'Nenhum canal corresponde ao termo pesquisado.'
                  : 'Nenhum canal ativo nesta categoria.',
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
