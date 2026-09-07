import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/http_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/auth/permissions_provider.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/providers/current_user_provider.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  bool _isSaving = false;
  bool _isRequestingPush = false;

  void _showEditProfileDialog(UserEntity user) {
    final nomeCtrl = TextEditingController(text: user.nome);
    final cargoCtrl = TextEditingController(text: user.cargo);
    final matriculaCtrl = TextEditingController(text: user.matricula ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.edit_outlined, color: AppColors.primary),
              SizedBox(width: 8),
              Text('Editar Meus Dados', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            ],
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: nomeCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nome Completo',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (v) => (v == null || v.trim().length < 2) ? 'Nome inválido' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: cargoCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Cargo / Função',
                      prefixIcon: Icon(Icons.work_outline),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe seu cargo' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: matriculaCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Matrícula / Registro SUS',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: _isSaving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() => _isSaving = true);
                      final nav = Navigator.of(dialogCtx);
                      final messenger = ScaffoldMessenger.of(context);
                      try {
                        final resp = await HttpService.instance.put(
                          '/users/${user.id}',
                          data: {
                            'nome': nomeCtrl.text.trim(),
                            'cargo': cargoCtrl.text.trim(),
                            'matricula': matriculaCtrl.text.trim().isNotEmpty
                                ? matriculaCtrl.text.trim()
                                : null,
                          },
                        );

                        if (resp.data['success'] == true) {
                          final data = resp.data['data'] as Map<String, dynamic>;
                          final updatedUser = user.copyWith(
                            nome: data['nome'] as String? ?? nomeCtrl.text.trim(),
                            cargo: data['cargo'] as String? ?? cargoCtrl.text.trim(),
                            matricula: data['matricula'] as String? ?? matriculaCtrl.text.trim(),
                          );
                          ref.read(currentUserProvider.notifier).setUser(updatedUser);
                          nav.pop();
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Dados atualizados com sucesso!'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      } catch (e) {
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text('Erro ao salvar: $e'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      } finally {
                        setDialogState(() => _isSaving = false);
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: _isSaving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleEnablePushNotifications() async {
    if (_isRequestingPush) return;
    setState(() => _isRequestingPush = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final notifService = ref.read(notificationServiceProvider);
      final status = await notifService.requestPermissionExplicitly();
      if (status == AuthorizationStatus.authorized ||
          status == AuthorizationStatus.provisional) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('✅ Notificações Push ativadas com sucesso neste dispositivo!'),
            backgroundColor: AppColors.success,
          ),
        );
      } else if (status == AuthorizationStatus.denied) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('⚠️ Notificações bloqueadas nas configurações do navegador. Clique no cadeado da barra de endereço para permitir.'),
            backgroundColor: AppColors.warning,
            duration: Duration(seconds: 6),
          ),
        );
      } else {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Status de notificação atualizado.'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Erro ao ativar notificações: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isRequestingPush = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final perms = ref.watch(permissionsProvider);
    final pushStatus = ref.watch(pushPermissionStatusProvider);
    final hasPush = pushStatus == AuthorizationStatus.authorized || pushStatus == AuthorizationStatus.provisional;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Meu Perfil Profissional'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (user != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _showEditProfileDialog(user),
              tooltip: 'Editar Dados',
            ),
        ],
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  // ─── Header com Avatar e Nível ────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            CircleAvatar(
                              radius: 44,
                              backgroundColor: AppColors.primary,
                              child: Text(
                                user.nome.isNotEmpty ? user.nome[0].toUpperCase() : '?',
                                style: const TextStyle(fontSize: 34, color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Color(perms.levelColorHex),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(Icons.verified_user, color: Colors.white, size: 14),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          user.nome,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.neutral900),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.email,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 13, color: AppColors.neutral600),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Color(perms.levelColorHex).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Color(perms.levelColorHex), width: 1),
                          ),
                          child: Text(
                            perms.hierarquiaLabel,
                            style: TextStyle(
                              color: Color(perms.levelColorHex),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ─── Dados Funcionais e Setor ──────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'INFORMAÇÕES FUNCIONAIS',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _buildInfoTile(
                          icon: Icons.work_outline_rounded,
                          label: 'Cargo / Função',
                          value: user.cargo.isNotEmpty ? user.cargo : 'Não informado',
                        ),
                        const Divider(height: 20, color: Color(0xFFF1F5F9)),
                        _buildInfoTile(
                          icon: Icons.local_hospital_outlined,
                          label: 'Unidade / Setor de Lotação',
                          value: user.setorNome.isNotEmpty ? user.setorNome : 'Centro Carioca do Olho (CCO)',
                        ),
                        const Divider(height: 20, color: Color(0xFFF1F5F9)),
                        _buildInfoTile(
                          icon: Icons.badge_outlined,
                          label: 'Matrícula / Registro SUS',
                          value: (user.matricula != null && user.matricula!.isNotEmpty)
                              ? user.matricula!
                              : 'Não informada',
                        ),
                        const Divider(height: 20, color: Color(0xFFF1F5F9)),
                        _buildInfoTile(
                          icon: Icons.check_circle_outline_rounded,
                          label: 'Status do Acesso',
                          value: user.ativo ? 'Ativo e Liberado' : 'Aguardando Aprovação',
                          valueColor: user.ativo ? AppColors.success : AppColors.warning,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ─── Status das Notificações Push ─────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'NOTIFICAÇÕES PUSH DO SISTEMA',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                                letterSpacing: 0.8,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: hasPush
                                    ? AppColors.success.withValues(alpha: 0.15)
                                    : const Color(0xFFFFF3E0),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                hasPush ? 'Ativado' : 'Não Ativado',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: hasPush ? AppColors.success : const Color(0xFFE65100),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          hasPush
                              ? 'Este dispositivo está registrado para receber alertas em segundo plano e com o aplicativo fechado.'
                              : 'Ative as notificações para receber avisos de plantão, mensagens institucionais e alertas de emergência.',
                          style: const TextStyle(fontSize: 12.5, color: AppColors.neutral600),
                        ),
                        const SizedBox(height: 14),
                        if (!hasPush)
                          ElevatedButton.icon(
                            onPressed: _isRequestingPush ? null : _handleEnablePushNotifications,
                            icon: const Icon(Icons.notifications_active_outlined, size: 18),
                            label: _isRequestingPush
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Text('Ativar Notificações Push'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(42),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ─── Botão Editar e Sair ──────────────────────────────────
                  OutlinedButton.icon(
                    onPressed: () => _showEditProfileDialog(user),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Atualizar Meus Dados'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary, width: 1.2),
                      minimumSize: const Size.fromHeight(46),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () => ref.read(authRepositoryProvider).signOut(),
                    icon: const Icon(Icons.logout, size: 18),
                    label: const Text('Sair da Conta'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(46),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.neutral600),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? AppColors.neutral900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
