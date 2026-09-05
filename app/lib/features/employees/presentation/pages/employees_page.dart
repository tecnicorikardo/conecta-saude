import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/hierarchy_badge.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/current_user_provider.dart';
import '../../../sectors/presentation/providers/sectors_provider.dart';
import '../providers/employees_provider.dart';
import '../widgets/employee_form_dialog.dart';

/// Página de listagem de funcionários com filtros, busca e paginação.
class EmployeesPage extends ConsumerStatefulWidget {
  const EmployeesPage({super.key});

  @override
  ConsumerState<EmployeesPage> createState() => _EmployeesPageState();
}

class _EmployeesPageState extends ConsumerState<EmployeesPage> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(employeesProvider.notifier).loadMore();
    }
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      ref.read(employeesProvider.notifier).setSearchQuery(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(employeesProvider);
    final sectorsAsync = ref.watch(sectorsProvider);
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final isDirecao = currentUser?.isDirecao ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Funcionários'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Atualizar lista',
            onPressed: () =>
                ref.read(employeesProvider.notifier).fetchEmployees(isRefresh: true),
          ),
        ],
      ),
      floatingActionButton: isDirecao
          ? FloatingActionButton.extended(
              onPressed: () {
                showDialog<UserEntity>(
                  context: context,
                  builder: (ctx) => const EmployeeFormDialog(),
                );
              },
              icon: const Icon(Icons.person_add_rounded),
              label: const Text('Novo'),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            )
          : null,
      body: Column(
        children: [
          // ─── Barra de Pesquisa ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Buscar por nome, cargo ou e-mail...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(employeesProvider.notifier).setSearchQuery('');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                filled: true,
                fillColor: Theme.of(context).cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.outlineVariant),
                ),
              ),
            ),
          ),

          // ─── Barra de Filtros Rápidos ────────────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                // Filtro por Nível Hierárquico
                _FilterChipButton(
                  label: state.selectedHierarquia == null
                      ? 'Nível: Todos'
                      : 'Nível: ${_getHierarquiaLabel(state.selectedHierarquia!)}',
                  isSelected: state.selectedHierarquia != null,
                  onTap: () => _showHierarquiaFilterMenu(context),
                ),
                const SizedBox(width: 8),

                // Filtro por Setor
                sectorsAsync.when(
                  data: (sectors) {
                    final selectedSector = sectors
                        .where((s) => s.id == state.selectedSetorId)
                        .firstOrNull;
                    return _FilterChipButton(
                      label: selectedSector == null
                          ? 'Setor: Todos'
                          : 'Setor: ${selectedSector.nome}',
                      isSelected: state.selectedSetorId != null,
                      onTap: () => _showSetorFilterMenu(context, sectors),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(width: 8),

                // Filtro Ativos / Inativos
                _FilterChipButton(
                  label: state.selectedAtivo == null
                      ? 'Status: Todos'
                      : (state.selectedAtivo! ? 'Apenas Ativos' : 'Apenas Inativos'),
                  isSelected: state.selectedAtivo != null,
                  onTap: () {
                    if (state.selectedAtivo == null) {
                      ref.read(employeesProvider.notifier).setAtivoFilter(true);
                    } else if (state.selectedAtivo == true) {
                      ref.read(employeesProvider.notifier).setAtivoFilter(false);
                    } else {
                      ref.read(employeesProvider.notifier).setAtivoFilter(null);
                    }
                  },
                ),

                if (state.selectedHierarquia != null ||
                    state.selectedSetorId != null ||
                    state.selectedAtivo != null ||
                    state.searchQuery.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.error,
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.filter_alt_off, size: 16),
                    label: const Text('Limpar'),
                    onPressed: () {
                      _searchController.clear();
                      final notifier = ref.read(employeesProvider.notifier);
                      notifier.setSearchQuery('');
                      notifier.setHierarquiaFilter(null);
                      notifier.setSetorFilter(null);
                      notifier.setAtivoFilter(null);
                    },
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 6),

          // ─── Lista de Usuários ───────────────────────────────────────────
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref
                  .read(employeesProvider.notifier)
                  .fetchEmployees(isRefresh: true),
              child: _buildListContent(context, state),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListContent(BuildContext context, EmployeesState state) {
    if (state.isLoading && state.users.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.errorMessage != null && state.users.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              Text(
                state.errorMessage!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar novamente'),
                onPressed: () => ref
                    .read(employeesProvider.notifier)
                    .fetchEmployees(isRefresh: true),
              ),
            ],
          ),
        ),
      );
    }

    if (state.users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.people_outline_rounded,
              size: 56,
              color: AppColors.neutral500,
            ),
            const SizedBox(height: 14),
            Text(
              'Nenhum funcionário encontrado',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.neutral700,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              'Tente ajustar os filtros ou termos da busca.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.neutral500,
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: state.users.length + (state.isLoadingMore ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        if (index == state.users.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          );
        }

        final user = state.users[index];
        return _UserCard(
          user: user,
          onTap: () {
            context.push('/employees/${user.id}');
          },
        );
      },
    );
  }

  void _showHierarquiaFilterMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Filtrar por Nível Hierárquico',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                title: const Text('Todos os níveis'),
                onTap: () {
                  ref.read(employeesProvider.notifier).setHierarquiaFilter(null);
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: const Icon(Icons.workspace_premium_rounded,
                    color: AppColors.levelDirecao),
                title: const Text('1 — Direção'),
                onTap: () {
                  ref.read(employeesProvider.notifier).setHierarquiaFilter(1);
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: const Icon(Icons.shield_rounded,
                    color: AppColors.levelCoordenacao),
                title: const Text('2 — Coordenação'),
                onTap: () {
                  ref.read(employeesProvider.notifier).setHierarquiaFilter(2);
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: const Icon(Icons.supervisor_account_rounded,
                    color: AppColors.levelSupervisao),
                title: const Text('3 — Supervisão'),
                onTap: () {
                  ref.read(employeesProvider.notifier).setHierarquiaFilter(3);
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: const Icon(Icons.person_rounded,
                    color: AppColors.levelFuncionario),
                title: const Text('4 — Funcionário'),
                onTap: () {
                  ref.read(employeesProvider.notifier).setHierarquiaFilter(4);
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSetorFilterMenu(BuildContext context, List dynamicSectors) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Filtrar por Setor Hospitalar',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  children: [
                    ListTile(
                      title: const Text('Todos os setores'),
                      onTap: () {
                        ref.read(employeesProvider.notifier).setSetorFilter(null);
                        Navigator.pop(ctx);
                      },
                    ),
                    ...dynamicSectors.map(
                      (sector) => ListTile(
                        title: Text(sector.nome),
                        onTap: () {
                          ref
                              .read(employeesProvider.notifier)
                              .setSetorFilter(sector.id);
                          Navigator.pop(ctx);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getHierarquiaLabel(int nivel) {
    switch (nivel) {
      case 1:
        return 'Direção';
      case 2:
        return 'Coordenação';
      case 3:
        return 'Supervisão';
      case 4:
        return 'Funcionário';
      default:
        return '$nivel';
    }
  }
}

class _FilterChipButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChipButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      backgroundColor: Theme.of(context).cardColor,
      selectedColor: AppColors.primary.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        color: isSelected ? AppColors.primary : AppColors.neutral800,
      ),
      side: BorderSide(
        color: isSelected ? AppColors.primary : AppColors.outlineVariant,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}

class _UserCard extends StatelessWidget {
  final UserEntity user;
  final VoidCallback onTap;

  const _UserCard({
    required this.user,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final initials = user.nome.trim().isNotEmpty
        ? user.nome
            .trim()
            .split(' ')
            .take(2)
            .map((e) => e.isNotEmpty ? e[0].toUpperCase() : '')
            .join()
        : 'U';

    return Card(
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primary.withValues(alpha: 0.85),
                backgroundImage: user.fotoUrl != null && user.fotoUrl!.isNotEmpty
                    ? NetworkImage(user.fotoUrl!)
                    : null,
                child: user.fotoUrl == null || user.fotoUrl!.isEmpty
                    ? Text(
                        initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 14),

              // Informações
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            user.nome,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        StatusBadge(ativo: user.ativo),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      user.cargo,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.neutral700,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        HierarchyBadge(
                          nivel: user.hierarquiaNivel,
                          isSmall: true,
                        ),
                        if (user.setorNome.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              user.setorNome,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppColors.neutral600,
                                    fontSize: 11,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.neutral500),
            ],
          ),
        ),
      ),
    );
  }
}
