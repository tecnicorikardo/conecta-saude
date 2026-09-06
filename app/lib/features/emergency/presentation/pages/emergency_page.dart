import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../auth/presentation/providers/current_user_provider.dart';
import '../../domain/entities/emergency_entity.dart';
import '../providers/emergency_provider.dart';

class EmergencyPage extends ConsumerStatefulWidget {
  const EmergencyPage({super.key});

  @override
  ConsumerState<EmergencyPage> createState() => _EmergencyPageState();
}

class _EmergencyPageState extends ConsumerState<EmergencyPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _openTriggerEmergencyModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _TriggerEmergencySheet(),
    );
  }

  void _confirmResolveEmergency(EmergencyAlertEntity alert) {
    final obsController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle_outline_rounded, color: AppColors.success),
            SizedBox(width: 8),
            Text('Encerrar Protocolo?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Confirma que a ocorrência em "${alert.localizacao}" foi atendida e a equipe pode retornar ao fluxo normal?',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: obsController,
              decoration: const InputDecoration(
                labelText: 'Observação do encerramento (opcional)',
                hintText: 'Ex: Paciente estabilizado, oxigênio restabelecido',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.success),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final success = await ref
                  .read(emergencyProvider.notifier)
                  .resolveEmergency(alert.id, observacao: obsController.text.trim());
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(success
                      ? '✅ Protocolo de emergência encerrado com sucesso.'
                      : 'Erro ao encerrar protocolo no servidor.'),
                  backgroundColor: success ? AppColors.success : AppColors.error,
                ),
              );
            },
            child: const Text('ENCERRAR PROTOCOLO'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(emergencyProvider);
    final user = ref.watch(currentUserProvider).valueOrNull;
    final canResolve = user != null && user.hierarquiaNivel <= 2;
    final activeAlert = state.activeAlert;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Central de Emergência'),
        backgroundColor: activeAlert != null ? AppColors.emergency : AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(emergencyProvider.notifier).loadData(),
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.emergency,
        onRefresh: () => ref.read(emergencyProvider.notifier).loadData(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ─── Banner de Emergência Ativa ou Status Normal ───────────────
            if (activeAlert != null) ...[
              ScaleTransition(
                scale: _pulseAnimation,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.emergency,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.emergency.withValues(alpha: 0.4),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.error_outline_rounded,
                              color: Colors.white, size: 32),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              activeAlert.tipo.label.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'EM ANDAMENTO',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on_rounded,
                                color: Colors.white, size: 18),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                activeAlert.localizacao,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (activeAlert.descricao != null &&
                          activeAlert.descricao!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          activeAlert.descricao!,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 13),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        'Acionado por: ${activeAlert.criadorNome} (${activeAlert.criadorCargo}) • ${DateFormat('HH:mm').format(activeAlert.criadoEm)}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 12,
                        ),
                      ),
                      if (canResolve) ...[
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.emergency,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: const Icon(Icons.check_circle_rounded),
                            label: const Text(
                              'ENCERRAR PROTOCOLO DE EMERGÊNCIA',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            onPressed: () =>
                                _confirmResolveEmergency(activeAlert),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.outlineVariant),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.shield_rounded,
                          color: AppColors.success, size: 28),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Unidade em Estado Normal',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppColors.neutral900,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Nenhum protocolo vermelho ou emergência ativa no momento.',
                            style: TextStyle(
                                fontSize: 12, color: AppColors.neutral600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),

            // ─── Botão Principal: Disparar Chamado de Emergência ───────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.emergency,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 2,
                ),
                icon: const Icon(Icons.add_alert_rounded, size: 22),
                label: const Text(
                  'DISPARAR CHAMADO DE EMERGÊNCIA',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                onPressed: _openTriggerEmergencyModal,
              ),
            ),
            const SizedBox(height: 24),

            // ─── Acesso Rápido ao Canal de Emergência ──────────────────────
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: AppColors.emergency, width: 1.2),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => context.go(AppRoutes.channels),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.emergencyLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.campaign_rounded,
                            color: AppColors.emergency, size: 26),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Canal Geral de Transmissão',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.emergency,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Transmissão de avisos em tempo real para as equipes.',
                              style: TextStyle(
                                  fontSize: 12, color: AppColors.neutral700),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right,
                          color: AppColors.emergency),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ─── Ramais e Contatos de Emergência ───────────────────────────
            Text(
              'Ramais e Contatos de Emergência',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.neutral900,
                  ),
            ),
            const SizedBox(height: 10),
            const _EmergencyContactTile(
              titulo: 'SAMU 192 (Regulação Rio)',
              subtitulo: 'Regulação de urgência e transferências imediatas',
              ramal: '192',
              icon: Icons.local_hospital_rounded,
            ),
            const SizedBox(height: 8),
            const _EmergencyContactTile(
              titulo: 'Plantão CCO — Centro Carioca do Olho',
              subtitulo: 'Trauma ocular e emergência cirúrgica',
              ramal: 'Ramal 4201',
              icon: Icons.remove_red_eye_rounded,
            ),
            const SizedBox(height: 8),
            const _EmergencyContactTile(
              titulo: 'Plantão CCDTI — Diagnóstico por Imagem',
              subtitulo: 'Tomografia e Ressonância Urgente',
              ramal: 'Ramal 4101',
              icon: Icons.biotech_rounded,
            ),
            const SizedBox(height: 8),
            const _EmergencyContactTile(
              titulo: 'Plantão CCE — Especialidades',
              subtitulo: 'Regulação ambulatorial e suporte clínico',
              ramal: 'Ramal 4301',
              icon: Icons.healing_rounded,
            ),
            const SizedBox(height: 28),

            // ─── Histórico de Ocorrências Recentes ─────────────────────────
            Text(
              'Histórico de Ocorrências da Unidade',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.neutral900,
                  ),
            ),
            const SizedBox(height: 10),
            if (state.history.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.outlineVariant),
                ),
                child: const Center(
                  child: Text(
                    'Nenhuma ocorrência registrada no histórico.',
                    style: TextStyle(color: AppColors.neutral600, fontSize: 13),
                  ),
                ),
              )
            else
              ...state.history.map((alert) => _HistoryAlertCard(alert: alert)),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ─── Modal Sheet para Disparar Emergência ─────────────────────────────────────
