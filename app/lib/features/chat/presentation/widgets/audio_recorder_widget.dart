import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import '../../../../core/theme/app_colors.dart';

/// Widget de gravação de áudio — estilo WhatsApp.
/// Aparece quando o usuário pressiona e segura o microfone.
/// Mostra: botão cancelar, timer, amplitude animada, botão enviar.
class AudioRecorderWidget extends StatefulWidget {
  final void Function(String path, int durationSeconds) onRecorded;
  final VoidCallback onCancel;

  const AudioRecorderWidget({
    super.key,
    required this.onRecorded,
    required this.onCancel,
  });

  @override
  State<AudioRecorderWidget> createState() => _AudioRecorderWidgetState();
}

class _AudioRecorderWidgetState extends State<AudioRecorderWidget>
    with SingleTickerProviderStateMixin {
  final _recorder = AudioRecorder();
  Timer? _timer;
  int _seconds = 0;
  bool _isRecording = false;
  String? _filePath;
  double _amplitude = 0.0;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _startRecording();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        widget.onCancel();
        return;
      }

      final dir = await getTemporaryDirectory();
      _filePath =
          '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: _filePath!,
      );

      setState(() => _isRecording = true);

      // Timer de duração
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _seconds++);
      });

      // Monitorar amplitude para animação
      Timer.periodic(const Duration(milliseconds: 100), (t) async {
        if (!_isRecording) {
          t.cancel();
          return;
        }
        final amp = await _recorder.getAmplitude();
        if (mounted) {
          setState(() {
            // Normalizar amplitude (-160 a 0 dBFS) para 0-1
            _amplitude = ((amp.current + 60) / 60).clamp(0.0, 1.0);
          });
        }
      });
    } catch (_) {
      widget.onCancel();
    }
  }

  Future<void> _stopAndSend() async {
    if (!_isRecording) return;
    _timer?.cancel();
    setState(() => _isRecording = false);

    await _recorder.stop();

    if (_filePath != null && _seconds > 0) {
      HapticFeedback.mediumImpact();
      widget.onRecorded(_filePath!, _seconds);
    } else {
      widget.onCancel();
    }
  }

  Future<void> _cancel() async {
    _timer?.cancel();
    setState(() => _isRecording = false);
    await _recorder.stop();
    widget.onCancel();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurface : Colors.white;

    return Container(
      color: bg,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // ─── Cancelar ───────────────────────────────────────────────
            GestureDetector(
              onTap: _cancel,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(
                  Icons.delete_outline,
                  color: AppColors.error,
                  size: 26,
                ),
              ),
            ),
            const SizedBox(width: 8),

            // ─── Microfone animado ───────────────────────────────────────
            AnimatedBuilder(
              animation: _pulseController,
              builder: (_, __) {
                final scale = 1.0 + (_amplitude * 0.4 * _pulseController.value);
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.error.withValues(
                        alpha: 0.15 + _amplitude * 0.2,
                      ),
                    ),
                    child: const Icon(
                      Icons.mic,
                      color: AppColors.error,
                      size: 20,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 12),

            // ─── Timer ───────────────────────────────────────────────────
            Expanded(
              child: Row(
                children: [
                  // Ponto piscante vermelho
                  _BlinkingDot(),
                  const SizedBox(width: 8),
                  Text(
                    _formatDuration(_seconds),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.onDarkSurface
                          : AppColors.onSurface,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Deslize para cancelar (hint)
                  const Text(
                    '< deslize para cancelar',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.neutral500,
                    ),
                  ),
                ],
              ),
            ),

            // ─── Enviar ──────────────────────────────────────────────────
            GestureDetector(
              onTap: _stopAndSend,
              child: Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

/// Ponto vermelho piscante durante gravação
class _BlinkingDot extends StatefulWidget {
  @override
  State<_BlinkingDot> createState() => _BlinkingDotState();
}

class _BlinkingDotState extends State<_BlinkingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _ctrl,
      child: Container(
        width: 10,
        height: 10,
        decoration: const BoxDecoration(
          color: AppColors.error,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
