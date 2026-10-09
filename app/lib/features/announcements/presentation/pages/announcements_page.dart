import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/auth/permissions_provider.dart';
import '../../../../core/widgets/delete_content_dialog.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme_provider.dart';
import '../../domain/entities/announcement_entity.dart';
import '../providers/announcements_provider.dart';

class AnnouncementsPage extends ConsumerWidget {
  const AnnouncementsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(announcementsProvider);
    final perms = ref.watch(permissionsProvider);
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
      floatingActionButton: perms.canCreateAnnouncement
          ? FloatingActionButton.extended(
              onPressed: () => _showCreateAnnouncementDialog(context, ref),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Novo Comunicado'),
              backgroundColor: tokens.primary,
              foregroundColor: Colors.white,
            )
          : null,
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
                                      if (a.canDelete)
                                        IconButton(
                                          tooltip: 'Excluir comunicado',
                                          icon: const Icon(Icons.delete_outline),
                                          onPressed: () async {
                                            final deleted = await showDeleteContentDialog(
                                              context: context,
                                              kind: 'comunicado',
                                              title: a.titulo,
                                              onDelete: () => ref.read(announcementsProvider.notifier).deleteAnnouncement(a.id),
                                            );
                                            if (deleted && context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('Comunicado excluído.')),
                                              );
                                            }
                                          },
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

  void _showCreateAnnouncementDialog(BuildContext context, WidgetRef ref) {
    final tituloCtrl = TextEditingController();
    final mensagemCtrl = TextEditingController();
    AnnouncementPriority selectedPriority = AnnouncementPriority.normal;
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final tokens = context.appTokens;
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: tokens.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.campaign_rounded, color: tokens.primary, size: 24),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Novo Comunicado',
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
                    controller: tituloCtrl,
                    decoration: InputDecoration(
                      labelText: 'Título do Comunicado *',
                      helperText: 'Mínimo de 3 caracteres',
                      hintText: 'Ex: Escala de Plantão de Fim de Semana',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: mensagemCtrl,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: 'Mensagem Oficial *',
                      helperText: 'Mínimo de 3 caracteres',
                      hintText: 'Digite as instruções completas para a equipe...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Prioridade:',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('Normal')),
                          selected: selectedPriority == AnnouncementPriority.normal,
                          onSelected: (val) {
                            if (val) setDialogState(() => selectedPriority = AnnouncementPriority.normal);
                          },
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('Alta')),
                          selected: selectedPriority == AnnouncementPriority.alta,
                          selectedColor: const Color(0xFFFFF3E0),
                          onSelected: (val) {
                            if (val) setDialogState(() => selectedPriority = AnnouncementPriority.alta);
                          },
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('Urgente')),
                          selected: selectedPriority == AnnouncementPriority.urgente,
                          selectedColor: const Color(0xFFFFEBEE),
                          onSelected: (val) {
                            if (val) setDialogState(() => selectedPriority = AnnouncementPriority.urgente);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.of(dialogCtx).pop(),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        final titulo = tituloCtrl.text.trim();
                        final mensagem = mensagemCtrl.text.trim();

                        if (titulo.length < 3) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('O título deve ter no mínimo 3 caracteres.'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                          return;
                        }
                        if (mensagem.length < 3) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('A mensagem deve ter no mínimo 3 caracteres.'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                          return;
                        }

                        setDialogState(() => isSubmitting = true);

                        // O notifier devolve null no sucesso ou uma mensagem na
                        // falha. await impede anunciar sucesso antes da resposta.
                        final error = await ref
                            .read(announcementsProvider.notifier)
                            .createAnnouncement(
                              titulo: titulo,
                              mensagem: mensagem,
                              prioridade: selectedPriority,
                            );

                        if (dialogCtx.mounted) {
                          Navigator.of(dialogCtx).pop();
                        }

                        if (context.mounted) {
                          if (error == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Comunicado oficial publicado com sucesso!'),
                                backgroundColor: AppColors.secondary,
                              ),
                            );
                            ref.read(announcementsProvider.notifier).loadAnnouncements();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Falha ao publicar comunicado: $error'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        }
                      },
                child: isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Publicar'),
              ),
            ],
          );
        },
      ),
    );
  }
}
