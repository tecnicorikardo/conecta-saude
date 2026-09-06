import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/hierarchy_badge.dart';
import '../../../../core/widgets/status_badge.dart';
import '../providers/employees_provider.dart';

class EmployeeDetailPage extends ConsumerWidget {
  final String employeeId;

  const EmployeeDetailPage({super.key, required this.employeeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(employeesProvider);
    final user = state.users.where((u) => u.id == employeeId).firstOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes do Colaborador')),
      body: user == null
          ? const Center(child: Text('Colaborador não encontrado.'))
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: AppColors.primary,
                      child: Text(
                        user.nome.isNotEmpty ? user.nome[0].toUpperCase() : '?',
                        style: const TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(child: Text(user.nome, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
                  const SizedBox(height: 4),
                  Center(child: Text(user.email, style: const TextStyle(color: AppColors.textSecondary))),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      HierarchyBadge(hierarquiaNivel: user.hierarquiaNivel),
                      const SizedBox(width: 8),
                      StatusBadge(ativo: user.ativo),
                    ],
                  ),
                  const Divider(height: 32),
                  ListTile(
                    leading: const Icon(Icons.work_outline),
                    title: const Text('Cargo'),
                    subtitle: Text(user.cargo),
                  ),
                  ListTile(
                    leading: const Icon(Icons.apartment_outlined),
                    title: const Text('Setor / Unidade'),
                    subtitle: Text(user.setorNome),
                  ),
                ],
              ),
            ),
    );
  }
}
