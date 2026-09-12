import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/hospital_roles.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../sectors/domain/entities/sector_entity.dart';
import '../../../sectors/presentation/providers/sectors_provider.dart';
import '../../../units/domain/entities/hospital_unit_entity.dart';
import '../../../units/presentation/providers/units_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/login_logo.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final _nomeCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _matriculaCtrl = TextEditingController();
  final _cargoCustomCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  final _nomeFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _matriculaFocus = FocusNode();
  final _cargoCustomFocus = FocusNode();
  final _passFocus = FocusNode();
  final _confirmPassFocus = FocusNode();

  String? _selectedUnitId;
  String? _selectedSectorId;
  String? _selectedRole;
  bool _isCustomRole = false;

  // Escala inicial sugerida
  String _jornadaInicio = '07:00';
  String _jornadaFim = '16:00';
  final List<String> _selectedDays = ['seg', 'ter', 'qua', 'qui', 'sex'];

  bool _obscurePass = true;
  bool _obscureConfirm = true;

  static const Color _primaryBlue = Color(0xFF1565C0);
  static const Color _textPrimary = Color(0xFF263238);
  static const Color _textSecondary = Color(0xFF607D8B);
  static const Color _borderColor = Color(0xFFD9E2EC);
  static const Color _inputFillColor = Color(0xFFF8FAFC);
  static const Color _errorColor = Color(0xFFC62828);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(registerNotifierProvider.notifier).reset();
    });
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _emailCtrl.dispose();
    _matriculaCtrl.dispose();
    _cargoCustomCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();

    _nomeFocus.dispose();
    _emailFocus.dispose();
    _matriculaFocus.dispose();
    _cargoCustomFocus.dispose();
    _passFocus.dispose();
    _confirmPassFocus.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedSectorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecione seu Setor de lotação.'),
          backgroundColor: _errorColor,
        ),
      );
      return;
    }

    final finalCargo = _isCustomRole
        ? _cargoCustomCtrl.text.trim()
        : (_selectedRole ?? '').trim();

    if (finalCargo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecione ou informe seu cargo / função.'),
          backgroundColor: _errorColor,
        ),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    ref.read(registerNotifierProvider.notifier).register(
          nome: _nomeCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text,
          cargo: finalCargo,
          setorId: _selectedSectorId!,
          unitId: _selectedUnitId,
          matricula: _matriculaCtrl.text.trim(),
          jornadaInicio: _jornadaInicio,
          jornadaFim: _jornadaFim,
          jornadaDias: _selectedDays.join(','),
        );
  }

  void _showSuccessDialog(RegisterSuccess state) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFE8F5E9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF2E7D32),
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Solicitação Enviada!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: _textPrimary,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Olá, ${state.nome}!\n\nSeu cadastro foi registrado com sucesso e está aguardando liberação pelo RH ou Coordenação da sua unidade (${state.setorNome.isNotEmpty ? state.setorNome : 'selecionada'}).',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: _textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFBBDEFB)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: _primaryBlue, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Assim que seu coordenador ou RH aprovar, seu acesso institucional estará liberado.',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: _primaryBlue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(dialogCtx).pop();
                context.go(AppRoutes.login);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'IR PARA O LOGIN',
                style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<RegisterState>(registerNotifierProvider, (_, next) {
      if (next is RegisterSuccess) {
        _showSuccessDialog(next);
      } else if (next is RegisterError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Expanded(child: Text(next.message)),
              ],
            ),
            backgroundColor: _errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    });

    final registerState = ref.watch(registerNotifierProvider);
    final isLoading = registerState is RegisterLoading;
    final unitsAsync = ref.watch(unitsProvider);
    final sectorsAsync = ref.watch(sectorsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _primaryBlue, size: 20),
          onPressed: () => context.go(AppRoutes.login),
          tooltip: 'Voltar ao Login',
        ),
        title: const Text(
          'Auto-Cadastro SUS',
          style: TextStyle(
            color: _textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const LoginLogo(),
                    const SizedBox(height: 16),

                    // ─── Card Formulário ────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _borderColor, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Primeiro Acesso ao Sistema',
                              style: TextStyle(
                                color: _textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Preencha seus dados funcionais para solicitar aprovação na sua unidade hospitalar.',
                              style: TextStyle(
                                color: _textSecondary,
                                fontSize: 12.5,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 18),

                            // Nome Completo
                            TextFormField(
                              controller: _nomeCtrl,
                              focusNode: _nomeFocus,
                              textInputAction: TextInputAction.next,
                              enabled: !isLoading,
                              style: const TextStyle(color: _textPrimary, fontSize: 14),
                              onFieldSubmitted: (_) =>
                                  FocusScope.of(context).requestFocus(_emailFocus),
                              decoration: _inputDecoration(
                                label: 'Nome Completo *',
                                hint: 'Ex: Ricardo Silva',
                                icon: Icons.person_outline_rounded,
                              ),
                              validator: (v) {
                                if (v == null || v.trim().length < 3) {
                                  return 'Informe seu nome completo.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),

                            // E-mail Institucional
                            TextFormField(
                              controller: _emailCtrl,
                              focusNode: _emailFocus,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              enabled: !isLoading,
                              style: const TextStyle(color: _textPrimary, fontSize: 14),
                              onFieldSubmitted: (_) =>
                                  FocusScope.of(context).requestFocus(_matriculaFocus),
                              decoration: _inputDecoration(
                                label: 'E-mail Institucional / Profissional *',
                                hint: 'seu.email@conectasaude.dev',
                                icon: Icons.mail_outline_rounded,
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Informe seu e-mail.';
                                }
                                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(v.trim())) {
                                  return 'E-mail com formato inválido.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),

                            // Matrícula SUS (Opcional)
                            TextFormField(
                              controller: _matriculaCtrl,
                              focusNode: _matriculaFocus,
                              textInputAction: TextInputAction.next,
                              enabled: !isLoading,
                              style: const TextStyle(color: _textPrimary, fontSize: 14),
                              decoration: _inputDecoration(
                                label: 'Matrícula / Registro SUS (opcional)',
                                hint: 'Ex: 245.890-1',
                                icon: Icons.badge_outlined,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Unidade Hospitalar / Hospital (Dropdown)
                            unitsAsync.when(
                              loading: () => const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                              error: (_, __) => _buildUnitDropdown(_fallbackUnits, isLoading),
                              data: (units) => _buildUnitDropdown(
                                units.isNotEmpty ? units : _fallbackUnits,
                                isLoading,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Setor de Lotação (Dropdown)
                            sectorsAsync.when(
                              loading: () => const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                              error: (_, __) => _buildSectorDropdown(_fallbackSectors, isLoading),
                              data: (sectors) => _buildSectorDropdown(
                                sectors.isNotEmpty ? sectors : _fallbackSectors,
                                isLoading,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Cargo / Função Padronizado (SUS CBO)
                            _buildRoleSelector(isLoading),

                            if (_isCustomRole) ...[
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _cargoCustomCtrl,
                                focusNode: _cargoCustomFocus,
                                textInputAction: TextInputAction.next,
                                enabled: !isLoading,
                                style: const TextStyle(color: _textPrimary, fontSize: 14),
                                decoration: _inputDecoration(
                                  label: 'Especifique o seu Cargo / Função *',
                                  hint: 'Digite seu cargo conforme contratação',
                                  icon: Icons.edit_outlined,
                                ),
                                validator: (v) {
                                  if (_isCustomRole && (v == null || v.trim().length < 2)) {
                                    return 'Especifique o cargo.';
                                  }
                                  return null;
                                },
                              ),
                            ],
                            const SizedBox(height: 16),

                            // ─── Seção Horário de Trabalho / Plantão ────────────
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: _borderColor),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(Icons.schedule_rounded, size: 18, color: _primaryBlue),
                                      SizedBox(width: 8),
                                      Text(
                                        'Horário de Trabalho / Plantão',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: _textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Define seu status "Em Serviço" e silenciamento de notificações fora da jornada.',
                                    style: TextStyle(fontSize: 11.5, color: _textSecondary),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildTimePickerField(
                                          label: 'Entrada',
                                          time: _jornadaInicio,
                                          onSelected: (t) => setState(() => _jornadaInicio = t),
                                          enabled: !isLoading,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: _buildTimePickerField(
                                          label: 'Saída',
                                          time: _jornadaFim,
                                          onSelected: (t) => setState(() => _jornadaFim = t),
                                          enabled: !isLoading,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Senha
                            TextFormField(
                              controller: _passCtrl,
                              focusNode: _passFocus,
                              obscureText: _obscurePass,
                              textInputAction: TextInputAction.next,
                              enabled: !isLoading,
                              style: const TextStyle(color: _textPrimary, fontSize: 14),
                              onFieldSubmitted: (_) =>
                                  FocusScope.of(context).requestFocus(_confirmPassFocus),
                              decoration: _inputDecoration(
                                label: 'Senha (mínimo 8 caracteres) *',
                                hint: 'Crie uma senha segura',
                                icon: Icons.lock_outline_rounded,
                                suffix: IconButton(
                                  icon: Icon(
                                    _obscurePass
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    size: 20,
                                    color: _textSecondary,
                                  ),
                                  onPressed: () =>
                                      setState(() => _obscurePass = !_obscurePass),
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.length < 8) {
                                  return 'A senha deve ter ao menos 8 caracteres.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),

                            // Confirmar Senha
                            TextFormField(
                              controller: _confirmPassCtrl,
                              focusNode: _confirmPassFocus,
                              obscureText: _obscureConfirm,
                              textInputAction: TextInputAction.done,
                              enabled: !isLoading,
                              style: const TextStyle(color: _textPrimary, fontSize: 14),
                              onFieldSubmitted: (_) => _submit(),
                              decoration: _inputDecoration(
                                label: 'Confirmar Senha *',
                                hint: 'Repita sua senha',
                                icon: Icons.lock_clock_outlined,
                                suffix: IconButton(
                                  icon: Icon(
                                    _obscureConfirm
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    size: 20,
                                    color: _textSecondary,
                                  ),
                                  onPressed: () =>
                                      setState(() => _obscureConfirm = !_obscureConfirm),
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'Confirme sua senha.';
                                }
                                if (v != _passCtrl.text) {
                                  return 'As senhas não coincidem.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),

                            // Botão Enviar
                            SizedBox(
                              height: 48,
                              child: ElevatedButton(
                                onPressed: isLoading ? null : _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _primaryBlue,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor:
                                      _primaryBlue.withValues(alpha: 0.65),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: isLoading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.2,
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                              Colors.white),
                                        ),
                                      )
                                    : const Text(
                                        'SOLICITAR CADASTRO',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.8,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Voltar ao Login
                            Center(
                              child: TextButton.icon(
                                onPressed: isLoading ? null : () => context.go(AppRoutes.login),
                                icon: const Icon(Icons.arrow_back, size: 16),
                                label: const Text('Já possui conta? Faça login'),
                                style: TextButton.styleFrom(
                                  foregroundColor: _primaryBlue,
                                  textStyle: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Rodapé
                    Text(
                      'Conecta Saúde • SUS © ${DateTime.now().year}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _textSecondary.withValues(alpha: 0.7),
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUnitDropdown(List<HospitalUnitEntity> units, bool isLoading) {
    return DropdownButtonFormField<String>(
      initialValue: _selectedUnitId ?? (units.isNotEmpty ? units.first.id : null),
      isExpanded: true,
      dropdownColor: Colors.white,
      style: const TextStyle(
        fontSize: 13.5,
        color: _textPrimary,
        fontWeight: FontWeight.w500,
      ),
      icon: const Icon(Icons.arrow_drop_down, color: _primaryBlue),
      decoration: _inputDecoration(
        label: 'Unidade Hospitalar / Hospital *',
        hint: 'Selecione o hospital',
        icon: Icons.domain_rounded,
      ),
      items: units.map((u) {
        return DropdownMenuItem<String>(
          value: u.id,
          child: Text(
            u.sigla != null ? '${u.nome} (${u.sigla})' : u.nome,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13.5,
              color: Color(0xFF263238),
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList(),
      onChanged: isLoading
          ? null
          : (val) {
              setState(() => _selectedUnitId = val);
            },
    );
  }

  Widget _buildSectorDropdown(List<SectorEntity> sectors, bool isLoading) {
    return DropdownButtonFormField<String>(
      initialValue: _selectedSectorId,
      isExpanded: true,
      dropdownColor: Colors.white,
      style: const TextStyle(
        fontSize: 13.5,
        color: _textPrimary,
        fontWeight: FontWeight.w500,
      ),
      icon: const Icon(Icons.arrow_drop_down, color: _primaryBlue),
      decoration: _inputDecoration(
        label: 'Setor de Lotação *',
        hint: 'Selecione seu setor',
        icon: Icons.local_hospital_outlined,
      ),
      items: sectors.map((s) {
        return DropdownMenuItem<String>(
          value: s.id,
          child: Text(
            s.nome,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13.5,
              color: Color(0xFF263238),
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList(),
      onChanged: isLoading
          ? null
          : (val) {
              setState(() => _selectedSectorId = val);
            },
      validator: (v) {
        if (v == null || v.isEmpty) return 'Selecione seu setor.';
        return null;
      },
    );
  }

  Widget _buildRoleSelector(bool isLoading) {
    final allRolesWithOther = [...kAllHospitalRoles, kOtherRoleOption];

    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return allRolesWithOther;
        }
        return allRolesWithOther.where((role) =>
            role.toLowerCase().contains(textEditingValue.text.toLowerCase()));
      },
      onSelected: (String selection) {
        setState(() {
          _selectedRole = selection;
          _isCustomRole = (selection == kOtherRoleOption);
        });
      },
      fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
        return TextFormField(
          controller: textEditingController,
          focusNode: focusNode,
          enabled: !isLoading,
          style: const TextStyle(color: _textPrimary, fontSize: 14),
          decoration: _inputDecoration(
            label: 'Cargo / Função na Unidade (SUS) *',
            hint: 'Digite ou selecione seu cargo...',
            icon: Icons.work_outline_rounded,
            suffix: const Icon(Icons.search, size: 20, color: _textSecondary),
          ),
          onChanged: (val) {
            setState(() {
              _selectedRole = val;
              _isCustomRole = (val == kOtherRoleOption);
            });
          },
          validator: (v) {
            if (v == null || v.trim().isEmpty) {
              return 'Selecione ou informe seu cargo.';
            }
            return null;
          },
        );
      },
    );
  }

  Widget _buildTimePickerField({
    required String label,
    required String time,
    required ValueChanged<String> onSelected,
    required bool enabled,
  }) {
    return InkWell(
      onTap: enabled
          ? () async {
              final parts = time.split(':').map((e) => int.tryParse(e) ?? 0).toList();
              final initial = TimeOfDay(
                hour: parts.isNotEmpty ? parts[0] : 7,
                minute: parts.length > 1 ? parts[1] : 0,
              );
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
                onSelected('$h:$m');
              }
            }
          : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _borderColor),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 11, color: _textSecondary),
                ),
                const SizedBox(height: 2),
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary,
                  ),
                ),
              ],
            ),
            const Icon(Icons.access_time_rounded, size: 18, color: _primaryBlue),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(color: _textSecondary, fontSize: 13.5),
      hintStyle: TextStyle(color: _textSecondary.withValues(alpha: 0.6), fontSize: 13.5),
      prefixIcon: Icon(icon, size: 20, color: _textSecondary),
      suffixIcon: suffix,
      filled: true,
      fillColor: _inputFillColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _primaryBlue, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _errorColor),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _errorColor, width: 1.8),
      ),
    );
  }

  static const List<HospitalUnitEntity> _fallbackUnits = [
    HospitalUnitEntity(
      id: 'unit-chc-centro',
      nome: 'Complexo Hospitalar Carioca (Central)',
      sigla: 'CHC-Centro',
    ),
    HospitalUnitEntity(
      id: 'unit-hmzs',
      nome: 'Hospital Municipal Zona Sul',
      sigla: 'HMZS',
    ),
    HospitalUnitEntity(
      id: 'unit-upa24h',
      nome: 'UPA 24h Regional',
      sigla: 'UPA-24H',
    ),
  ];

  static const List<SectorEntity> _fallbackSectors = [
    SectorEntity(
      id: 'sec-cco',
      nome: 'Centro Carioca do Olho (CCO)',
      ativo: true,
    ),
    SectorEntity(
      id: 'sec-ccdti',
      nome: 'Centro Carioca de Diagnóstico e Tratamento por Imagem (CCDTI)',
      ativo: true,
    ),
    SectorEntity(
      id: 'sec-cce',
      nome: 'Centro Carioca de Especialidades (CCE)',
      ativo: true,
    ),
    SectorEntity(
      id: 'sec-direcao',
      nome: 'Direção Geral',
      ativo: true,
    ),
  ];
}
