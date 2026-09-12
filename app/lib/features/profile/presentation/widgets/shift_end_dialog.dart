import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/web_notification_helper.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/current_user_provider.dart';

/// Diálogo interativo de Fim de Expediente
/// Disparado automaticamente quando bate o horário de término do expediente (ex: 16:00)
class ShiftEndDialog extends ConsumerStatefulWidget {
  final UserEntity user;
  final VoidCallback onDismiss;

  const ShiftEndDialog({
    super.key,
    required this.user,
    required this.onDismiss,
  });

  @override
  ConsumerState<ShiftEndDialog> createState() => _ShiftEndDialogState();
}

class _ShiftEndDialogState extends ConsumerState<ShiftEndDialog> {
  final _hoursCtrl = TextEditingController(text: '1');
  int _remainingSeconds = 300; // 5 minutos (300s)
  Timer? _timer;
  bool _userInteracted = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
    // Dispara notificação push nativa do sistema operacional com áudio institucional
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyHospitalUser(
        '🏁 Fim de Expediente (${widget.user.jornadaFim})',
        'Seu horário regular encerrou. Toque para ir para casa ou prorrogar suas horas.',
        tag: 'shift_end',
        url: '/profile',
      );
    });
  }

  String _formatTimer(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_userInteracted) {
        t.cancel();
        return;
      }
      setState(() {
        if (_remainingSeconds > 1) {
          _remainingSeconds--;
        } else {
          t.cancel();
          _goHome(); // Se não apertar nada em 5 minutos, encerra e vai para casa
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _hoursCtrl.dispose();
    super.dispose();
  }

  void _onUserActivity() {
    if (!_userInteracted) {
      setState(() {
        _userInteracted = true;
      });
      _timer?.cancel();
    }
  }

  void _goHome() {
    _timer?.cancel();
    if (!mounted) return;

    // Remove qualquer extensão de jornada temporária para o dia
    final updated = widget.user.copyWith(jornadaEstendidaAte: null);
    ref.read(currentUserProvider.notifier).setUser(updated);

    Navigator.of(context, rootNavigator: true).pop();
    widget.onDismiss();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.home_rounded, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Expediente encerrado! Você está Fora de Serviço até as ${widget.user.jornadaInicio} de amanhã.',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF37474F),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _extendShift() {
    _timer?.cancel();
    final hours = int.tryParse(_hoursCtrl.text.trim()) ?? 1;
    final validHours = hours > 0 ? hours : 1;

    final now = DateTime.now();
    final extendedUntil = now.add(Duration(hours: validHours));

    final updated = widget.user.copyWith(jornadaEstendidaAte: extendedUntil);
    ref.read(currentUserProvider.notifier).setUser(updated);

    Navigator.of(context, rootNavigator: true).pop();
    widget.onDismiss();

    final timeStr = DateFormat('HH:mm').format(extendedUntil);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.timer_rounded, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Jornada prorrogada em $validHours hora(s). Você continuará Em Serviço até as $timeStr.',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 8,
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFFB300), width: 1.5),
                ),
                child: const Icon(
                  Icons.alarm_on_rounded,
                  color: Color(0xFFD97706),
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                'Fim de Expediente!',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),

              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: const TextStyle(fontSize: 13.5, color: Color(0xFF475569), height: 1.4),
                  children: [
                    const TextSpan(text: 'Seu horário regular de plantão encerrou às '),
                    TextSpan(
                      text: widget.user.jornadaFim,
                      style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary),
                    ),
                    const TextSpan(
                      text: '. Deseja ir para casa ou precisa permanecer trabalhando em horas extras?',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quantas horas a mais vai trabalhar?',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _hoursCtrl,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            onTap: _onUserActivity,
                            onChanged: (_) => _onUserActivity(),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                            decoration: InputDecoration(
                              isDense: true,
                              hintText: '1',
                              suffixText: 'hora(s)',
                              suffixStyle: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildQuickChip('1h', 1),
                        const SizedBox(width: 4),
                        _buildQuickChip('2h', 2),
                        const SizedBox(width: 4),
                        _buildQuickChip('3h', 3),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              if (!_userInteracted) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.timer_outlined, size: 16, color: Color(0xFF64748B)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Encerrando automaticamente em ${_formatTimer(_remainingSeconds)}...',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ),
                      Text(
                        _formatTimer(_remainingSeconds),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFD97706),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: _remainingSeconds / 300.0,
                  backgroundColor: const Color(0xFFE2E8F0),
                  color: _remainingSeconds > 60 ? const Color(0xFFD97706) : Colors.red,
                  minHeight: 4,
                  borderRadius: BorderRadius.circular(2),
                ),
                const SizedBox(height: 18),
              ] else ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFA5D6A7)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.touch_app_rounded, size: 14, color: Color(0xFF2E7D32)),
                      SizedBox(width: 6),
                      Text(
                        'Temporizador pausado (interação detectada)',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1B5E20)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _goHome,
                      icon: const Icon(Icons.home_outlined, size: 18),
                      label: const Text(
                        'Ir para Casa',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF475569),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _extendShift,
                      icon: const Icon(Icons.work_history_rounded, size: 18),
                      label: const Text(
                        'Prorrogar',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickChip(String label, int hours) {
    final isSelected = _hoursCtrl.text.trim() == hours.toString();
    return InkWell(
      onTap: () {
        _onUserActivity();
        setState(() {
          _hoursCtrl.text = hours.toString();
        });
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFCBD5E1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : const Color(0xFF334155),
          ),
        ),
      ),
    );
  }
}
