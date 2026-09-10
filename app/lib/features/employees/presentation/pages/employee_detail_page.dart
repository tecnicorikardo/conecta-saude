import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/http_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/hierarchy_badge.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/data/models/user_model.dart';
import '../providers/employees_provider.dart';

class EmployeeDetailPage extends ConsumerStatefulWidget {
  final String employeeId;

  const EmployeeDetailPage({super.key, required this.employeeId});

  @override
  ConsumerState<EmployeeDetailPage> createState() => _EmployeeDetailPageState();
}

class _EmployeeDetailPageState extends ConsumerState<EmployeeDetailPage> {
  UserEntity? _fetchedUser;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUserIfNeeded();
  }

  Future<void> _loadUserIfNeeded() async {
    final state = ref.read(employeesProvider);
    final existing = state.users.where((u) => u.id == widget.employeeId).firstOrNull;
    if (existing != null) {
      setState(() => _fetchedUser = existing);
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final resp = await HttpService.instance.get('/users/${widget.employeeId}');
      if (resp.data['success'] == true && resp.data['data'] != null) {
        if (mounted) {
          setState(() {
            _fetchedUser = UserModel.fromJson(resp.data['data'] as Map<String, dynamic>);
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _error = 'Colaborador não encontrado.';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Não foi possível carregar os dados do colaborador.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _fetchedUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Perfil do Profissional'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.person_off_outlined, size: 54, color: AppColors.textSecondary),
                      const SizedBox(height: 12),
                      Text(_error!, style: const TextStyle(fontSize: 16, color: AppColors.textSecondary)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadUserIfNeeded,
                        child: const Text('Tentar Novamente'),
                      ),
                    ],
                  ),
                )
              : user == null
                  ? const Center(child: Text('Colaborador não encontrado.'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Card Principal
                          Container(
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
                                AppAvatar(
                                  name: user.nome,
                                  fotoUrl: user.fotoUrl,
                                  size: 88,
                                  hierarquiaNivel: user.hierarquiaNivel,
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  user.nome,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.neutral900,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  user.email,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.neutral600,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  alignment: WrapAlignment.center,
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    HierarchyBadge(hierarquiaNivel: user.hierarquiaNivel),
                                    StatusBadge(ativo: user.ativo),
                                    // Status de Plantão / Jornada em Tempo Real
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
                                              color: user.workStatusColor,
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Card Informações Profissionais
                          Container(
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
                                  'DADOS INSTITUCIONAIS',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: const CircleAvatar(
                                    backgroundColor: Color(0xFFE3F2FD),
                                    child: Icon(Icons.work_outline, color: AppColors.primary),
                                  ),
                                  title: const Text('Cargo / Função', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                  subtitle: Text(user.cargo, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.neutral900)),
                                ),
                                const Divider(height: 16, color: Color(0xFFF1F5F9)),
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: const CircleAvatar(
                                    backgroundColor: Color(0xFFE8F5E9),
                                    child: Icon(Icons.domain_rounded, color: AppColors.success),
                                  ),
                                  title: const Text('Hospital / Unidade', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                  subtitle: Text(
                                    user.unitNome != null && user.unitNome!.isNotEmpty
                                        ? '${user.unitNome!}${user.unitSigla != null ? ' (${user.unitSigla!})' : ''}'
                                        : 'Complexo Hospitalar Carioca (Central)',
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.neutral900),
                                  ),
                                ),
                                const Divider(height: 16, color: Color(0xFFF1F5F9)),
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: const CircleAvatar(
                                    backgroundColor: Color(0xFFEDE7F6),
                                    child: Icon(Icons.local_hospital_outlined, color: Color(0xFF5E35B1)),
                                  ),
                                  title: const Text('Setor de Lotação', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                  subtitle: Text(user.setorNome, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.neutral900)),
                                ),
                                const Divider(height: 16, color: Color(0xFFF1F5F9)),
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: const CircleAvatar(
                                    backgroundColor: Color(0xFFE0F2F1),
                                    child: Icon(Icons.schedule_rounded, color: Color(0xFF00897B)),
                                  ),
                                  title: const Text('Escala & Horário de Trabalho', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                  subtitle: Text(
                                    '${user.jornadaInicio} às ${user.jornadaFim} (${user.jornadaDias.toUpperCase()})',
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.neutral900),
                                  ),
                                ),
                                if (user.matricula != null && user.matricula!.isNotEmpty) ...[
                                  const Divider(height: 16, color: Color(0xFFF1F5F9)),
                                  ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: const CircleAvatar(
                                      backgroundColor: Color(0xFFFFF3E0),
                                      child: Icon(Icons.badge_outlined, color: Color(0xFFE65100)),
                                    ),
                                    title: const Text('Matrícula / Registro SUS', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                    subtitle: Text(user.matricula!, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.neutral900)),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }
}
