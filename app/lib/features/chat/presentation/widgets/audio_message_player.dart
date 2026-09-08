import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class AudioMessagePlayer extends StatefulWidget {
  final String audioSource;
  final int durationSeconds;
  final bool isOwn;

  const AudioMessagePlayer({
    super.key,
    required this.audioSource,
    required this.durationSeconds,
    required this.isOwn,
  });

  @override
  State<AudioMessagePlayer> createState() => _AudioMessagePlayerState();
}

class _AudioMessagePlayerState extends State<AudioMessagePlayer> {
  late final AudioPlayer _player;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  double _playbackRate = 1.0;
  late final List<double> _waveformHeights;

  StreamSubscription? _posSub;
  StreamSubscription? _stateSub;
  StreamSubscription? _completeSub;
  StreamSubscription? _durSub;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _duration = Duration(seconds: widget.durationSeconds > 0 ? widget.durationSeconds : 0);
    _waveformHeights = _generateWaveform(widget.audioSource);

    _stateSub = _player.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() => _isPlaying = state == PlayerState.playing);
      }
    });

    _posSub = _player.onPositionChanged.listen((pos) {
      if (mounted) {
        setState(() => _position = pos);
      }
    });

    _durSub = _player.onDurationChanged.listen((dur) {
      if (mounted && dur.inSeconds > 0) {
        setState(() => _duration = dur);
      }
    });

    _completeSub = _player.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _position = Duration.zero;
        });
      }
    });
  }

  /// Gera um perfil determinístico de barras de equalizador baseado no conteúdo do áudio
  List<double> _generateWaveform(String source) {
    const barCount = 32;
    final seed = source.length + (source.isNotEmpty ? source.codeUnitAt(0) * 31 : 42);
    final rand = math.Random(seed);
    final list = <double>[];

    for (int i = 0; i < barCount; i++) {
      // Simula uma forma de onda natural de voz humana (variação suave com picos)
      final base = 0.25 + 0.65 * rand.nextDouble();
      final envelope = math.sin((i / (barCount - 1)) * math.pi) * 0.3 + 0.7;
      list.add((base * envelope).clamp(0.2, 1.0));
    }
    return list;
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _stateSub?.cancel();
    _completeSub?.cancel();
    _durSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (_isPlaying) {
      await _player.pause();
    } else {
      final raw = widget.audioSource.trim();
      if (raw.startsWith('data:audio') || raw.startsWith('data:application')) {
        if (kIsWeb) {
          await _player.play(UrlSource(raw));
        } else {
          try {
            final b64 = raw.contains(',') ? raw.split(',')[1] : raw;
            final bytes = base64Decode(b64);
            await _player.play(BytesSource(bytes));
          } catch (_) {
            await _player.play(UrlSource(raw));
          }
        }
      } else if (raw.startsWith('http://') || raw.startsWith('https://') || raw.startsWith('blob:')) {
        await _player.play(UrlSource(raw));
      } else {
        await _player.play(DeviceFileSource(raw));
      }
      await _player.setPlaybackRate(_playbackRate);
    }
  }

  Future<void> _cyclePlaybackRate() async {
    double nextRate = 1.0;
    if (_playbackRate == 1.0) {
      nextRate = 1.5;
    } else if (_playbackRate == 1.5) {
      nextRate = 2.0;
    } else {
      nextRate = 1.0;
    }

    setState(() => _playbackRate = nextRate);
    if (_isPlaying) {
      await _player.setPlaybackRate(nextRate);
    }
  }

  void _seekByPercent(double percent) async {
    final maxSec = _duration.inSeconds > 0
        ? _duration.inSeconds
        : (widget.durationSeconds > 0 ? widget.durationSeconds : 1);
    final targetSec = (percent * maxSec).clamp(0.0, maxSec.toDouble());
    final newPos = Duration(milliseconds: (targetSec * 1000).round());
    setState(() => _position = newPos);
    await _player.seek(newPos);
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString();
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.isOwn ? Colors.white : AppColors.primary;
    final inactiveColor = widget.isOwn
        ? Colors.white.withValues(alpha: 0.35)
        : AppColors.primary.withValues(alpha: 0.28);
    final textColor = widget.isOwn ? Colors.white : AppColors.textPrimary;

    final totalSeconds = _duration.inSeconds > 0
        ? _duration.inSeconds.toDouble()
        : (widget.durationSeconds > 0 ? widget.durationSeconds.toDouble() : 1.0);
    final currentSeconds = _position.inMilliseconds / 1000.0;
    final progress = (currentSeconds / totalSeconds).clamp(0.0, 1.0);

    return Container(
      constraints: const BoxConstraints(minWidth: 220, maxWidth: 290),
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Botão Play / Pause estilo WhatsApp
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _togglePlay,
                  borderRadius: BorderRadius.circular(22),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: widget.isOwn
                          ? Colors.white.withValues(alpha: 0.22)
                          : AppColors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: activeColor,
                      size: 26,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Equalizador de áudio interativo (Waveform)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTapDown: (details) {
                            final percent = (details.localPosition.dx / constraints.maxWidth).clamp(0.0, 1.0);
                            _seekByPercent(percent);
                          },
                          onHorizontalDragUpdate: (details) {
                            final percent = (details.localPosition.dx / constraints.maxWidth).clamp(0.0, 1.0);
                            _seekByPercent(percent);
                          },
                          child: SizedBox(
                            height: 28,
                            width: constraints.maxWidth,
                            child: CustomPaint(
                              painter: _WaveformEqualizerPainter(
                                waveform: _waveformHeights,
                                progress: progress,
                                activeColor: activeColor,
                                inactiveColor: inactiveColor,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 5),

                    // Rodapé: Duração atual, botão de velocidade (1x, 1.5x, 2x) e microfone
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _isPlaying || _position.inSeconds > 0
                              ? _formatDuration(_position)
                              : _formatDuration(_duration),
                          style: TextStyle(
                            color: textColor.withValues(alpha: 0.85),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                        ),

                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Botão de velocidade estilo WhatsApp (1x, 1.5x, 2x)
                            InkWell(
                              onTap: _cyclePlaybackRate,
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: widget.isOwn
                                      ? Colors.white.withValues(alpha: 0.18)
                                      : AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${_playbackRate == 1.0 ? '1' : _playbackRate.toString()}x',
                                  style: TextStyle(
                                    color: activeColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.mic_rounded,
                              size: 14,
                              color: activeColor.withValues(alpha: 0.85),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// CustomPainter que desenha barras de onda sonora verticais com pontas arredondadas,
/// preenchendo as barras tocadas com cor ativa e as futuras com cor suave.
class _WaveformEqualizerPainter extends CustomPainter {
  final List<double> waveform;
  final double progress;
  final Color activeColor;
  final Color inactiveColor;

  _WaveformEqualizerPainter({
    required this.waveform,
    required this.progress,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (waveform.isEmpty) return;

    final barCount = waveform.length;
    const barSpacing = 2.5;
    final totalSpacing = barSpacing * (barCount - 1);
    final barWidth = math.max(2.0, (size.width - totalSpacing) / barCount);
    final maxHeight = size.height;

    final activePaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.fill;

    final inactivePaint = Paint()
      ..color = inactiveColor
      ..style = PaintingStyle.fill;

    for (int i = 0; i < barCount; i++) {
      final x = i * (barWidth + barSpacing);
      final barNormalizedHeight = waveform[i];
      final barHeight = (barNormalizedHeight * maxHeight).clamp(4.0, maxHeight);
      final y = (maxHeight - barHeight) / 2.0;

      final barProgress = (i + 0.5) / barCount;
      final isBarActive = barProgress <= progress;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, barHeight),
        const Radius.circular(3),
      );

      canvas.drawRRect(rect, isBarActive ? activePaint : inactivePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformEqualizerPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.inactiveColor != inactiveColor;
  }
}
