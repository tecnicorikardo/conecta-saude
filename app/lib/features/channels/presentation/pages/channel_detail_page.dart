import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme_provider.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/services/language_filter_service.dart';
import '../../../chat/presentation/widgets/language_warning_dialog.dart';
import '../../../../core/auth/permissions_provider.dart';
import '../../../../core/widgets/delete_content_dialog.dart';
import '../../domain/entities/channel_entity.dart';
import '../providers/channels_provider.dart';

class ChannelDetailPage extends ConsumerStatefulWidget {
  final String channelId;
  final ChannelEntity? channel;

  const ChannelDetailPage({
    super.key,
    required this.channelId,
    this.channel,
  });

  @override
  ConsumerState<ChannelDetailPage> createState() => _ChannelDetailPageState();
}

class _ChannelDetailPageState extends ConsumerState<ChannelDetailPage> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _handleSend() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    // ─── FILTRO PREVENTIVO DE LINGUAGEM NO CANAL OFICIAL ────────────────────
    final isEmergencia = widget.channel?.isEmergencia ?? false;
    final eval = LanguageFilterService.instance.evaluateMessage(
      text: text,
      isEmergencyChannel: isEmergencia,
    );

    if (!eval.isClean) {
      final action = await LanguageWarningDialog.show(
        context,
        result: eval,
        originalText: text,
      );

      switch (action) {
        case WarningDialogAction.review:
          _focusNode.requestFocus();
          return;
        case WarningDialogAction.cancel:
          return;
        case WarningDialogAction.reportIncident:
          if (mounted) {
            context.push(AppRoutes.reports);
          }
          return;
        case WarningDialogAction.sendAnyway:
          break;
      }
    }

    _textController.clear();
    final ok = await ref
        .read(channelMessagesProvider(widget.channelId).notifier)
        .postMessage(text);

    if (ok) {
      Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao publicar mensagem no canal.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showReadersModal(BuildContext context, ChannelMessageEntity message) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReadersBottomSheet(
        channelId: widget.channelId,
        message: message,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(channelMessagesProvider(widget.channelId));
    final perms = ref.watch(permissionsProvider);
    final canPublish =
        perms.canCreateChannel; // Direção, Coordenação ou Supervisão
    final tokens = context.appTokens;

    final channelName = widget.channel?.nome ?? 'Canal Oficial';
    final sectorName = widget.channel?.setorNome ??
        (widget.channel?.isEmergencia == true
            ? 'Emergência Geral'
            : 'Institucional');

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: (widget.channel?.isEmergencia ?? false)
                    ? AppColors.emergencyLight
                    : AppColors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                (widget.channel?.isEmergencia ?? false)
                    ? Icons.local_hospital_rounded
                    : Icons.campaign_rounded,
                color: (widget.channel?.isEmergencia ?? false)
                    ? AppColors.emergency
                    : AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    channelName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    sectorName,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (widget.channel?.canDelete == true)
            IconButton(
              tooltip: 'Excluir canal',
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                final deleted = await showDeleteContentDialog(
                  context: context,
                  kind: 'canal',
                  title: channelName,
                  onDelete: () => ref
                      .read(channelsProvider.notifier)
                      .deleteChannel(widget.channelId),
                );
                if (deleted && context.mounted) context.go('/channels');
              },
            ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Atualizar mensagens',
            onPressed: () => ref
                .read(channelMessagesProvider(widget.channelId).notifier)
                .loadMessages(),
          ),
        ],
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: Column(
            children: [
              // ─── Lista de Mensagens ──────────────────────────────────────────
              Expanded(
                child: Container(
                  decoration: tokens.isLgbtq
                      ? const BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage(
                                'assets/images/background_lgbtq.jpg'),
                            fit: BoxFit.cover,
                            opacity: 0.20,
                          ),
                        )
                      : null,
                  child: state.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : state.messages.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                              controller: _scrollController,
                              keyboardDismissBehavior:
                                  ScrollViewKeyboardDismissBehavior.onDrag,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              itemCount: state.messages.length,
                              itemBuilder: (context, index) {
                                final msg = state.messages[index];
                                return _buildMessageCard(
                                  context,
                                  msg,
                                  canPublish,
                                );
                              },
                            ),
                ),
              ),

              // ─── Rodapé: Input para Liderança OU Banner para Funcionários ──
              if (canPublish)
                _buildPublisherInputBar(state.isSending)
              else
                _buildStaffReadOnlyBanner(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.campaign_outlined,
                size: 40,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhum comunicado no canal',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Avisos e comunicados publicados pela Coordenação e Direção aparecerão aqui.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageCard(
    BuildContext context,
    ChannelMessageEntity msg,
    bool isLeadership,
  ) {
    final timeStr = DateFormat('dd/MM/yyyy • HH:mm').format(msg.criadoEm);

    // Cor e rótulo do crachá do autor
    String roleLabel = msg.remetenteCargo;
    Color roleBg = AppColors.primaryContainer;
    Color roleColor = AppColors.primary;

    if (msg.remetenteHierarquia == 1) {
      roleBg = const Color(0xFFEDE7F6);
      roleColor = const Color(0xFF5E35B1);
    } else if (msg.remetenteHierarquia == 2) {
      roleBg = const Color(0xFFE0F2F1);
      roleColor = const Color(0xFF00796B);
    }

    final tokens = context.appTokens;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: tokens.cardDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Cabeçalho da Postagem (Autor + Cargo + Hora)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: roleBg,
                  backgroundImage: msg.remetenteFotoUrl != null
                      ? NetworkImage(msg.remetenteFotoUrl!)
                      : null,
                  child: msg.remetenteFotoUrl == null
                      ? Text(
                          msg.remetenteNome.isNotEmpty
                              ? msg.remetenteNome[0].toUpperCase()
                              : 'U',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: roleColor,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              msg.remetenteNome,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: roleBg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              roleLabel,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: roleColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        timeStr,
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Texto do Comunicado
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: SelectableText(
              msg.texto,
              style: TextStyle(
                fontSize: 14,
                height: 1.45,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          const Divider(height: 1),

          // Rodapé: Estatísticas de Visualização / Status de Leitura
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withValues(alpha: 0.5),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                if (isLeadership) ...[
                  // Botão para abrir modal "Quem visualizou"
                  InkWell(
                    onTap: () => _showReadersModal(context, msg),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.visibility_rounded,
                            size: 15,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${msg.readsCount} visualizaç${msg.readsCount == 1 ? 'ão' : 'ões'}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.info_outline_rounded,
                            size: 13,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  // Indicador de conformidade para o funcionário
                  Icon(
                    Icons.check_circle_rounded,
                    size: 14,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Leitura registrada',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ],
                const Spacer(),
                Icon(
                  Icons.shield_outlined,
                  size: 13,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  'Oficial',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPublisherInputBar(bool isSending) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -2),
            blurRadius: 8,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        bottom: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  Icons.campaign_rounded,
                  size: 14,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 5),
                Text(
                  'Publicando como Liderança / Oficial',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Focus(
                    onKeyEvent: (node, event) {
                      if (event is KeyDownEvent &&
                          event.logicalKey == LogicalKeyboardKey.enter &&
                          !HardwareKeyboard.instance.isShiftPressed) {
                        if (!isSending) _handleSend();
                        return KeyEventResult.handled;
                      }
                      return KeyEventResult.ignored;
                    },
                    child: TextField(
                      controller: _textController,
                      focusNode: _focusNode,
                      maxLines: 4,
                      minLines: 1,
                      keyboardType: TextInputType.multiline,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface),
                      decoration: InputDecoration(
                        hintText: 'Escreva um aviso ou comunicado...',
                        hintStyle: TextStyle(
                            fontSize: 13.5,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant),
                        filled: true,
                        fillColor: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 44,
                  width: 44,
                  child: FilledButton(
                    onPressed: isSending ? null : _handleSend,
                    style: FilledButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isSending
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          )
                        : const Icon(Icons.send_rounded, size: 20),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStaffReadOnlyBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer.withValues(alpha: 0.5),
        border: Border(
          top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lock_outline_rounded,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Apenas Coordenação e Direção podem publicar neste canal. Suas visualizações são registradas para conformidade institucional.',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Modal BottomSheet: Quem Visualizou o Comunicado ──────────────────────────
class _ReadersBottomSheet extends ConsumerStatefulWidget {
  final String channelId;
  final ChannelMessageEntity message;

  const _ReadersBottomSheet({
    required this.channelId,
    required this.message,
  });

  @override
  ConsumerState<_ReadersBottomSheet> createState() =>
      _ReadersBottomSheetState();
}

class _ReadersBottomSheetState extends ConsumerState<_ReadersBottomSheet> {
  late Future<ChannelMessageStatsEntity> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = ref
        .read(channelMessagesProvider(widget.channelId).notifier)
        .fetchMessageReaders(widget.message.id);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Barra de arrasto
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.neutral300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),

              // Título
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Icon(
                      Icons.visibility_rounded,
                      color: Theme.of(context).colorScheme.primary,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Quem visualizou este aviso',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Conteúdo com FutureBuilder
              Expanded(
                child: FutureBuilder<ChannelMessageStatsEntity>(
                  future: _statsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                color: AppColors.error,
                                size: 36,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Erro ao carregar visualizações:\n${snapshot.error}',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final stats = snapshot.data!;

                    return ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                      children: [
                        // Card de Progresso e Estatísticas
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer
                                .withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Theme.of(context)
                                    .colorScheme
                                    .outlineVariant),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${stats.totalReads} de ${stats.totalMembers} membros leram',
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                  Text(
                                    '${stats.percentual}%',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: stats.totalMembers > 0
                                      ? stats.totalReads / stats.totalMembers
                                      : 1.0,
                                  minHeight: 8,
                                  backgroundColor: AppColors.surfaceVariant,
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                    AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),

                        Text(
                          'COLABORADORES QUE LERAM',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),

                        if (stats.readers.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: Text(
                                'Nenhum membro visualizou ainda.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                              ),
                            ),
                          )
                        else
                          ...stats.readers.map((reader) {
                            final readTimeStr = DateFormat(
                              'dd/MM às HH:mm:ss',
                            ).format(reader.lidoEm);

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .outlineVariant,
                                ),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: AppColors.primaryContainer,
                                    backgroundImage: reader.fotoUrl != null
                                        ? NetworkImage(reader.fotoUrl!)
                                        : null,
                                    child: reader.fotoUrl == null
                                        ? Text(
                                            reader.nome.isNotEmpty
                                                ? reader.nome[0].toUpperCase()
                                                : 'U',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                              fontSize: 13,
                                            ),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          reader.nome,
                                          style: TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w700,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${reader.cargo} • ${reader.setorNome}',
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.done_all_rounded,
                                            size: 13,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .secondary,
                                          ),
                                          const SizedBox(width: 3),
                                          Text(
                                            'Lido',
                                            style: TextStyle(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w700,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .secondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        readTimeStr,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
