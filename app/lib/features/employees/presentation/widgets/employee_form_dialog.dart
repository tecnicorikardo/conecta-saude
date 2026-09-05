import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../sectors/presentation/providers/sectors_provider.dart';
import '../providers/employees_provider.dart';

/// Modal dialog para criação ou edição de funcionário.
class EmployeeFormDialog extends ConsumerStatefulWidget {
  final UserEntity? employeeToEdit;

  const EmployeeFormDialog({super.key, this.employeeToEdit});

  @override
  ConsumerState<EmployeeFormDialog> createState() => _EmployeeFormDialogState();
}

class _EmployeeFormDialogState extends ConsumerState<EmployeeFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nomeController;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _cargoController;

  int _selectedHierarquia = 4;
  String? _selectedSetorId;
  bool _isLoading = false;
  bool _obscurePassword = true;

  bool get isEditing => widget.employeeToEdit != null;

  @override
  void initState() {
    super.initState();
    final emp = widget.employeeToEdit;
    _nomeController = TextEditingController(text: emp?.nome ?? '');
    _emailController = TextEditingController(text: emp?.email ?? '');
    _passwordController = TextEditingController();
    _cargoController = TextEditingController(text: emp?.cargo ?? '');
    _selectedHierarquia = emp?.hierarquiaNivel ?? 4;
    _selectedSetorId = emp?.setorId;
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _cargoController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSetorId == null || _selectedSetorId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecione um setor.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    final repo = ref.read(employeesRepositoryProvider);

    if (isEditing) {
      final result = await repo.updateUser(
        id: widget.employeeToEdit!.id,
        nome: _nomeController.text.trim(),
        cargo: _cargoController.text.trim(),
        hierarquiaNivel: _selectedHierarquia,
        setorId: _selectedSetorId,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      result.fold(
        (failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(failure.message),
              backgroundColor: AppColors.error,
            ),
          );
        },
        (updatedUser) {
          ref.read(employeesProvider.notifier).updateOrAddUserLocally(updatedUser);
          Navigator.of(context).pop(updatedUser);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Funcionário atualizado com sucesso!'),
              backgroundColor: AppColors.success,
            ),
          );
        },
      );
    } else {
      final result = await repo.createUser(
        nome: _nomeController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        cargo: _cargoController.text.trim(),
        hierarquiaNivel: _selectedHierarquia,
        setorId: _selectedSetorId!,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      result.fold(
        (failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(failure.message),
              backgroundColor: AppColors.error,
            ),
          );
        },
        (newUser) {
          ref.read(employeesProvider.notifier).updateOrAddUserLocally(newUser);
          Navigator.of(context).pop(newUser);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Funcionário cadastrado com sucesso!'),
              backgroundColor: AppColors.success,
            ),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sectorsAsync = ref.watch(sectorsProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ─── Título ────────────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEditing ? 'Editar Funcionário' : 'Novo Funcionário',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ─── Nome ──────────────────────────────────────────────────
                TextFormField(
                  controller: _nomeController,
                  decoration: const InputDecoration(
                    labelText: 'Nome completo *',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Informe o nome completo.';
                    }
                    if (v.trim().length < 2) {
                      return 'Nome deve ter ao menos 2 caracteres.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // ─── E-mail (somente leitura se editando) ───────────────────
                TextFormField(
                  controller: _emailController,
                  enabled: !isEditing,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'E-mail institucional *',
                    prefixIcon: const Icon(Icons.email_outlined),
                    helperText: isEditing
                        ? 'O e-mail não pode ser alterado.'
                        : null,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Informe o e-mail.';
                    }
                    if (!v.contains('@')) {
                      return 'Informe um e-mail válido.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // ─── Senha (somente ao criar) ──────────────────────────────
                if (!isEditing) ...[
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Senha de acesso inicial *',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                      helperText: 'Mínimo de 8 caracteres.',
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return 'Informe uma senha provisória.';
                      }
                      if (v.length < 8) {
                        return 'A senha deve ter no mínimo 8 caracteres.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                ],

                // ─── Cargo ────────────────────────────────────────────────
                TextFormField(
                  controller: _cargoController,
                  decoration: const InputDecoration(
                    labelText: 'Cargo / Função *',
                    prefixIcon: Icon(Icons.work_outline),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Informe o cargo do funcionário.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // ─── Nível Hierárquico ─────────────────────────────────────
                DropdownButtonFormField<int>(
                  initialValue: _selectedHierarquia,
                  decoration: const InputDecoration(
                    labelText: 'Nível Hierárquico *',
                    prefixIcon: Icon(Icons.military_tech_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('1 — Direção')),
                    DropdownMenuItem(value: 2, child: Text('2 — Coordenação')),
                    DropdownMenuItem(value: 3, child: Text('3 — Supervisão')),
                    DropdownMenuItem(value: 4, child: Text('4 — Funcionário')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedHierarquia = val);
                  },
                ),
                const SizedBox(height: 14),

                // ─── Setor ─────────────────────────────────────────────────
                sectorsAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text(
                    'Erro ao carregar setores: $e',
                    style: const TextStyle(color: AppColors.error, fontSize: 12),
                  ),
                  data: (sectors) {
                    final validSectors = sectors.where((s) => s.ativo).toList();
                    final currentIdValid = validSectors.any((s) => s.id == _selectedSetorId);
                    final currentValue = currentIdValid ? _selectedSetorId : null;

                    return DropdownButtonFormField<String>(
                      initialValue: currentValue,
                      decoration: const InputDecoration(
                        labelText: 'Setor Hospitalar *',
                        prefixIcon: Icon(Icons.apartment_outlined),
                      ),
                      hint: const Text('Selecione o setor'),
                      items: validSectors
                          .map(
                            (s) => DropdownMenuItem(
                              value: s.id,
                              child: Text(s.nome),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedSetorId = val);
                      },
                      validator: (v) =>
                          v == null ? 'Selecione um setor hospitalar.' : null,
                    );
                  },
                ),
                const SizedBox(height: 24),

                // ─── Ações ────────────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: _isLoading ? null : _submit,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(isEditing ? 'Salvar Alterações' : 'Criar Funcionário'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
