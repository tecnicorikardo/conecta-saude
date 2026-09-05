import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/hierarchy_badge.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/current_user_provider.dart';
import '../providers/employees_provider.dart';
import '../widgets/employee_form_dialog.dart';

/// Página de detalhes do funcionário com dados e ações administrativas.
class EmployeeDetailPage extends ConsumerStatefulWidget {
  final String employeeId;

  const EmployeeDetailPage({super.key, required this.employeeId});

  @override
  ConsumerState<EmployeeDetailPage> createState() => _EmployeeDetailPageState();
}

class _EmployeeDetailPageState extends ConsumerState<EmployeeDetailPage> {
  UserEntity? _user;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isStatusUpdating = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final repo = ref.read(employeesRepositoryProvider);
    final result = await repo.getUser(widget.employeeId);

    if (!mounted) return;

    result.fold(
      (failure) => setState(() {
        _isLoading = false;
        _errorMessage = failure.message;
      }),
      (user) => setState(() {
        _isLoading = false;
        _user = user;
      }),
    );
  }

  Future<void> _toggleStatus() async {
    if (_user == null) return;
    final newStatus = !_user!.ativo;
    final actionText = newStatus ? 'ativar' : 'desativar';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${newStatus ? 'Ativar' : 'Desativar'} Funcionário'),
        content: Text(
          'Deseja realmente $actionText o acesso de ${_user!.nome} ao sistema?\n\n'
          '${newStatus ? 'O funcionário voltará a ter acesso ao app.' : 'O usuário perderá acesso imediato e suas sessões ativas serão invalidadas.'}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: newStatus ? AppColors.success : AppColors.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(newStatus ? 'Confirmar Ativação' : 'Confirmar Desativação'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isStatusUpdating = true);

    final success = await ref
        .read(employeesProvider.notifier)
        .updateStatus(_user!.id, newStatus);

    if (!mounted) return;
    setState(() => _isStatusUpdating = false);

    if (success) {
      setState(() {
        _user = UserEntity(
          id: _user!.id,
          firebaseUid: _user!.firebaseUid,
          nome: _user!.nome,
          email: _user!.email,
          cargo: _user!.cargo,
          hierarquiaNivel: _user!.hierarquiaNivel,
          setorId: _user!.setorId,
          setorNome: _user!.setorNome,
          fotoUrl: _user!.fotoUrl,
          ativo: newStatus,
          criadoEm: _user!.criadoEm,
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newStatus
                ? 'Funcionário ativado com sucesso!'
                : 'Funcionário desativado com sucesso.',
          ),
          backgroundColor: newStatus ? AppColors.success : AppColors.warning,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível alterar o status do funcionário.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _openEditDialog() async {
    if (_user == null) return;
    final updated = await showDialog<UserEntity>(
      context: context,
      builder: (ctx) => EmployeeFormDialog(employeeToEdit: _user),
    );

    if (updated != null && mounted) {
      setState(() => _user = updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final isDirecao = currentUser?.isDirecao ?? false;
    final dateFormat = DateFormat("dd/MM/yyyy 'às' HH:mm", 'pt_BR');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes do Funcionário'),
        actions: [
          if (_user != null && isDirecao)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Editar funcionário',
              onPressed: _openEditDialog,
            ),
        ],
      ),
      body: _buildBody(context, isDirecao, dateFormat),
    );
  }

  Widget _buildBody(
    BuildContext context,
    bool isDirecao,
    DateFormat dateFormat,
  ) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              Text(_errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar novamente'),
                onPressed: _loadUser,
              ),
            ],
          ),
        ),
      );
    }

    final user = _user!;
    final initials = user.nome.trim().isNotEmpty
        ? user.nome
            .trim()
            .split(' ')
            .take(2)
            .map((e) => e.isNotEmpty ? e[0].toUpperCase() : '')
            .join()
        : 'U';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        children: [
          // ─── Header do Funcionário ──────────────────────────────────────
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 46,
                  backgroundColor: AppColors.primary,
                  backgroundImage: user.fotoUrl != null && user.fotoUrl!.isNotEmpty
                      ? NetworkImage(user.fotoUrl!)
                      : null,
                  child: user.fotoUrl == null || user.fotoUrl!.isEmpty
                      ? Text(
                          initials,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 14),
                Text(
                  user.nome,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.cargo,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.neutral700,
                      ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    HierarchyBadge(nivel: user.hierarquiaNivel),
                    StatusBadge(ativo: user.ativo),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ─── Dados Institucionais ─────────────────────────────────────────
          Card(
            elevation: 0,
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _DetailRow(
                  icon: Icons.email_outlined,
                  label: 'E-mail institucional',
                  value: user.email,
                ),
                const Divider(height: 1),
                _DetailRow(
                  icon: Icons.apartment_outlined,
                  label: 'Setor hospitalar',
                  value: user.setorNome.isNotEmpty ? user.setorNome : 'Não atribuído',
                ),
                const Divider(height: 1),
                _DetailRow(
                  icon: Icons.military_tech_outlined,
                  label: 'Nível hierárquico',
                  value: '${user.hierarquiaNivel} — ${user.hierarquiaNome}',
                ),
                const Divider(height: 1),
                _DetailRow(
                  icon: Icons.calendar_today_outlined,
                  label: 'Data de admissão / registro',
                  value: dateFormat.format(user.criadoEm),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ─── Ações Administrativas (apenas Direção) ───────────────────────
          if (isDirecao) ...[
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.edit_rounded),
                label: const Text(
                  'Editar Dados do Funcionário',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                onPressed: _openEditDialog,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor:
                      user.ativo ? AppColors.error : AppColors.success,
                  side: BorderSide(
                    color: user.ativo ? AppColors.error : AppColors.success,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: _isStatusUpdating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        user.ativo
                            ? Icons.person_off_outlined
                            : Icons.person_add_alt_1_outlined,
                      ),
                label: Text(
                  user.ativo
                      ? 'Desativar Funcionário'
                      : 'Reativar Funcionário',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                onPressed: _isStatusUpdating ? null : _toggleStatus,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.neutral600,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
