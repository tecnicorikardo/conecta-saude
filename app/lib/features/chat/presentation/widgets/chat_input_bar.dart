import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart' show XFile;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/message_entity.dart';
import '../providers/chat_provider.dart';

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

class _ChatInputBarState extends ConsumerState<ChatInputBar> {
  final _textCtrl = TextEditingController();
  final _focusNode = FocusNode();
  bool _isComposing = false;

  late final AudioRecorder _audioRecorder;
  bool _isRecording = false;
  int _recordDuration = 0;
  Timer? _recordTimer;

  @override
  void initState() {
    super.initState();
    _audioRecorder = AudioRecorder();
    if (widget.editingMessage != null) {
      _textCtrl.text = widget.editingMessage!.texto;
      _isComposing = _textCtrl.text.trim().isNotEmpty;
    }
  }

  @override
  void didUpdateWidget(covariant ChatInputBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.editingMessage != null && widget.editingMessage != oldWidget.editingMessage) {
      _textCtrl.text = widget.editingMessage!.texto;
      _isComposing = true;
    }
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    _audioRecorder.dispose();
    _textCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;

    _textCtrl.clear();
    setState(() => _isComposing = false);

    // Notifica imediatamente para rolar e limpar estado de resposta/edição sem delay
    widget.onSent();

    if (widget.editingMessage != null) {
      await ref
          .read(messagesProvider(widget.conversationId).notifier)
          .editMessage(widget.editingMessage!.id, text);
    } else {
      ref
          .read(messagesProvider(widget.conversationId).notifier)
          .sendTextMessage(text);
    }
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        String path = '';
        if (!kIsWeb) {
          final tempDir = await getTemporaryDirectory();
          path = '${tempDir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
        }

        const config = RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 64000,
          sampleRate: 44100,
        );

        await _audioRecorder.start(config, path: path);

        setState(() {
          _isRecording = true;
          _recordDuration = 0;
        });

        _recordTimer?.cancel();
        _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (mounted) {
            setState(() {
              _recordDuration++;
            });
          }
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Permissão de microfone necessária para gravar áudio.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Erro ao iniciar gravação de áudio: $e');
    }
  }

  Future<void> _cancelRecording() async {
    _recordTimer?.cancel();
    _recordTimer = null;
    try {
      await _audioRecorder.stop();
    } catch (_) {}
    if (mounted) {
      setState(() {
        _isRecording = false;
        _recordDuration = 0;
      });
    }
  }

  Future<void> _stopAndSendRecording() async {
    _recordTimer?.cancel();
    _recordTimer = null;
    final duration = _recordDuration > 0 ? _recordDuration : 1;

    try {
      final path = await _audioRecorder.stop();
      if (mounted) {
        setState(() {
          _isRecording = false;
          _recordDuration = 0;
        });
      }

      if (path != null && path.isNotEmpty) {
        final xfile = XFile(path);
        final bytes = await xfile.readAsBytes();
        if (bytes.isNotEmpty) {
          final b64 = base64Encode(bytes);
          const mime = kIsWeb ? 'audio/webm' : 'audio/m4a';
          final payload = '[audio:$duration]data:$mime;base64,$b64';

          widget.onSent();
          try {
            await ref
                .read(messagesProvider(widget.conversationId).notifier)
                .sendTextMessage(payload);
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Erro ao enviar áudio: $e'),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Erro ao salvar e enviar áudio: $e');
      if (mounted) {
        setState(() {
          _isRecording = false;
          _recordDuration = 0;
        });
      }
    }
  }

  String _formatTimer(int seconds) {
    final m = (seconds ~/ 60).toString();
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.border,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        bottom: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Banner de resposta / edição
            if (widget.replyingTo != null)
              _buildContextBanner(
                icon: Icons.reply,
                title: 'Respondendo a ',
                subtitle: widget.replyingTo!.texto,
                onCancel: widget.onCancelReply,
              ),
            if (widget.editingMessage != null)
              _buildContextBanner(
                icon: Icons.edit_outlined,
                title: 'Editando mensagem',
                subtitle: widget.editingMessage!.texto,
                onCancel: widget.onCancelEdit,
              ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: _isRecording ? _buildRecordingBar(isDark) : _buildInputBar(isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkBackground : AppColors.neutral100,
              borderRadius: BorderRadius.circular(24),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Focus(
              onKeyEvent: (node, event) {
                if (event is KeyDownEvent &&
                    event.logicalKey == LogicalKeyboardKey.enter &&
                    !HardwareKeyboard.instance.isShiftPressed) {
                  _send();
                  return KeyEventResult.handled;
                }
                return KeyEventResult.ignored;
              },
              child: TextField(
                controller: _textCtrl,
                focusNode: _focusNode,
                maxLines: 4,
                minLines: 1,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Mensagem institucional...',
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
                onChanged: (text) {
                  setState(() => _isComposing = text.trim().isNotEmpty);
                },
                onSubmitted: (_) => _send(),
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        if (_isComposing)
          IconButton(
            onPressed: _send,
            icon: const Icon(Icons.send_rounded),
            color: AppColors.primary,
            tooltip: 'Enviar mensagem',
          )
        else
          Container(
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: _startRecording,
              icon: const Icon(Icons.mic_rounded),
              color: AppColors.primary,
              tooltip: 'Gravar áudio (WhatsApp)',
            ),
          ),
      ],
    );
  }

  Widget _buildRecordingBar(bool isDark) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
          tooltip: 'Cancelar gravação',
          onPressed: _cancelRecording,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkBackground : AppColors.neutral100,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  _formatTimer(_recordDuration),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Gravando áudio...',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 6),
        Container(
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.send_rounded, color: Colors.white),
            tooltip: 'Enviar áudio gravado',
            onPressed: _stopAndSendRecording,
          ),
        ),
      ],
    );
  }

  Widget _buildContextBanner({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onCancel,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.primary.withValues(alpha: 0.08),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: onCancel,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
