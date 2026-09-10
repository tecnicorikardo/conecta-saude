import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/repositories/channels_repository.dart';
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
        backgroundColor: AppColors.primaryDeep,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Atualizar',
            onPressed: () => ref.read(channelsProvider.notifier).loadChannels(),
          ),
        ],
      ),
      floatingActionButton: ((state.currentUser?.hierarquiaNivel ?? 4) <= 2)
          ? FloatingActionButton.extended(
              onPressed: () => _showCreateChannelDialog(context, ref, state),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Novo Canal'),
              backgroundColor: AppColors.primary,
            )
          : null,
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

                  // Abas dos Centros Oficiais respeitando o centro do funcionário
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        if (state.isDirecao || state.userCentroTag == 'CCD' || state.userCentroTag == 'TODOS') ...[
                          _buildCategoryChip(
                            label: 'CCD (CCDTI)',
                            sublabel: 'Imagem e Diagnóstico',
                            isSelected: state.selectedTab == ChannelTab.ccd,
                            onTap: () => ref
                                .read(channelsProvider.notifier)
                                .setTab(ChannelTab.ccd),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (state.isDirecao || state.userCentroTag == 'CCO' || state.userCentroTag == 'TODOS') ...[
                          _buildCategoryChip(
                            label: 'CCO',
                            sublabel: 'Centro do Olho',
                            isSelected: state.selectedTab == ChannelTab.cco,
                            onTap: () => ref
                                .read(channelsProvider.notifier)
                                .setTab(ChannelTab.cco),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (state.isDirecao || state.userCentroTag == 'CCE' || state.userCentroTag == 'TODOS') ...[
                          _buildCategoryChip(
                            label: 'CCE',
                            sublabel: 'Especialidades',
                            isSelected: state.selectedTab == ChannelTab.cce,
                            onTap: () => ref
                                .read(channelsProvider.notifier)
                                .setTab(ChannelTab.cce),
                          ),
                          const SizedBox(width: 8),
                        ],
                        _buildCategoryChip(
                          label: '🚨 Emergência',
                          isSelected: state.selectedTab == ChannelTab.emergencia,
                          isUrgent: true,
                          onTap: () => ref
                              .read(channelsProvider.notifier)
                              .setTab(ChannelTab.emergencia),
                        ),
                        if (state.isDirecao) ...[
                          const SizedBox(width: 8),
                          _buildCategoryChip(
                            label: 'Todos',
                            isSelected: state.selectedTab == ChannelTab.todos,
                            onTap: () => ref
                                .read(channelsProvider.notifier)
                                .setTab(ChannelTab.todos),
                          ),
                        ],
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
    final activeBg = isUrgent ? const Color(0xFFFFEBEE) : AppColors.softBlue;
    final activeBorder = isUrgent ? AppColors.emergency : AppColors.primary;
    final activeText = isUrgent ? AppColors.emergency : AppColors.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? activeBorder : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? activeText : AppColors.navy,
              ),
            ),
            if (sublabel != null)
              Text(
                sublabel,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w400,
                  color: isSelected ? activeText : AppColors.textSecondary,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.emergency, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push(
            AppRoutes.channelDetail.replaceAll(':id', channel.id),
            extra: channel,
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 4, color: AppColors.emergency),
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
                          child: const Icon(Icons.warning_amber_rounded,
                              color: AppColors.emergency, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    'CANAL DE EMERGÊNCIA',
                                    style: TextStyle(
                                      color: AppColors.emergency,
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const Spacer(),
                                  if (channel.naoLidas > 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.emergency,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '${channel.naoLidas} novo(s)',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                channel.descricao ?? 'Canal prioritário hospitalar',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.chevron_right, color: AppColors.emergency, size: 20),
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

  Widget _buildChannelCard(BuildContext context, ChannelEntity channel) {
    final isEmergencia = channel.tipo == ChannelType.emergencia;
    final icon = isEmergencia
        ? Icons.local_hospital_outlined
        : (channel.tipo == ChannelType.institucional
            ? Icons.campaign_outlined
            : Icons.groups_outlined);
    final iconBg = isEmergencia ? const Color(0xFFFFEBEE) : AppColors.softBlue;
    final iconColor = isEmergencia ? AppColors.emergency : AppColors.primary;
    final stripeColor = isEmergencia ? AppColors.emergency : AppColors.primary;

    String timeStr = '';
    if (channel.ultimaMensagemHora != null) {
      timeStr = DateFormat('HH:mm').format(channel.ultimaMensagemHora!);
    }

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
          onTap: () {
            context.push(
              AppRoutes.channelDetail.replaceAll(':id', channel.id),
              extra: channel,
            );
          },
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 3.5, color: stripeColor),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: iconBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(icon, color: iconColor, size: 20),
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
                                      channel.nome,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.navy,
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
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              if (channel.setorNome != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  channel.setorNome!,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                              if (channel.ultimaMensagem != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  channel.ultimaMensagem!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.person_outline_rounded,
                                    size: 13,
                                    color: AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${channel.totalMembros} membros',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const Spacer(),
                                  if (channel.naoLidas > 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isEmergencia ? AppColors.emergency : AppColors.primary,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '${channel.naoLidas}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
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
              ],
            ),
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
              decoration: const BoxDecoration(
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

  void _showCreateChannelDialog(
    BuildContext context,
    WidgetRef ref,
    ChannelsState state,
  ) {
    final nomeController = TextEditingController();
    final descController = TextEditingController();
    String tipo = state.isDirecao ? 'institucional' : 'setor';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.campaign_rounded, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                'Criar Novo Canal',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: nomeController,
                  decoration: const InputDecoration(
                    labelText: 'Nome do Canal *',
                    hintText: 'Ex: Equipe de Enfermagem CCO',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Descrição (opcional)',
                    hintText: 'Finalidade das transmissões deste canal',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: tipo,
                  decoration: const InputDecoration(labelText: 'Tipo de Canal'),
                  items: [
                    const DropdownMenuItem(value: 'setor', child: Text('Canal de Setor')),
                    if (state.isDirecao) ...[
                      const DropdownMenuItem(value: 'institucional', child: Text('Institucional Geral')),
                      const DropdownMenuItem(value: 'emergencia', child: Text('Emergência')),
                      const DropdownMenuItem(value: 'geral', child: Text('Geral')),
                    ],
                  ],
                  onChanged: (val) {
                    if (val != null) setStateDialog(() => tipo = val);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () async {
                final nome = nomeController.text.trim();
                if (nome.isEmpty) return;
                Navigator.of(ctx).pop();
                try {
                  await ref.read(channelsRepositoryProvider).createChannel(
                        nome: nome,
                        descricao: descController.text.trim(),
                        tipo: tipo,
                        setorId: state.currentUser?.setorId,
                      );
                  ref.read(channelsProvider.notifier).loadChannels();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Canal criado com sucesso!'),
                        backgroundColor: AppColors.secondary,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erro ao criar canal: $e'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }
              },
              child: const Text('Criar Canal'),
            ),
          ],
        ),
      ),
    );
  }
}
