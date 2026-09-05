import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/message_entity.dart';
import '../providers/chat_provider.dart';
import 'audio_recorder_widget.dart';

/// Barra de input do chat — comportamento idêntico ao WhatsApp:
/// - Ícone de anexo à esquerda
/// - Campo de texto expansível
/// - Botão que alterna entre enviar (texto) e gravar áudio (vazio)
/// - Gravação por pressão longa no microfone
/// - Banner de reply e edição
class ChatInputBar extends ConsumerStatefulWidget {
  final String conversationId;
  final MessageEntity? replyingTo;
  final MessageEntity? editingMessage;
  final VoidCallback onCancelReply;
  final VoidCallback onCancelEdit;
  final VoidCallback onSent;

  const ChatInputBar({
    super.key,
    required this.conversationId,
    this.replyingTo,
    this.editingMessage,
    required this.onCancelReply,
    required this.onCancelEdit,
    required this.onSent,
  });

  @override
  ConsumerState<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends ConsumerState<ChatInputBar>
    with SingleTickerProviderStateMixin {
  final _textController = TextEditingController();
  final _focusNode = FocusNode();
  bool _hasText = false;
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    _textController.addListener(() {
      final has = _textController.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });

    // Preencher texto ao editar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.editingMessage != null) {
        _textController.text = widget.editingMessage!.texto;
        _textController.selection = TextSelection.collapsed(
          offset: _textController.text.length,
        );
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void didUpdateWidget(ChatInputBar old) {
    super.didUpdateWidget(old);
    // Ao entrar em modo edição, preenche o campo
    if (widget.editingMessage != null &&
        widget.editingMessage != old.editingMessage) {
      _textController.text = widget.editingMessage!.texto;
      _textController.selection = TextSelection.collapsed(
        offset: _textController.text.length,
      );
      _focusNode.requestFocus();
    }
    // Ao cancelar edição, limpa o campo
    if (widget.editingMessage == null && old.editingMessage != null) {
      _textController.clear();
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _send() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final notifier = ref.read(messagesProvider(widget.conversationId).notifier);

    if (widget.editingMessage != null) {
      notifier.editMessage(widget.editingMessage!.id, text);
    } else {
      notifier.sendTextMessage(text);
    }

    _textController.clear();
    HapticFeedback.lightImpact();
    widget.onSent();
  }

  void _onAudioRecorded(String path, int durationSeconds) {
    ref
        .read(messagesProvider(widget.conversationId).notifier)
        .sendAudioMessage(path, durationSeconds);
    setState(() => _isRecording = false);
    HapticFeedback.mediumImpact();
    widget.onSent();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkSurface : Colors.white;
    final inputFill = isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant;

    return Container(
      color: bgColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ─── Banner de reply ───────────────────────────────────────────
          if (widget.replyingTo != null)
            _ReplyBanner(
              message: widget.replyingTo!,
              onCancel: widget.onCancelReply,
              isDark: isDark,
            ),

          // ─── Banner de edição ──────────────────────────────────────────
          if (widget.editingMessage != null)
            _EditBanner(
              message: widget.editingMessage!,
              onCancel: widget.onCancelEdit,
              isDark: isDark,
            ),

          // ─── Gravação de áudio ─────────────────────────────────────────
          if (_isRecording)
            AudioRecorderWidget(
              onRecorded: _onAudioRecorded,
              onCancel: () => setState(() => _isRecording = false),
            )
          else
            // ─── Input principal ─────────────────────────────────────────
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // ─── Campo de texto + emoji + anexo ─────────────────
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: inputFill,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // Emoji
                            IconButton(
                              icon: const Icon(
                                Icons.emoji_emotions_outlined,
                                color: AppColors.neutral500,
                              ),
                              onPressed: () {
                                // TODO: emoji picker
                              },
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4),
                              constraints: const BoxConstraints(),
                              iconSize: 22,
                            ),

                            // Campo de texto
                            Expanded(
                              child: TextField(
                                controller: _textController,
                                focusNode: _focusNode,
                                maxLines: 6,
                                minLines: 1,
                                keyboardType: TextInputType.multiline,
                                textInputAction: TextInputAction.newline,
                                textCapitalization:
                                    TextCapitalization.sentences,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: isDark
                                      ? AppColors.onDarkSurface
                                      : AppColors.onSurface,
                                ),
                                decoration: InputDecoration(
                                  hintText: widget.editingMessage != null
                                      ? 'Editar mensagem...'
                                      : 'Mensagem',
                                  hintStyle: const TextStyle(
                                    color: AppColors.neutral500,
                                    fontSize: 15,
                                  ),
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  contentPadding:
                                      const EdgeInsets.symmetric(
                                          vertical: 10),
                                  filled: false,
                                ),
                              ),
                            ),

                            // Anexo (clipes)
                            if (!_hasText)
                              IconButton(
                                icon: const Icon(
                                  Icons.attach_file,
                                  color: AppColors.neutral500,
                                ),
                                onPressed: () {
                                  // TODO: seletor de arquivo/imagem
                                },
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4),
                                constraints: const BoxConstraints(),
                                iconSize: 22,
                              ),

                            const SizedBox(width: 4),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // ─── Botão enviar / microfone ────────────────────────
                    _SendButton(
                      hasText: _hasText,
                      isEditing: widget.editingMessage != null,
                      onSend: _send,
                      onStartRecord: () {
                        setState(() => _isRecording = true);
                        HapticFeedback.mediumImpact();
                      },
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Botão enviar / microfone ─────────────────────────────────────────────────
class _SendButton extends StatelessWidget {
  final bool hasText;
  final bool isEditing;
  final VoidCallback onSend;
  final VoidCallback onStartRecord;

  const _SendButton({
    required this.hasText,
    required this.isEditing,
    required this.onSend,
    required this.onStartRecord,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: hasText ? onSend : null,
      onLongPress: hasText ? null : onStartRecord,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 48,
        height: 48,
        decoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, animation) => ScaleTransition(
            scale: animation,
            child: child,
          ),
          child: hasText
              ? Icon(
                  isEditing ? Icons.check : Icons.send_rounded,
                  key: const ValueKey('send'),
                  color: Colors.white,
                  size: 22,
                )
              : const Icon(
                  Icons.mic_rounded,
                  key: ValueKey('mic'),
                  color: Colors.white,
                  size: 24,
                ),
        ),
      ),
    );
  }
}

