import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../auth/presentation/providers/current_user_provider.dart';

class EmergencyPage extends ConsumerStatefulWidget {
  const EmergencyPage({super.key});

  @override
  ConsumerState<EmergencyPage> createState() => _EmergencyPageState();
}

class _EmergencyPageState extends ConsumerState<EmergencyPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _alertaAtivo = true;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _dispararAlertaGeral() {
    final user = ref.read(currentUserProvider).valueOrNull;
    final isCoordOrDirecao = (user?.isDirecao ?? false) || (user?.isCoordenacao ?? false);

    if (!isCoordOrDirecao) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Apenas Coordenação e Direção podem emitir alertas globais de emergência.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded, color: AppColors.emergency, size: 48),
        title: const Text('DISPARAR ALERTA DE EMERGÊNCIA?'),
        content: const Text(
          'Esta ação enviará uma notificação de alta prioridade e acionará o protocolo para todos os funcionários ativos nos centros CCDTI, CCO e CCE.\n\nConfirma o disparo imediato?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.emergency),
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() => _alertaAtivo = true);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('🚨 Alerta de emergência emitido para todas as equipes!'),
                  backgroundColor: AppColors.emergency,
                  duration: Duration(seconds: 4),
                ),
              );
            },
            child: const Text('DISPARAR AGORA'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final isCoordOrDirecao = (user?.isDirecao ?? false) || (user?.isCoordenacao ?? false);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Central de Emergência'),
        backgroundColor: AppColors.emergency,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Banner animado de Status
          if (_alertaAtivo)
            ScaleTransition(
              scale: _pulseAnimation,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.emergency,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.emergency.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  children: [
                    Icon(Icons.error_outline_rounded, color: Colors.white, size: 36),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PROTOCOLO VERMELHO ATIVO',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Equipes de plantão CCDTI, CCO e CCE em prontidão prioritária.',
                            style: TextStyle(color: Colors.white, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 24),

          // Botão de ação rápida do Canal de Emergência
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.emergency, width: 1.5),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => context.push(AppRoutes.channels),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.emergencyLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.campaign_rounded, color: AppColors.emergency, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Canal Geral de Emergência',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.emergency,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Acesse o canal com transmissão em tempo real para todas as equipes.',
                            style: TextStyle(fontSize: 13, color: AppColors.neutral700),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppColors.emergency),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Contatos Rápidos de Urgência
          Text(
            'Contatos e Ramais de Emergência',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.neutral900,
                ),
          ),
          const SizedBox(height: 12),
          _EmergencyContactTile(
            titulo: 'SAMU 192 (Regulação Rio)',
            subtitulo: 'Regulação de urgência e transferências imediatas',
            ramal: '192',
            icon: Icons.local_hospital_rounded,
          ),
          const SizedBox(height: 10),
          _EmergencyContactTile(
            titulo: 'Plantão CCDTI — Diagnóstico por Imagem',
            subtitulo: 'Tomografia & Ressonância Urgente',
            ramal: 'Ramal 4101',
            icon: Icons.biotech_rounded,
          ),
          const SizedBox(height: 10),
          _EmergencyContactTile(
            titulo: 'Plantão CCO — Centro Carioca do Olho',
            subtitulo: 'Trauma ocular e emergência cirúrgica',
            ramal: 'Ramal 4201',
            icon: Icons.remove_red_eye_rounded,
          ),
          const SizedBox(height: 10),
          _EmergencyContactTile(
            titulo: 'Plantão CCE — Especialidades',
            subtitulo: 'Regulação ambulatorial e suporte clínico',
            ramal: 'Ramal 4301',
            icon: Icons.healing_rounded,
          ),
          const SizedBox(height: 28),

          // Botão Emissão de Alerta (Coordenação & Direção)
          if (isCoordOrDirecao) ...[
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.emergency,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.add_alert_rounded),
                label: const Text(
                  'EMITIR ALERTA GERAL DE EMERGÊNCIA',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                onPressed: _dispararAlertaGeral,
              ),
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}

class _EmergencyContactTile extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final String ramal;
  final IconData icon;

  const _EmergencyContactTile({
    required this.titulo,
    required this.subtitulo,
    required this.ramal,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.emergency.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.emergency, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitulo,
                    style: const TextStyle(fontSize: 12, color: AppColors.neutral600),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                ramal,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: AppColors.neutral800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
