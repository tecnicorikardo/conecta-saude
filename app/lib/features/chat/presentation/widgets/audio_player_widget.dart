import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../../core/theme/app_colors.dart';

/// Player de áudio inline — estilo WhatsApp.
/// Exibe: avatar animado, botão play/pause, waveform e duração.
class AudioPlayerWidget extends StatefulWidget {
  final String? audioPath;
  final int durationSeconds;
  final bool isOwn;

  const AudioPlayerWidget({
    super.key,
    this.audioPath,
    required this.durationSeconds,
    required this.isOwn,
  });

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget>
    with SingleTickerProviderStateMixin {
  final _player = AudioPlayer();
  bool _isPlaying = false;
  bool _isLoading = false;
  double _progress = 0.0;
  int _currentSeconds = 0;
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    _player.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      setState(() {
        _isPlaying = state == PlayerState.playing;
        if (state == PlayerState.completed) {
          _progress = 0.0;
          _currentSeconds = 0;
          _isPlaying = false;
        }
      });
      if (_isPlaying) {
        _waveController.repeat(reverse: true);
      } else {
        _waveController.stop();
      }
    });

    _player.onPositionChanged.listen((pos) {
      if (!mounted) return;
      final total = widget.durationSeconds;
      setState(() {
        _currentSeconds = pos.inSeconds;
        _progress = total > 0 ? pos.inSeconds / total : 0.0;
      });
    });
  }

  @override
  void dispose() {
    _waveController.dispose();
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (_isPlaying) {
      await _player.pause();
      return;
    }

    if (widget.audioPath == null) return;

    setState(() => _isLoading = true);
    try {
      if (_currentSeconds > 0) {
        await _player.resume();
      } else {
        await _player.play(DeviceFileSource(widget.audioPath!));
      }
    } catch (_) {
      // Fallback silencioso em dev (sem arquivo real)
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ownColor = AppColors.onMessageSent;
    final otherColor = AppColors.onMessageReceived;
    final contentColor = widget.isOwn ? ownColor : otherColor;
    final trackColor = widget.isOwn
        ? Colors.white.withValues(alpha: 0.3)
        : AppColors.neutral300;
    final activeColor = widget.isOwn
        ? Colors.white.withValues(alpha: 0.9)
        : AppColors.primary;

    return SizedBox(
      width: 220,
      child: Row(
        children: [
          // ─── Botão Play/Pause ──────────────────────────────────────────
          GestureDetector(
            onTap: _togglePlay,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.isOwn
                    ? Colors.white.withValues(alpha: 0.2)
                    : AppColors.primaryContainer,
              ),
              child: _isLoading
                  ? Padding(
                      padding: const EdgeInsets.all(10),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: contentColor,
                      ),
                    )
                  : Icon(
                      _isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: widget.isOwn ? Colors.white : AppColors.primary,
                      size: 26,
                    ),
            ),
          ),
          const SizedBox(width: 8),

          // ─── Waveform + progresso ─────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Waveform simulado
                _WaveformBar(
                  progress: _progress,
                  isPlaying: _isPlaying,
                  animation: _waveController,
                  activeColor: activeColor,
                  trackColor: trackColor,
                ),
                const SizedBox(height: 4),
                // Duração
                Text(
                  _formatDuration(
                      _isPlaying || _currentSeconds > 0
                          ? _currentSeconds
                          : widget.durationSeconds),
                  style: TextStyle(
                    fontSize: 11,
                    color: contentColor.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

/// Waveform visual com barras animadas
class _WaveformBar extends StatelessWidget {
  final double progress;
  final bool isPlaying;
  final Animation<double> animation;
  final Color activeColor;
  final Color trackColor;
  // Alturas fixas simulando um waveform
  static const _heights = [
    6.0, 12.0, 8.0, 16.0, 10.0, 18.0, 14.0, 9.0, 20.0,
    12.0, 7.0, 15.0, 11.0, 19.0, 8.0, 13.0, 17.0, 10.0,
    6.0, 14.0, 9.0, 16.0, 12.0, 7.0,
  ];

  const _WaveformBar({
    required this.progress,
    required this.isPlaying,
    required this.animation,
    required this.activeColor,
    required this.trackColor,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, __) {
        return SizedBox(
          height: 24,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(_heights.length, (i) {
              final barProgress = i / _heights.length;
              final isPassed = barProgress <= progress;
              final heightMult = isPlaying && isPassed
                  ? (1 + animation.value * 0.3)
                  : 1.0;

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 80),
                    height: (_heights[i] * heightMult).clamp(4.0, 24.0),
                    decoration: BoxDecoration(
                      color: isPassed ? activeColor : trackColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
