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

class _EmployeesPageState extends ConsumerState<EmployeesPage>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  late final TabController _tabController;
  int _currentTabIndex = 0;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index != _currentTabIndex) {
        setState(() {
          _currentTabIndex = _tabController.index;
        });
      }
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _tabController.dispose();
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
    final pendingAsync = ref.watch(pendingApprovalsProvider);
    final pendingCount = pendingAsync.valueOrNull?.length ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestão de Pessoal'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
          tabs: [
            const Tab(
              icon: Icon(Icons.people_alt_outlined, size: 20),
              text: 'Colaboradores',
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.how_to_reg_outlined, size: 20),
                  const SizedBox(width: 8),
                  const Text('Aprovações'),
                  if (pendingCount > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF5252),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$pendingCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Atualizar dados',
            onPressed: () {
              ref.read(employeesProvider.notifier).fetchEmployees(isRefresh: true);
              ref.read(pendingApprovalsProvider.notifier).fetchPending();
            },
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
      body: TabBarView(
        controller: _tabController,
        children: [
          // ─── ABA 1: Colaboradores Ativos ────────────────────────────────
          ExcludeSemantics(
            excluding: _currentTabIndex != 0,
            child: Column(
              children: [
                // Barra de Pesquisa
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

                // Barra de Filtros Rápidos
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Row(
                    children: [
                      _FilterChipButton(
                        label: state.selectedHierarquia == null
                            ? 'Nível: Todos'
                            : 'Nível: ${_getHierarquiaLabel(state.selectedHierarquia!)}',
                        isSelected: state.selectedHierarquia != null,
                        onTap: () => _showHierarquiaFilterMenu(context),
                      ),
                      const SizedBox(width: 8),

                      if (state.isDirecao) ...[
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
                      ],

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

                // Lista
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
          ),

          // ─── ABA 2: Aprovações Pendentes ────────────────────────────────
          ExcludeSemantics(
            excluding: _currentTabIndex != 1,
            child: _PendingApprovalsTab(pendingAsync: pendingAsync),
          ),
        ],
      ),
    );
  }

  Widget _buildListContent(BuildContext context, EmployeesState state) {
    final visibleList = state.visibleUsers;

    if (state.isLoading && visibleList.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.errorMessage != null && visibleList.isEmpty) {
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

    if (visibleList.isEmpty) {
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
      itemCount: visibleList.length + (state.isLoadingMore ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        if (index == visibleList.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          );
        }

        final user = visibleList[index];
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

// ─── ABA DE APROVAÇÕES PENDENTES ──────────────────────────────────────────────
class _PendingApprovalsTab extends ConsumerWidget {
  final AsyncValue<List<UserEntity>> pendingAsync;

  const _PendingApprovalsTab({required this.pendingAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () =>
          ref.read(pendingApprovalsProvider.notifier).fetchPending(),
      child: pendingAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                const SizedBox(height: 12),
                Text(
                  'Erro ao carregar aprovações pendentes: $err',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tentar novamente'),
                  onPressed: () =>
                      ref.read(pendingApprovalsProvider.notifier).fetchPending(),
                ),
              ],
            ),
          ),
        ),
        data: (pendingList) {
          if (pendingList.isEmpty) {
            return ListView(
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.verified_user_outlined,
                          size: 56,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Nenhuma aprovação pendente',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.neutral800,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          'Todos os servidores da sua unidade estão aprovados e ativos no Conecta Saúde.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.neutral600,
                                height: 1.3,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            itemCount: pendingList.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              if (index == 0) {
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFFE082)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Color(0xFFF57F17), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${pendingList.length} ${pendingList.length == 1 ? 'solicitação aguardando' : 'solicitações aguardando'} validação pelo RH/Coordenação.',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFE65100),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              final user = pendingList[index - 1];
              return _PendingUserCard(user: user);
            },
          );
        },
      ),
    );
  }
}

class _PendingUserCard extends ConsumerStatefulWidget {
  final UserEntity user;

  const _PendingUserCard({required this.user});

  @override
  ConsumerState<_PendingUserCard> createState() => _PendingUserCardState();
}

class _PendingUserCardState extends ConsumerState<_PendingUserCard> {
  bool _isProcessing = false;

  Future<void> _approve() async {
    setState(() => _isProcessing = true);
    final success = await ref
        .read(pendingApprovalsProvider.notifier)
        .approve(widget.user.id);
    if (!mounted) return;
    setState(() => _isProcessing = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Cadastro de ${widget.user.nome} aprovado com sucesso!'),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Falha ao aprovar cadastro.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _confirmReject() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rejeitar Solicitação?'),
        content: Text(
          'Deseja realmente recusar e cancelar a solicitação de auto-cadastro de ${widget.user.nome}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCELAR'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('REJEITAR', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isProcessing = true);
    final success =
        await ref.read(pendingApprovalsProvider.notifier).reject(widget.user.id);
    if (!mounted) return;
    setState(() => _isProcessing = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Solicitação de ${widget.user.nome} foi rejeitada.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final initials = widget.user.nome.trim().isNotEmpty
        ? widget.user.nome
            .trim()
            .split(' ')
            .take(2)
            .map((e) => e.isNotEmpty ? e[0].toUpperCase() : '')
            .join()
        : 'U';

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFFFFA000),
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
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
                              widget.user.nome,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF263238),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF3E0),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFFFB74D)),
                            ),
                            child: const Text(
                              'PENDENTE',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFE65100),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        widget.user.cargo,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF455A64),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.user.email,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF78909C),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // Detalhes extras: Unidade e Matrícula
            Row(
              children: [
                const Icon(Icons.local_hospital_outlined, size: 16, color: AppColors.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    widget.user.setorNome.isNotEmpty
                        ? widget.user.setorNome
                        : 'Unidade não informada',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF37474F),
                    ),
                  ),
                ),
              ],
            ),
            if (widget.user.matricula != null && widget.user.matricula!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.badge_outlined, size: 16, color: Color(0xFF78909C)),
                  const SizedBox(width: 6),
                  Text(
                    'Matrícula SUS: ${widget.user.matricula}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF546E7A)),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 14),

            // Botões de Ação
            if (_isProcessing)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: OutlinedButton(
                      onPressed: _confirmReject,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        '✕ Rejeitar',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _approve,
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      label: const Text(
                        'APROVAR ACESSO',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