class _TriggerEmergencySheet extends ConsumerStatefulWidget {
  const _TriggerEmergencySheet();

  @override
  ConsumerState<_TriggerEmergencySheet> createState() =>
      _TriggerEmergencySheetState();
}

class _TriggerEmergencySheetState extends ConsumerState<_TriggerEmergencySheet> {
  EmergencyType _selectedType = EmergencyType.pcr;
  final _localController = TextEditingController();
  final _descController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _localController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final local = _localController.text.trim();
    if (local.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Informe o local exato da ocorrência.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _loading = true);
    final success = await ref.read(emergencyProvider.notifier).triggerEmergency(
          tipo: _selectedType,
          titulo: _selectedType.label,
          descricao: _descController.text.trim(),
          localizacao: local,
        );

    if (mounted) {
      setState(() => _loading = false);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? '🚨 Alerta de emergência emitido para toda a unidade!'
              : 'Erro ao emitir chamado no servidor.'),
          backgroundColor: success ? AppColors.emergency : AppColors.error,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.neutral300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    color: AppColors.emergency, size: 28),
                SizedBox(width: 8),
                Text(
                  'Acionar Protocolo de Emergência',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.emergency,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Tipos de ocorrência
            const Text(
              'Tipo de Ocorrência:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: EmergencyType.values.map((type) {
                final isSelected = _selectedType == type;
                return ChoiceChip(
                  label: Text(type.shortLabel),
                  selected: isSelected,
                  selectedColor: AppColors.emergency,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppColors.neutral800,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                  onSelected: (_) => setState(() => _selectedType = type),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Localização
            TextField(
              controller: _localController,
              decoration: const InputDecoration(
                labelText: 'Local exato da ocorrência *',
                hintText: 'Ex: Bloco Cirúrgico CCO - Sala 2 / Recepção',
                prefixIcon: Icon(Icons.location_on_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            // Descrição
            TextField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: 'Detalhes adicionais (opcional)',
                hintText: 'Ex: Paciente em parada cardiorrespiratória',
                prefixIcon: Icon(Icons.notes_rounded),
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 20),

            // Botão Disparar
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.emergency,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.notifications_active_rounded),
                label: const Text(
                  'DISPARAR ALERTA IMEDIATO',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                onPressed: _loading ? null : _submit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Card de Contato / Ramal ──────────────────────────────────────────────────
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.emergency.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppColors.emergency, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  Text(
                    subtitulo,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.neutral600),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                ramal,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
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

// ─── Card de Histórico de Ocorrência ──────────────────────────────────────────
class _HistoryAlertCard extends StatelessWidget {
  final EmergencyAlertEntity alert;

  const _HistoryAlertCard({required this.alert});

  @override
  Widget build(BuildContext context) {
    final isAtivo = alert.isAtivo;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isAtivo ? AppColors.emergency : AppColors.outlineVariant,
          width: isAtivo ? 1.5 : 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isAtivo
                      ? Icons.error_outline_rounded
                      : Icons.check_circle_outline_rounded,
                  color: isAtivo ? AppColors.emergency : AppColors.success,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    alert.tipo.shortLabel,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isAtivo ? AppColors.emergency : AppColors.neutral900,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isAtivo
                        ? AppColors.emergencyLight
                        : AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isAtivo ? 'ATIVO' : 'RESOLVIDO',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isAtivo ? AppColors.emergency : AppColors.success,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '📍 ${alert.localizacao}',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            ),
            if (alert.descricao != null && alert.descricao!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                alert.descricao!,
                style: const TextStyle(fontSize: 12, color: AppColors.neutral700),
              ),
            ],
            const SizedBox(height: 6),
            Text(
              'Acionado por ${alert.criadorNome} • ${DateFormat('dd/MM HH:mm').format(alert.criadoEm)}${alert.resolvidoEm != null ? ' • Encerrado às ${DateFormat('HH:mm').format(alert.resolvidoEm!)}' : ''}',
              style: const TextStyle(fontSize: 11, color: AppColors.neutral500),
            ),
          ],
        ),
      ),
    );
  }
}
