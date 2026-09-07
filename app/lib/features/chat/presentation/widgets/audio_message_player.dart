import 'dart:async';
import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
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
  StreamSubscription? _posSub;
  StreamSubscription? _stateSub;
  StreamSubscription? _completeSub;
  StreamSubscription? _durSub;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _duration = Duration(seconds: widget.durationSeconds > 0 ? widget.durationSeconds : 0);

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
        try {
          final b64 = raw.contains(',') ? raw.split(',')[1] : raw;
          final bytes = base64Decode(b64);
          await _player.play(BytesSource(bytes));
        } catch (_) {}
      } else if (raw.startsWith('http://') || raw.startsWith('https://') || raw.startsWith('blob:')) {
        await _player.play(UrlSource(raw));
      } else {
        await _player.play(DeviceFileSource(raw));
      }
    }
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
        : AppColors.primary.withValues(alpha: 0.25);
    final textColor = widget.isOwn ? Colors.white : AppColors.textPrimary;

    final maxSec = _duration.inSeconds > 0
        ? _duration.inSeconds.toDouble()
        : (widget.durationSeconds > 0 ? widget.durationSeconds.toDouble() : 1.0);
    final currentSec = _position.inSeconds.toDouble().clamp(0.0, maxSec);

    return Container(
      constraints: const BoxConstraints(minWidth: 200, maxWidth: 280),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Botão Play/Pause estilo WhatsApp
              GestureDetector(
                onTap: _togglePlay,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: widget.isOwn
                        ? Colors.white.withValues(alpha: 0.2)
                        : AppColors.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: activeColor,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Barra de progresso / slider estilo WhatsApp
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 3.5,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                        activeTrackColor: activeColor,
                        inactiveTrackColor: inactiveColor,
                        thumbColor: activeColor,
                        overlayColor: activeColor.withValues(alpha: 0.2),
                      ),
                      child: Slider(
                        value: currentSec,
                        min: 0.0,
                        max: maxSec,
                        onChanged: (val) async {
                          final newPos = Duration(seconds: val.toInt());
                          setState(() => _position = newPos);
                          await _player.seek(newPos);
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _isPlaying || _position.inSeconds > 0
                                ? _formatDuration(_position)
                                : _formatDuration(_duration),
                            style: TextStyle(
                              color: textColor.withValues(alpha: 0.8),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Icon(
                            Icons.mic_rounded,
                            size: 13,
                            color: activeColor.withValues(alpha: 0.85),
                          ),
                        ],
                      ),
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
