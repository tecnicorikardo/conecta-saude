import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/routes/app_routes.dart';

enum NotificationCategory {
  mensagem,
  comunicado,
  emergencia,
  sistema,
}

class AppNotificationItem {
  final String id;
  final String titulo;
  final String mensagem;
  final NotificationCategory categoria;
  final DateTime data;
  final bool lida;
  final String? rotaDestino;

  const AppNotificationItem({
    required this.id,
    required this.titulo,
    required this.mensagem,
    required this.categoria,
    required this.data,
    required this.lida,
    this.rotaDestino,
  });

  AppNotificationItem copyWith({bool? lida}) {
    return AppNotificationItem(
      id: id,
      titulo: titulo,
      mensagem: mensagem,
      categoria: categoria,
      data: data,
      lida: lida ?? this.lida,
      rotaDestino: rotaDestino,
    );
  }
}

final notificationsListProvider =
    StateNotifierProvider<NotificationsNotifier, List<AppNotificationItem>>((ref) {
  return NotificationsNotifier();
});

class NotificationsNotifier extends StateNotifier<List<AppNotificationItem>> {
  NotificationsNotifier()
      : super([
          AppNotificationItem(
            id: 'notif-1',
            titulo: '🚨 Alerta Geral de Emergência',
            mensagem:
                'Protocolo de alta demanda ativado no Centro Carioca de Especialidades (CCE).',
            categoria: NotificationCategory.emergencia,
            data: DateTime.now().subtract(const Duration(minutes: 15)),
            lida: false,
            rotaDestino: AppRoutes.emergency,
          ),
          AppNotificationItem(
            id: 'notif-2',
            titulo: 'Novo Comunicado Institucional',
            mensagem:
                'Manutenção preventiva dos equipamentos de tomografia no CCDTI agendada.',
            categoria: NotificationCategory.comunicado,
            data: DateTime.now().subtract(const Duration(hours: 2)),
            lida: false,
            rotaDestino: AppRoutes.announcements,
          ),
          AppNotificationItem(
            id: 'notif-3',
            titulo: 'Mensagem no Canal CCDTI',
            mensagem:
                'Dra. Juliana Moreira enviou atualizações sobre o plantão de exames.',
            categoria: NotificationCategory.mensagem,
            data: DateTime.now().subtract(const Duration(hours: 4)),
            lida: true,
            rotaDestino: AppRoutes.channels,
          ),
          AppNotificationItem(
            id: 'notif-4',
            titulo: 'Atualização do Sistema',
            mensagem:
                'A plataforma Conecta Saúde foi sincronizada com a identidade SUS.',
            categoria: NotificationCategory.sistema,
            data: DateTime.now().subtract(const Duration(days: 1)),
            lida: true,
          ),
        ]);

  void marcarComoLida(String id) {
    state = [
      for (final item in state)
        if (item.id == id) item.copyWith(lida: true) else item,
    ];
  }

  void marcarTodasComoLidas() {
    state = [
      for (final item in state) item.copyWith(lida: true),
    ];
  }

  void limparTodas() {
    state = [];
  }
}

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsListProvider);
    final naoLidas = notifications.where((n) => !n.lida).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notificações'),
        actions: [
          if (notifications.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.done_all_rounded),
              tooltip: 'Marcar todas como lidas',
              onPressed: () {
                ref.read(notificationsListProvider.notifier).marcarTodasComoLidas();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Todas as notificações foram marcadas como lidas.'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded),
              tooltip: 'Limpar notificações',
              onPressed: () {
                ref.read(notificationsListProvider.notifier).limparTodas();
              },
            ),
          ],
        ],
      ),
      body: notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.notifications_off_outlined,
                      size: 48,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Você não possui notificações',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.neutral800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Novos avisos e mensagens aparecerão aqui.',
                    style: TextStyle(color: AppColors.neutral600, fontSize: 13),
                  ),
                ],
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (naoLidas > 0)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Text(
                      '$naoLidas não lida${naoLidas > 1 ? 's' : ''}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: notifications.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final notif = notifications[index];
                      return _NotificationTile(
                        item: notif,
                        onTap: () {
                          ref
                              .read(notificationsListProvider.notifier)
                              .marcarComoLida(notif.id);
                          if (notif.rotaDestino != null) {
                            context.push(notif.rotaDestino!);
                          }
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotificationItem item;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.item,
    required this.onTap,
  });

  Color _getCategoriaColor() {
    switch (item.categoria) {
      case NotificationCategory.emergencia:
        return AppColors.emergency;
      case NotificationCategory.comunicado:
        return AppColors.info;
      case NotificationCategory.mensagem:
        return AppColors.primary;
      case NotificationCategory.sistema:
        return AppColors.neutral700;
    }
  }

  IconData _getCategoriaIcon() {
    switch (item.categoria) {
      case NotificationCategory.emergencia:
        return Icons.emergency_rounded;
      case NotificationCategory.comunicado:
        return Icons.campaign_rounded;
      case NotificationCategory.mensagem:
        return Icons.chat_bubble_outline_rounded;
      case NotificationCategory.sistema:
        return Icons.settings_outlined;
    }
  }

  String _formatarData(DateTime data) {
    final diff = DateTime.now().difference(data);
    if (diff.inMinutes < 60) {
      return 'Há ${diff.inMinutes}m';
    } else if (diff.inHours < 24) {
      return 'Há ${diff.inHours}h';
    } else {
      return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cor = _getCategoriaColor();
    final icone = _getCategoriaIcon();

    return Card(
      elevation: 0,
      color: item.lida ? Colors.white : AppColors.primaryContainer.withValues(alpha: 0.25),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: item.lida ? AppColors.outlineVariant : cor.withValues(alpha: 0.5),
          width: item.lida ? 1 : 1.5,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: cor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icone, color: cor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.titulo,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: item.lida ? FontWeight.w600 : FontWeight.bold,
                              color: AppColors.neutral900,
                            ),
                          ),
                        ),
                        Text(
                          _formatarData(item.data),
                          style: const TextStyle(fontSize: 11, color: AppColors.neutral500),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.mensagem,
                      style: const TextStyle(fontSize: 13, color: AppColors.neutral700),
                    ),
                  ],
                ),
              ),
              if (!item.lida) ...[
                const SizedBox(width: 8),
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 6),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
