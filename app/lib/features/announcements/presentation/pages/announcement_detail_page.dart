import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/current_user_provider.dart';
import '../../domain/entities/announcement_entity.dart';
import '../providers/announcements_provider.dart';

class AnnouncementDetailPage extends ConsumerStatefulWidget {
  final String announcementId;

  const AnnouncementDetailPage({
    super.key,
    required this.announcementId,
  });

  @override
  ConsumerState<AnnouncementDetailPage> createState() =>
      _AnnouncementDetailPageState();
}

class _AnnouncementDetailPageState
    extends ConsumerState<AnnouncementDetailPage> {
  bool _isConfirming = false;

  Future<void> _handleConfirmRead() async {
    setState(() => _isConfirming = true);
    final success = await ref
        .read(announcementsProvider.notifier)
        .confirmRead(widget.announcementId);

    if (mounted) {
      setState(() => _isConfirming = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Leitura institucional confirmada!'),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(announcementsProvider);
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final isManager = currentUser != null && currentUser.hierarquiaNivel <= 2;

    final announcement = state.announcements
        .where((a) => a.id == widget.announcementId)
        .firstOrNull;

    if (announcement == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Comunicado')),
        body: const Center(
          child: Text('Comunicado não encontrado.'),
        ),
      );
    }

    Color priorityColor;
    Color priorityBg;
    String priorityText;
    IconData priorityIcon;

    switch (announcement.prioridade) {
      case AnnouncementPriority.urgente:
        priorityColor = AppColors.emergency;
        priorityBg = AppColors.emergencyLight;
        priorityText = 'PRIORIDADE URGENTE';
        priorityIcon = Icons.error_outline_rounded;
        break;
      case AnnouncementPriority.alta:
        priorityColor = AppColors.warning;
        priorityBg = AppColors.warningLight;
        priorityText = 'PRIORIDADE ALTA';
        priorityIcon = Icons.warning_amber_rounded;
        break;
      case AnnouncementPriority.normal:
        priorityColor = AppColors.primary;
        priorityBg = AppColors.primaryContainer;
        priorityText = 'COMUNICADO INSTITUCIONAL';
        priorityIcon = Icons.info_outline_rounded;
        break;
    }

    final dateStr = DateFormat('dd/MM/yyyy às HH:mm')
        .format(announcement.publicadoEm);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Detalhes do Comunicado'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ─── Card Principal ──────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge de Prioridade
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: priorityBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(priorityIcon, size: 14, color: priorityColor),
                        const SizedBox(width: 6),
                        Text(
                          priorityText,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: priorityColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Título do Comunicado
                  Text(
                    announcement.titulo,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.neutral900,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Autor e Data
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.primaryLight.withValues(alpha: 0.15),
                        child: Text(
                          announcement.criadorNome.isNotEmpty
                              ? announcement.criadorNome[0]
                              : 'A',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              announcement.criadorNome,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.neutral900,
                              ),
                            ),
                            Text(
                              '${announcement.criadorCargo} • $dateStr',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.neutral600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 18),
                    child: Divider(height: 1),
                  ),

                  // Conteúdo Completo
                  SelectableText(
                    announcement.mensagem,
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.neutral800,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ─── Métricas de Leitura (Visível para Gestores / Coordenação+) ──
            if (isManager) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.outlineVariant),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.insights_rounded,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Controle de Leitura (Coordenação/Direção)',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.neutral900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${announcement.totalLeituras} de ${announcement.totalUsuarios} servidores leram',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.neutral700,
                          ),
                        ),
                        Text(
                          '${announcement.percentualLeitura}%',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: announcement.totalUsuarios > 0
                            ? announcement.totalLeituras /
                                announcement.totalUsuarios
                            : 0,
                        minHeight: 8,
                        backgroundColor: AppColors.surfaceVariant,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ─── Status de Confirmação de Leitura ──────────────────────────
            if (announcement.lido) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.successLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.success,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Leitura Confirmada',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.success,
                            ),
                          ),
                          Text(
                            announcement.lidoEm != null
                                ? 'Confirmado em ${DateFormat('dd/MM/yyyy às HH:mm').format(announcement.lidoEm!)}'
                                : 'Sua ciência institucional foi registrada.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.success.withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _isConfirming ? null : _handleConfirmRead,
                  icon: _isConfirming
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.mark_email_read_rounded, size: 20),
                  label: Text(
                    _isConfirming
                        ? 'Confirmando...'
                        : 'CONFIRMAR LEITURA DO COMUNICADO',
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
