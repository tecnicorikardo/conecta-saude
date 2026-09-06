import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../sectors/presentation/providers/sectors_provider.dart';
import '../providers/employees_provider.dart';

class EmployeeFormDialog extends ConsumerStatefulWidget {
  final UserEntity? user;

  const EmployeeFormDialog({super.key, this.user});

  @override
  ConsumerState<EmployeeFormDialog> createState() => _EmployeeFormDialogState();
}

class _EmployeeFormDialogState extends ConsumerState<EmployeeFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomeCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _cargoCtrl;
  late final TextEditingController _passCtrl;
  String? _selectedSectorId;
  int _hierarquiaNivel = 4;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final u = widget.user;
    _nomeCtrl = TextEditingController(text: u?.nome ?? '');
    _emailCtrl = TextEditingController(text: u?.email ?? '');
    _cargoCtrl = TextEditingController(text: u?.cargo ?? '');
    _passCtrl = TextEditingController();
    _selectedSectorId = u?.setorId;
    _hierarquiaNivel = u?.hierarquiaNivel ?? 4;
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _emailCtrl.dispose();
    _cargoCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSectorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione um setor.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (widget.user != null) {
        await ref.read(employeesProvider.notifier).updateUser(
              id: widget.user!.id,
              nome: _nomeCtrl.text.trim(),
              cargo: _cargoCtrl.text.trim(),
              hierarquiaNivel: _hierarquiaNivel,
              setorId: _selectedSectorId!,
            );
      } else {
        await ref.read(employeesProvider.notifier).createUser(
              nome: _nomeCtrl.text.trim(),
              email: _emailCtrl.text.trim(),
              password: _passCtrl.text.trim(),
              cargo: _cargoCtrl.text.trim(),
              hierarquiaNivel: _hierarquiaNivel,
              setorId: _selectedSectorId!,
            );
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao salvar colaborador.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sectorsAsync = ref.watch(sectorsProvider);
    final isEditing = widget.user != null;

    return AlertDialog(
      title: Text(isEditing ? 'Editar Colaborador' : 'Novo Colaborador'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nomeCtrl,
                decoration: const InputDecoration(labelText: 'Nome Completo *'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe o nome' : null,
              ),
              const SizedBox(height: 12),
              if (!isEditing) ...[
                TextFormField(
                  controller: _emailCtrl,
                  decoration: const InputDecoration(labelText: 'E-mail *'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => (v == null || !v.contains('@')) ? 'E-mail inválido' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passCtrl,
                  decoration: const InputDecoration(labelText: 'Senha inicial *'),
                  obscureText: true,
                  validator: (v) => (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
                ),
                const SizedBox(height: 12),
              ],
              TextFormField(
                controller: _cargoCtrl,
                decoration: const InputDecoration(labelText: 'Cargo *'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe o cargo' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: _hierarquiaNivel,
                decoration: const InputDecoration(labelText: 'Nível Hierárquico *'),
                items: const [
                  DropdownMenuItem(value: 1, child: Text('1 — Direção Geral')),
                  DropdownMenuItem(value: 2, child: Text('2 — Coordenação')),
                  DropdownMenuItem(value: 3, child: Text('3 — Supervisão')),
                  DropdownMenuItem(value: 4, child: Text('4 — Funcionário')),
                ],
                onChanged: (v) => setState(() => _hierarquiaNivel = v ?? 4),
              ),
              const SizedBox(height: 12),
              sectorsAsync.when(
                data: (sectors) => DropdownButtonFormField<String>(
                  value: _selectedSectorId,
                  decoration: const InputDecoration(labelText: 'Setor / Unidade *'),
                  items: sectors
                      .map((s) => DropdownMenuItem(value: s.id, child: Text(s.nome)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedSectorId = v),
                ),
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const Text('Erro ao carregar setores'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text(isEditing ? 'Salvar' : 'Criar'),
        ),
      ],
    );
  }
}