// ─── Banner de reply ──────────────────────────────────────────────────────────
class _ReplyBanner extends StatelessWidget {
  final MessageEntity message;
  final VoidCallback onCancel;
  final bool isDark;

  const _ReplyBanner({
    required this.message,
    required this.onCancel,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant;

    return Container(
      color: bg,
      padding: const EdgeInsets.only(left: 16, right: 8, top: 8, bottom: 8),
      child: Row(
        children: [
          // Barra lateral colorida
          Container(
            width: 3,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.remetente.nome.split(' ').first,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message.excluido
                      ? 'Mensagem apagada'
                      : message.tipo == MessageType.audio
                          ? '🎤 Áudio'
                          : message.texto,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? AppColors.onDarkSurfaceVariant
                        : AppColors.neutral600,
                    fontStyle: message.excluido
                        ? FontStyle.italic
                        : FontStyle.normal,
                  ),
                ),
              ],
            ),
          ),

          // Botão cancelar
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: onCancel,
            color: AppColors.neutral500,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

// ─── Banner de edição ─────────────────────────────────────────────────────────
class _EditBanner extends StatelessWidget {
  final MessageEntity message;
  final VoidCallback onCancel;
  final bool isDark;

  const _EditBanner({
    required this.message,
    required this.onCancel,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant;

    return Container(
      color: bg,
      padding: const EdgeInsets.only(left: 16, right: 8, top: 8, bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.edit, color: AppColors.primary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Editar mensagem',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message.texto,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? AppColors.onDarkSurfaceVariant
                        : AppColors.neutral600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: onCancel,
            color: AppColors.neutral500,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
