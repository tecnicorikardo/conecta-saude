import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme_provider.dart';
import '../../../../core/theme/app_theme_tokens.dart';
import '../../../../core/services/http_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/web_notification_helper.dart';
import '../../../../core/auth/permissions_provider.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/providers/current_user_provider.dart';
import '../widgets/shift_end_dialog.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  bool _isSaving = false;
  bool _isRequestingPush = false;
  bool _isTestingPush = false;
  String? _selectedInicio;
  String? _selectedFim;
  List<String>? _selectedDias;
  bool? _selectedSilenciar;
  bool _isSavingSchedule = false;

  Future<void> _pickImage(UserEntity user, ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      await _updateProfilePhoto(user, base64Image);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Não foi possível carregar a imagem: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showUrlInputDialog(UserEntity user) {
    final urlCtrl = TextEditingController(
      text: user.fotoUrl?.startsWith('http') == true ? user.fotoUrl : '',
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.link_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Link da Foto (URL)', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ],
        ),
        content: TextField(
          controller: urlCtrl,
          decoration: const InputDecoration(
            labelText: 'URL da imagem (https://...)',
            hintText: 'https://exemplo.com/minha-foto.jpg',
            prefixIcon: Icon(Icons.image_outlined),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              final url = urlCtrl.text.trim();
              if (url.isNotEmpty) {
                _updateProfilePhoto(user, url);
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  void _showPhotoOptions(UserEntity user) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Foto do Perfil Profissional',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFE3F2FD),
                  child: Icon(Icons.camera_alt_outlined, color: AppColors.primary),
                ),
                title: const Text('Tirar Foto com a Câmera'),
                subtitle: const Text('Usar câmera do dispositivo'),
                onTap: () {
                  Navigator.pop(bCtx);
                  _pickImage(user, ImageSource.camera);
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFE8F5E9),
                  child: Icon(Icons.photo_library_outlined, color: AppColors.success),
                ),
                title: const Text('Escolher da Galeria / Arquivos'),
                subtitle: const Text('Selecionar foto do dispositivo'),
                onTap: () {
                  Navigator.pop(bCtx);
                  _pickImage(user, ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFF3E5F5),
                  child: Icon(Icons.link_rounded, color: Color(0xFF7C3AED)),
                ),
                title: const Text('Inserir Link de Foto (URL)'),
                subtitle: const Text('Usar link direto da web'),
                onTap: () {
                  Navigator.pop(bCtx);
                  _showUrlInputDialog(user);
                },
              ),
              if (user.fotoUrl != null && user.fotoUrl!.isNotEmpty)
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFFFEBEE),
                    child: Icon(Icons.delete_outline, color: AppColors.error),
                  ),
                  title: const Text('Remover Foto Atual', style: TextStyle(color: AppColors.error)),
                  onTap: () {
                    Navigator.pop(bCtx);
                    _updateProfilePhoto(user, null);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _updateSchedule({
    required UserEntity user,
    String? jornadaInicio,
    String? jornadaFim,
    String? jornadaDias,
    bool? emPlantaoExtra,
    bool? silenciarForaJornada,
  }) async {
    setState(() => _isSavingSchedule = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final resp = await HttpService.instance.patch(
        '/users/me/schedule',
        data: {
          if (jornadaInicio != null) 'jornadaInicio': jornadaInicio,
          if (jornadaFim != null) 'jornadaFim': jornadaFim,
          if (jornadaDias != null) 'jornadaDias': jornadaDias,
          if (emPlantaoExtra != null) 'emPlantaoExtra': emPlantaoExtra,
          if (silenciarForaJornada != null) 'silenciarForaJornada': silenciarForaJornada,
        },
      );
      if (resp.data['success'] == true) {
        final updatedUser = user.copyWith(
          jornadaInicio: jornadaInicio ?? user.jornadaInicio,
          jornadaFim: jornadaFim ?? user.jornadaFim,
          jornadaDias: jornadaDias ?? user.jornadaDias,
          emPlantaoExtra: emPlantaoExtra ?? user.emPlantaoExtra,
          silenciarForaJornada: silenciarForaJornada ?? user.silenciarForaJornada,
        );
        ref.read(currentUserProvider.notifier).setUser(updatedUser);
        messenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Escala salva com sucesso! Seu status agora é: ${updatedUser.workStatusLabel}.',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Erro ao atualizar escala: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSavingSchedule = false);
      }
    }
  }

  Future<void> _updateProfilePhoto(UserEntity user, String? newPhotoUrl) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isSaving = true);
    try {
      final resp = await HttpService.instance.put(
        '/users/${user.id}',
        data: {
          'fotoUrl': newPhotoUrl,
        },
      );
      if (resp.data['success'] == true) {
        final updatedUser = user.copyWith(fotoUrl: newPhotoUrl);
        ref.read(currentUserProvider.notifier).setUser(updatedUser);
        messenger.showSnackBar(
          SnackBar(
            content: Text(newPhotoUrl != null
                ? 'Foto de perfil atualizada com sucesso!'
                : 'Foto de perfil removida com sucesso!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Erro ao atualizar foto: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

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

  Future<void> _handleTestPush({int delaySeconds = 0}) async {
    if (_isTestingPush) return;
    setState(() => _isTestingPush = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final notifService = ref.read(notificationServiceProvider);
      final token = await notifService.syncToken();
      if (token == null) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('⚠️ Não foi possível obter o token deste dispositivo. Verifique a permissão do navegador.'),
            backgroundColor: AppColors.warning,
          ),
        );
        return;
      }

      // Disparar chime e notificação nativa imediata no navegador se estiver em primeiro plano
      if (delaySeconds == 0) {
        notifyHospitalUser(
          '🚨 Teste Conecta Saúde (SUS)',
          'Notificação push e áudio institucional funcionando!',
          tag: 'test_push',
        );
      }

      final response = await HttpService.instance.post(
        '/auth/test-push',
        data: {'delaySeconds': delaySeconds},
      );
      if (!mounted) return;

      if (response.data['success'] == true) {
        if (delaySeconds > 0) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.timer_outlined, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text('Disparo em 5 Segundos!'),
                ],
              ),
              content: const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '⏳ O servidor vai disparar a notificação em 5 segundos.',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Text('👉 Minimize o aplicativo agora ou bloqueie a tela do celular para ver o alerta chegar em segundo plano na barra de status do Android/Windows!'),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Entendi, vou minimizar')),
              ],
            ),
          );
        } else {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.check_circle, color: AppColors.success),
                  SizedBox(width: 8),
                  Text('Push Despachado!'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('O servidor enviou com sucesso uma notificação push via Firebase Cloud Messaging:'),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Token: ${response.data['tokenPreview']}', style: const TextStyle(fontSize: 11, fontFamily: 'monospace')),
                        const SizedBox(height: 4),
                        Text('ID Mensagem: ${response.data['messageId']}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('O som institucional foi emitido e a notificação foi enviada ao sistema operacional.'),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
              ],
            ),
          );
        }
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Falha ao enviar push: ${response.data['errorMessage']}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Erro na requisição: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isTestingPush = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final perms = ref.watch(permissionsProvider);
    final pushStatus = ref.watch(pushPermissionStatusProvider);
    final hasPush = pushStatus == AuthorizationStatus.authorized || pushStatus == AuthorizationStatus.provisional;
    final currentThemeMode = ref.watch(appThemeModeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Meu Perfil Profissional',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            letterSpacing: 0.2,
          ),
        ),
        backgroundColor: AppColors.primaryDeep,
        foregroundColor: Colors.white,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: AppColors.primaryDeep,
          statusBarIconBrightness: Brightness.light,
        ),
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
                            AppAvatar(
                              name: user.nome,
                              fotoUrl: user.fotoUrl,
                              size: 88,
                              hierarquiaNivel: user.hierarquiaNivel,
                              showEditBadge: true,
                              onEditTap: () => _showPhotoOptions(user),
                              onTap: () => _showPhotoOptions(user),
                            ),
                            Positioned(
                              left: 0,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Color(perms.levelColorHex),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: const Icon(Icons.verified_user, color: Colors.white, size: 14),
                              ),
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

                  // ─── Minha Escala & Horário de Plantão ───────────────────
                  _buildScheduleCard(user, isDark),
                  const SizedBox(height: 16),

                  // ─── Seletor de Temas Visuais ────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? Colors.white12 : AppColors.border,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.palette_outlined, size: 18, color: isDark ? Colors.white70 : AppColors.primary),
                                const SizedBox(width: 8),
                                const Text(
                                  'APARÊNCIA E TEMA VISUAL',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.primary.withValues(alpha: 0.2) : AppColors.softBlue,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDark ? Colors.white24 : AppColors.primary.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Text(
                                currentThemeMode.label,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Personalize a identidade visual do Conecta Saúde. O padrão institucional do SUS é mantido como base em todos os temas.',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: isDark ? Colors.white60 : AppColors.textSecondary,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _buildThemeOption(
                          context: context,
                          mode: AppThemeMode.susLight,
                          isSelected: currentThemeMode == AppThemeMode.susLight,
                          onTap: () => ref.read(appThemeModeProvider.notifier).setTheme(AppThemeMode.susLight),
                        ),
                        const SizedBox(height: 8),
                        _buildThemeOption(
                          context: context,
                          mode: AppThemeMode.dark,
                          isSelected: currentThemeMode == AppThemeMode.dark,
                          onTap: () => ref.read(appThemeModeProvider.notifier).setTheme(AppThemeMode.dark),
                        ),
                        const SizedBox(height: 8),
                        _buildThemeOption(
                          context: context,
                          mode: AppThemeMode.lgbtq,
                          isSelected: currentThemeMode == AppThemeMode.lgbtq,
                          onTap: () => ref.read(appThemeModeProvider.notifier).setTheme(AppThemeMode.lgbtq),
                        ),
                        const SizedBox(height: 8),
                        _buildThemeOption(
                          context: context,
                          mode: AppThemeMode.rosa,
                          isSelected: currentThemeMode == AppThemeMode.rosa,
                          onTap: () => ref.read(appThemeModeProvider.notifier).setTheme(AppThemeMode.rosa),
                        ),
                        const SizedBox(height: 8),
                        _buildThemeOption(
                          context: context,
                          mode: AppThemeMode.system,
                          isSelected: currentThemeMode == AppThemeMode.system,
                          onTap: () => ref.read(appThemeModeProvider.notifier).setTheme(AppThemeMode.system),
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
                          )
                        else ...[
                          ElevatedButton.icon(
                            onPressed: _isTestingPush ? null : () => _handleTestPush(delaySeconds: 0),
                            icon: _isTestingPush
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.volume_up_outlined, size: 18),
                            label: Text(_isTestingPush ? 'Disparando...' : '🔔 Testar Agora (Com Som e Alerta)'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1565C0),
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(42),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: _isTestingPush ? null : () => _handleTestPush(delaySeconds: 5),
                            icon: const Icon(Icons.timer_outlined, size: 18),
                            label: const Text('⏱️ Testar em Segundo Plano (5s para Minimizar)'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF1565C0),
                              side: const BorderSide(color: Color(0xFF1565C0), width: 1.2),
                              minimumSize: const Size.fromHeight(42),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Center(
                            child: Text(
                              'Use "Testar em Segundo Plano" para minimizar o app e ver o push no Android/Windows.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                            ),
                          ),
                        ],
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
                  // ─── Política de Retenção & Sigilo Operacional (LGPD) ────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.shield_outlined, color: AppColors.primary, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'POLÍTICA DE RETENÇÃO E SIGILO OPERACIONAL',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white70 : AppColors.primary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Em conformidade com as diretrizes do hospital e a LGPD na saúde, todas as mensagens e conversas do plantão são operacionais e expiram automaticamente em 24 horas para preservar o sigilo médico e garantir alto desempenho do sistema.',
                                style: TextStyle(
                                  fontSize: 12,
                                  height: 1.4,
                                  color: isDark ? Colors.white60 : AppColors.neutral600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
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

  Widget _buildThemeOption({
    required BuildContext context,
    required AppThemeMode mode,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget previewWidget;
    switch (mode) {
      case AppThemeMode.susLight:
        previewWidget = Container(
          width: 44,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFF6F8FA),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFD8E0E8)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Container(
                height: 10,
                decoration: const BoxDecoration(
                  color: Color(0xFF0B3D6E),
                ),
              ),
              Expanded(
                child: Center(
                  child: Container(
                    width: 24,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(2),
                      border: Border.all(color: const Color(0xFFD8E0E8)),
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: 4,
                        color: const Color(0xFF1565C0),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
        break;
      case AppThemeMode.dark:
        previewWidget = Container(
          width: 44,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFF081522),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFF2A455D)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Container(
                height: 10,
                decoration: const BoxDecoration(
                  color: Color(0xFF0F2438),
                ),
              ),
              Expanded(
                child: Center(
                  child: Container(
                    width: 24,
                    height: 12,
                    decoration: BoxDecoration(
                      color: const Color(0xFF143450),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: 4,
                        color: const Color(0xFF42A5F5),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
        break;
      case AppThemeMode.lgbtq:
        previewWidget = Container(
          width: 44,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFF6F8FA),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFD8E0E8)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: Container(height: 2.5, color: const Color(0xFFE85D75))),
                  Expanded(child: Container(height: 2.5, color: const Color(0xFFE99A45))),
                  Expanded(child: Container(height: 2.5, color: const Color(0xFFD8B52C))),
                  Expanded(child: Container(height: 2.5, color: const Color(0xFF4C9B6B))),
                  Expanded(child: Container(height: 2.5, color: const Color(0xFF3D7CC9))),
                  Expanded(child: Container(height: 2.5, color: const Color(0xFF7657A6))),
                ],
              ),
              Container(
                height: 7.5,
                color: const Color(0xFF0B3D6E),
              ),
              Expanded(
                child: Center(
                  child: Container(
                    width: 24,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(2),
                      border: Border.all(color: const Color(0xFFD8E0E8)),
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: 4,
                        color: const Color(0xFF1565C0),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
        break;
      case AppThemeMode.rosa:
        previewWidget = Container(
          width: 44,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFF8F7F9),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFE4D6DF)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Container(
                height: 10,
                decoration: const BoxDecoration(
                  color: Color(0xFF0B3D6E),
                ),
              ),
              Expanded(
                child: Center(
                  child: Container(
                    width: 24,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(2),
                      border: Border.all(color: const Color(0xFFE4D6DF)),
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: 4,
                        color: const Color(0xFFC04B78),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
        break;
      case AppThemeMode.system:
        previewWidget = Container(
          width: 44,
          height: 36,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F2438) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: isDark ? const Color(0xFF2A455D) : const Color(0xFFD8E0E8)),
          ),
          child: const Center(
            child: Icon(Icons.brightness_auto_rounded, size: 20, color: AppColors.primary),
          ),
        );
        break;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? const Color(0xFF143450) : const Color(0xFFEAF3FB))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            children: [
              previewWidget,
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mode.label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                        color: isDark ? Colors.white : AppColors.navy,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      mode.description,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark ? Colors.white60 : AppColors.textSecondary,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? AppColors.primary : (isDark ? Colors.white38 : const Color(0xFFCBD5E1)),
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScheduleCard(UserEntity user, bool isDark) {
    final currentInicio = _selectedInicio ?? user.jornadaInicio;
    final currentFim = _selectedFim ?? user.jornadaFim;
    final currentDias = _selectedDias ?? user.jornadaDias.toLowerCase().split(',').map((d) => d.trim()).toList();
    final currentSilenciar = _selectedSilenciar ?? user.silenciarForaJornada;

    final allDays = [
      {'code': 'seg', 'label': 'Seg'},
      {'code': 'ter', 'label': 'Ter'},
      {'code': 'qua', 'label': 'Qua'},
      {'code': 'qui', 'label': 'Qui'},
      {'code': 'sex', 'label': 'Sex'},
      {'code': 'sab', 'label': 'Sáb'},
      {'code': 'dom', 'label': 'Dom'},
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : AppColors.border,
          width: 1,
        ),
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
              Row(
                children: [
                  Icon(Icons.schedule_rounded, size: 18, color: user.workStatusColor),
                  const SizedBox(width: 8),
                  const Text(
                    'MINHA ESCALA & PLANTÃO',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: user.workStatusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: user.workStatusColor, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: user.workStatusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      user.workStatusLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: user.workStatusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Configure sua jornada habitual. Fora do horário configurado, seu status é marcado automaticamente como "Fora de Serviço" e as notificações de mensagens comuns são silenciadas.',
            style: TextStyle(
              fontSize: 12.5,
              color: isDark ? Colors.white60 : AppColors.textSecondary,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 14),

          // Horários de Entrada e Saída
          const Text(
            'Horário de Trabalho Habitual (Formato 24h)',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildTimeButton(
                  label: 'Entrada',
                  time: currentInicio,
                  isDark: isDark,
                  onTap: () async {
                    final parts = currentInicio.split(':').map((e) => int.tryParse(e) ?? 0).toList();
                    final initial = TimeOfDay(hour: parts.isNotEmpty ? parts[0] : 7, minute: parts.length > 1 ? parts[1] : 0);
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: initial,
                      builder: (context, child) => MediaQuery(
                        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
                        child: child!,
                      ),
                    );
                    if (picked != null) {
                      final h = picked.hour.toString().padLeft(2, '0');
                      final m = picked.minute.toString().padLeft(2, '0');
                      setState(() => _selectedInicio = '$h:$m');
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildTimeButton(
                  label: 'Saída',
                  time: currentFim,
                  isDark: isDark,
                  onTap: () async {
                    final parts = currentFim.split(':').map((e) => int.tryParse(e) ?? 0).toList();
                    final initial = TimeOfDay(hour: parts.isNotEmpty ? parts[0] : 16, minute: parts.length > 1 ? parts[1] : 0);
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: initial,
                      builder: (context, child) => MediaQuery(
                        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
                        child: child!,
                      ),
                    );
                    if (picked != null) {
                      final h = picked.hour.toString().padLeft(2, '0');
                      final m = picked.minute.toString().padLeft(2, '0');
                      setState(() => _selectedFim = '$h:$m');
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Dias de Trabalho
          const Text(
            'Dias de Escala / Plantão',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: allDays.map((d) {
              final code = d['code']!;
              final isSelected = currentDias.contains(code);
              return FilterChip(
                label: Text(d['label']!),
                selected: isSelected,
                selectedColor: AppColors.primary.withValues(alpha: 0.15),
                checkmarkColor: AppColors.primary,
                labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppColors.primary : (isDark ? Colors.white70 : AppColors.neutral900),
                ),
                onSelected: (selected) {
                  final newDias = List<String>.from(currentDias);
                  if (selected) {
                    if (!newDias.contains(code)) newDias.add(code);
                  } else {
                    newDias.remove(code);
                  }
                  if (newDias.isNotEmpty) {
                    setState(() => _selectedDias = newDias);
                  }
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 14),

          // Silenciar Notificações Fora da Jornada
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Silenciar Fora da Jornada',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Não emitir som de mensagens comuns fora do plantão (Alertas de emergência não são afetados)',
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: currentSilenciar,
                  activeThumbColor: AppColors.primary,
                  onChanged: (val) {
                    setState(() => _selectedSilenciar = val);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ─── Botão Explícito "Salvar Escala" ───────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSavingSchedule
                  ? null
                  : () => _updateSchedule(
                        user: user,
                        jornadaInicio: currentInicio,
                        jornadaFim: currentFim,
                        jornadaDias: currentDias.join(','),
                        silenciarForaJornada: currentSilenciar,
                      ),
              icon: _isSavingSchedule
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save_rounded, size: 20),
              label: Text(
                _isSavingSchedule ? 'Salvando Escala...' : 'Salvar Escala & Horários',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 1,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // ─── Botão de Teste / Simulação do Alerta ─────────────────────
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => ShiftEndDialog(
                    user: user,
                    onDismiss: () {},
                  ),
                );
              },
              icon: const Icon(Icons.alarm_on_rounded, size: 18),
              label: const Text(
                'Testar Alerta de Fim de Expediente (5 min)',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: isDark ? Colors.white70 : AppColors.primary,
                side: BorderSide(
                  color: isDark ? Colors.white24 : AppColors.primary.withValues(alpha: 0.4),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeButton({
    required String label,
    required String time,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F2438) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isDark ? const Color(0xFF2A455D) : const Color(0xFFD8E0E8)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : AppColors.textSecondary),
                ),
                const SizedBox(height: 2),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.neutral900,
                  ),
                ),
              ],
            ),
            const Icon(Icons.access_time_rounded, size: 18, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
