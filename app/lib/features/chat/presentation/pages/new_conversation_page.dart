import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/conversation_model.dart';
import '../../data/repositories/conversation_repository.dart';
import '../providers/chat_provider.dart';
import '../widgets/conversation_avatar.dart';
import '../../domain/entities/conversation_entity.dart';

/// Tela que agrupa Nova Conversa (individual) e Novo Grupo em abas.
class NewConversationPage extends ConsumerStatefulWidget {
  const NewConversationPage({super.key});

  @override
  ConsumerState<NewConversationPage> createState() =>
      _NewConversationPageState();
}

class _NewConversationPageState
    extends ConsumerState<NewConversationPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nova Conversa'),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.person_outline), text: 'Individual'),
            Tab(icon: Icon(Icons.group_outlined), text: 'Grupo'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [
          _IndividualTab(),
          _GroupTab(),
        ],
      ),
    );
  }
}

// ─── Aba Individual ───────────────────────────────────────────────────────────
class _IndividualTab extends ConsumerStatefulWidget {
  const _IndividualTab();

  @override
  ConsumerState<_IndividualTab> createState() => _IndividualTabState();
}

class _IndividualTabState extends ConsumerState<_IndividualTab> {
  final _searchCtrl = TextEditingController();
  String? _loadingUserId;
  String _statusFilter = 'all'; // 'all', 'working', 'off'
  String _cargoFilterId = 'all';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _startConversation(
      BuildContext context, UserSummary user) async {
    // 1. Otimização Instantânea: Se a conversa individual já existe localmente, abre na hora (0ms delay)
    final allConvs = ref.read(conversationsProvider).valueOrNull ?? [];
    final existing = allConvs.cast<ConversationEntity?>().firstWhere(
      (c) =>
          c != null &&
          c.tipo == 'individual' &&
          c.participantes.any((p) => p.id == user.id),
      orElse: () => null,
    );

    if (existing != null) {
      context.pop();
      context.push('/chat/${existing.id}', extra: existing);
      return;
    }

    // 2. Caso precise criar no servidor, ativa o loading APENAS para este usuário selecionado
    setState(() => _loadingUserId = user.id);
    try {
      final repo = ref.read(conversationRepositoryProvider);
      final conv = await repo.createConversation(
        tipo: 'individual',
        participantIds: [user.id],
      );

      // Adicionar à lista de conversas
      ref.read(conversationsProvider.notifier).addConversation(conv);

      if (context.mounted) {
        // Fechar e abrir o chat
        context.pop();
        context.push('/chat/${conv.id}', extra: conv);
      }
    } catch (e) {
      if (context.mounted) {
        _showError(context, e.toString());
      }
    } finally {
      if (mounted) setState(() => _loadingUserId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ─── Busca ────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Buscar funcionário...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _searchCtrl.clear();
                        ref.read(usersSearchProvider.notifier).search('');
                      },
                    )
                  : null,
            ),
            onChanged: (v) => ref.read(usersSearchProvider.notifier).search(v),
          ),
        ),

        // ─── Lista de usuários e Filtros ───────────────────────────────
        ref.watch(usersSearchProvider).when(
          loading: () => const Expanded(
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Expanded(
            child: _ErrorView(
              message: e.toString(),
              onRetry: () => ref.read(usersSearchProvider.notifier).search(''),
            ),
          ),
          data: (rawUsers) {
            final myId = ref.watch(currentUserIdProvider);
            final users = rawUsers.where((u) => u.id != myId).toList();
            final cargoOptions = _getCargoOptionsForUsers(users);
            final filteredUsers = _filterUsers(
              users,
              cargoOptions,
              _statusFilter,
              _cargoFilterId,
            );

            return Expanded(
              child: Column(
                children: [
                  _UserFilterBar(
                    statusFilter: _statusFilter,
                    onStatusFilterChanged: (s) =>
                        setState(() => _statusFilter = s),
                    selectedCargoId: _cargoFilterId,
                    onCargoFilterChanged: (c) =>
                        setState(() => _cargoFilterId = c),
                    users: users,
                    cargoOptions: cargoOptions,
                  ),
                  Expanded(
                    child: users.isEmpty
                        ? const _EmptyView(
                            message: 'Nenhum funcionário encontrado.')
                        : filteredUsers.isEmpty
                            ? _FilterEmptyView(
                                onClear: () => setState(() {
                                  _statusFilter = 'all';
                                  _cargoFilterId = 'all';
                                }),
                              )
                            : ListView.separated(
                                keyboardDismissBehavior:
                                    ScrollViewKeyboardDismissBehavior.onDrag,
                                itemCount: filteredUsers.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 1, indent: 70),
                                itemBuilder: (context, i) {
                                  final user = filteredUsers[i];
                                  final isThisUserLoading =
                                      _loadingUserId == user.id;
                                  return _UserTile(
                                    user: user,
                                    trailing: isThisUserLoading
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2),
                                          )
                                        : const Icon(Icons.chevron_right,
                                            color: AppColors.neutral400),
                                    onTap: _loadingUserId != null
                                        ? null
                                        : () => _startConversation(
                                            context, user),
                                  );
                                },
                              ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

// ─── Aba Grupo ────────────────────────────────────────────────────────────────
class _GroupTab extends ConsumerStatefulWidget {
  const _GroupTab();

  @override
  ConsumerState<_GroupTab> createState() => _GroupTabState();
}

class _GroupTabState extends ConsumerState<_GroupTab> {
  static const _presetPhotos = [
    ('Geral / Hospital', 'https://images.unsplash.com/photo-1586773860418-d37222d8fce3?w=150&auto=format&fit=crop&q=80'),
    ('Equipe Médica', 'https://images.unsplash.com/photo-1622253692010-333f2da6031d?w=150&auto=format&fit=crop&q=80'),
    ('Enfermagem', 'https://images.unsplash.com/photo-1576765608535-5f04d1e3f289?w=150&auto=format&fit=crop&q=80'),
    ('UTI / Emergência', 'https://images.unsplash.com/photo-1516549655169-df83a0774514?w=150&auto=format&fit=crop&q=80'),
    ('Farmácia', 'https://images.unsplash.com/photo-1471864190281-a93a3070b6de?w=150&auto=format&fit=crop&q=80'),
    ('Centro Cirúrgico', 'https://images.unsplash.com/photo-1579684385127-1ef15d508118?w=150&auto=format&fit=crop&q=80'),
  ];

  final _nameCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();
  final Set<UserSummary> _selected = {};
  String? _selectedFotoUrl;
  bool _autoExcluir24h = false;
  bool _loading = false;
  String _statusFilter = 'all'; // 'all', 'working', 'off'
  String _cargoFilterId = 'all';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickGroupPhoto() async {
    final controller = TextEditingController(text: _selectedFotoUrl ?? '');
    final picked = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Foto do Grupo'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Escolha uma foto temática:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              SizedBox(
                height: 72,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _presetPhotos.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final item = _presetPhotos[i];
                    return InkWell(
                      onTap: () => Navigator.pop(ctx, item.$2),
                      child: Column(
                        children: [
                          CircleAvatar(radius: 24, backgroundImage: NetworkImage(item.$2)),
                          const SizedBox(height: 2),
                          Text(item.$1, style: const TextStyle(fontSize: 9)),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const Divider(height: 24),
              const Text('Ou insira o link de uma imagem pública:', style: TextStyle(fontSize: 12, color: Colors.black54)),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: 'https://exemplo.com/foto.png',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.link),
                  isDense: true,
                ),
              ),
            ],
          ),
        ),
        actions: [
          if (_selectedFotoUrl != null)
            TextButton(
              onPressed: () => Navigator.pop(ctx, ''),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Remover foto'),
            ),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('Confirmar')),
        ],
      ),
    );

    if (picked != null) {
      setState(() => _selectedFotoUrl = picked.isEmpty ? null : picked);
    }
  }

  Future<void> _createGroup(BuildContext context) async {
    final nome = _nameCtrl.text.trim();
    if (nome.isEmpty) {
      _showError(context, 'Informe o nome do grupo.');
      return;
    }
    if (_selected.isEmpty) {
      _showError(context, 'Selecione pelo menos um participante.');
      return;
    }

    setState(() => _loading = true);
    try {
      final repo = ref.read(conversationRepositoryProvider);
      final conv = await repo.createConversation(
        tipo: 'grupo',
        nome: nome,
        fotoUrl: _selectedFotoUrl,
        autoExcluir24h: _autoExcluir24h,
        participantIds: _selected.map((u) => u.id).toList(),
      );

      ref.read(conversationsProvider.notifier).addConversation(conv);

      if (context.mounted) {
        context.pop();
        context.push('/chat/${conv.id}', extra: conv);
      }
    } catch (e) {
      if (context.mounted) _showError(context, e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ─── Foto e Nome do grupo ──────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: Row(
            children: [
              GestureDetector(
                onTap: _pickGroupPhoto,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                      backgroundImage: _selectedFotoUrl != null ? NetworkImage(_selectedFotoUrl!) : null,
                      child: _selectedFotoUrl == null
                          ? const Icon(Icons.camera_alt, color: AppColors.primary, size: 26)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                        child: const Icon(Icons.edit, size: 10, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nome do grupo',
                    hintText: 'Ex: Maqueiros CCO',
                    prefixIcon: Icon(Icons.group_outlined),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
              ),
            ],
          ),
        ),

        // ─── Switch Auto-exclusão 24h ──────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: SwitchListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.timer_outlined, color: AppColors.primary, size: 20),
            title: const Text('Auto-exclusão 24h', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            subtitle: const Text('Mensagens expiram após 24 horas', style: TextStyle(fontSize: 11)),
            value: _autoExcluir24h,
            activeTrackColor: AppColors.primary,
            onChanged: (val) => setState(() => _autoExcluir24h = val),
          ),
        ),

        // ─── Participantes selecionados ────────────────────────────────
        if (_selected.isNotEmpty)
          Container(
            height: 80,
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 8),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _selected.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final u = _selected.elementAt(i);
                return Column(
                  children: [
                    Stack(
                      children: [
                        ConversationAvatar(
                            name: u.nome,
                            photoUrl: u.fotoUrl,
                            size: 42),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _selected.remove(u)),
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: const BoxDecoration(
                                color: AppColors.error,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close,
                                  color: Colors.white, size: 10),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: 48,
                      child: Text(
                        u.nome.split(' ').first,
                        style: const TextStyle(fontSize: 10),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

        // ─── Busca ────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: TextField(
            controller: _searchCtrl,
            decoration: const InputDecoration(
              hintText: 'Adicionar participante...',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (v) =>
                ref.read(usersSearchProvider.notifier).search(v),
          ),
        ),

        // ─── Lista de usuários e Filtros ───────────────────────────────
        ref.watch(usersSearchProvider).when(
          loading: () => const Expanded(
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Expanded(
            child: _ErrorView(
              message: e.toString(),
              onRetry: () => ref.read(usersSearchProvider.notifier).search(''),
            ),
          ),
          data: (rawUsers) {
            final myId = ref.watch(currentUserIdProvider);
            final users = rawUsers.where((u) => u.id != myId).toList();
            final cargoOptions = _getCargoOptionsForUsers(users);
            final filteredUsers = _filterUsers(
              users,
              cargoOptions,
              _statusFilter,
              _cargoFilterId,
            );

            return Expanded(
              child: Column(
                children: [
                  _UserFilterBar(
                    statusFilter: _statusFilter,
                    onStatusFilterChanged: (s) =>
                        setState(() => _statusFilter = s),
                    selectedCargoId: _cargoFilterId,
                    onCargoFilterChanged: (c) =>
                        setState(() => _cargoFilterId = c),
                    users: users,
                    cargoOptions: cargoOptions,
                  ),
                  Expanded(
                    child: users.isEmpty
                        ? const _EmptyView(
                            message: 'Nenhum funcionário encontrado.')
                        : filteredUsers.isEmpty
                            ? _FilterEmptyView(
                                onClear: () => setState(() {
                                  _statusFilter = 'all';
                                  _cargoFilterId = 'all';
                                }),
                              )
                            : ListView.separated(
                                keyboardDismissBehavior:
                                    ScrollViewKeyboardDismissBehavior.onDrag,
                                itemCount: filteredUsers.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 1, indent: 70),
                                itemBuilder: (context, i) {
                                  final u = filteredUsers[i];
                                  final isSelected = _selected.contains(u);
                                  return _UserTile(
                                    user: u,
                                    trailing: Checkbox(
                                      value: isSelected,
                                      activeColor: AppColors.primary,
                                      onChanged: (_) => setState(() {
                                        if (isSelected) {
                                          _selected.remove(u);
                                        } else {
                                          _selected.add(u);
                                        }
                                      }),
                                    ),
                                    onTap: () => setState(() {
                                      if (isSelected) {
                                        _selected.remove(u);
                                      } else {
                                        _selected.add(u);
                                      }
                                    }),
                                  );
                                },
                              ),
                  ),
                ],
              ),
            );
          },
        ),

        // ─── Botão criar grupo ─────────────────────────────────────────
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : () => _createGroup(context),
                icon: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.group_add_outlined),
                label: Text(
                  _loading
                      ? 'Criando...'
                      : 'Criar Grupo${_selected.isNotEmpty ? ' (${_selected.length})' : ''}',
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Tile de usuário ──────────────────────────────────────────────────────────
class _UserTile extends StatelessWidget {
  final UserSummary user;
  final Widget trailing;
  final VoidCallback? onTap;

  const _UserTile({
    required this.user,
    required this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isWorking = user.isCurrentlyWorking;

    return ListTile(
      leading: ConversationAvatar(
        name: user.nome,
        photoUrl: user.fotoUrl,
        size: 44,
        isWorking: isWorking,
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              user.nome,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5.5, vertical: 1),
            decoration: BoxDecoration(
              color: isWorking
                  ? const Color(0xFF22C55E).withValues(alpha: 0.12)
                  : const Color(0xFFF59E0B).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isWorking
                    ? const Color(0xFF22C55E).withValues(alpha: 0.3)
                    : const Color(0xFFF59E0B).withValues(alpha: 0.3),
                width: 0.8,
              ),
            ),
            child: Text(
              isWorking ? 'Em Plantão' : 'Fora de Serviço',
              style: TextStyle(
                color: isWorking
                    ? const Color(0xFF16A34A)
                    : const Color(0xFFD97706),
                fontWeight: FontWeight.w600,
                fontSize: 9.5,
              ),
            ),
          ),
        ],
      ),
      subtitle: Text(
        '${user.hierarquiaNome} · ${user.setorNome} (${user.jornadaInicio} às ${user.jornadaFim})',
        style: const TextStyle(
            fontSize: 12, color: AppColors.neutral500),
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────
class _EmptyView extends StatelessWidget {
  final String message;
  const _EmptyView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.person_search_outlined,
              size: 48, color: AppColors.neutral400),
          const SizedBox(height: 12),
          Text(message,
              style: const TextStyle(color: AppColors.neutral500)),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                size: 40, color: AppColors.error),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.neutral600, fontSize: 13),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}

void _showError(BuildContext context, String msg) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(12),
    ),
  );
}

// ─── Lógica e Modelos de Filtro por Cargo/Função ──────────────────────────────
class _CargoOption {
  final String id;
  final String label;
  final IconData icon;
  final List<String> keywords;

  const _CargoOption({
    required this.id,
    required this.label,
    required this.icon,
    this.keywords = const [],
  });

  bool matches(String cargo) {
    if (id == 'all') return true;
    final lower = cargo.toLowerCase();
    return keywords.any((k) => lower.contains(k));
  }
}

const _kBaseCargoOptions = [
  _CargoOption(
    id: 'all',
    label: 'Todas Funções',
    icon: Icons.grid_view_rounded,
  ),
  _CargoOption(
    id: 'med',
    label: 'Médicos',
    icon: Icons.medical_services_outlined,
    keywords: ['médic', 'doutor', 'cirurg', 'clínic'],
  ),
  _CargoOption(
    id: 'enf',
    label: 'Enfermagem',
    icon: Icons.health_and_safety_outlined,
    keywords: ['enferm', 'técnic'],
  ),
  _CargoOption(
    id: 'maq',
    label: 'Maqueiros',
    icon: Icons.accessible_forward_outlined,
    keywords: ['maqueir'],
  ),
  _CargoOption(
    id: 'far',
    label: 'Farmácia',
    icon: Icons.medication_outlined,
    keywords: ['farmác', 'farmac'],
  ),
  _CargoOption(
    id: 'rec',
    label: 'Recepção',
    icon: Icons.badge_outlined,
    keywords: ['recep', 'atend', 'regula'],
  ),
  _CargoOption(
    id: 'adm',
    label: 'Administrativo',
    icon: Icons.business_outlined,
    keywords: ['admin', 'dire', 'coord', 'geren'],
  ),
  _CargoOption(
    id: 'exa',
    label: 'Exames / Imagem',
    icon: Icons.biotech_outlined,
    keywords: ['radio', 'exame', 'oftal', 'laborat'],
  ),
];

List<_CargoOption> _getCargoOptionsForUsers(List<UserSummary> users) {
  final options = <_CargoOption>[..._kBaseCargoOptions];
  final unmapped = <String>{};
  for (final u in users) {
    final c = u.cargo.trim();
    if (c.isEmpty) continue;
    final matchesAny =
        _kBaseCargoOptions.skip(1).any((opt) => opt.matches(c));
    if (!matchesAny) {
      unmapped.add(c);
    }
  }
  for (final c in unmapped) {
    options.add(_CargoOption(
      id: 'custom_$c',
      label: c,
      icon: Icons.work_outline,
      keywords: [c.toLowerCase()],
    ));
  }
  return options;
}

List<UserSummary> _filterUsers(
  List<UserSummary> users,
  List<_CargoOption> cargoOptions,
  String statusFilter,
  String cargoFilterId,
) {
  return users.where((u) {
    // 1. Filtro de Status de Serviço (Online / Offline / Plantão)
    if (statusFilter == 'working' && !u.isCurrentlyWorking) return false;
    if (statusFilter == 'off' && u.isCurrentlyWorking) return false;

    // 2. Filtro de Função / Cargo
    if (cargoFilterId != 'all') {
      final opt = cargoOptions.firstWhere(
        (o) => o.id == cargoFilterId,
        orElse: () => _kBaseCargoOptions.first,
      );
      if (opt.id != 'all' && !opt.matches(u.cargo)) return false;
    }

    return true;
  }).toList();
}

// ─── Barra de Filtros (Status + Função) ────────────────────────────────────────
class _UserFilterBar extends StatelessWidget {
  final String statusFilter;
  final ValueChanged<String> onStatusFilterChanged;
  final String selectedCargoId;
  final ValueChanged<String> onCargoFilterChanged;
  final List<UserSummary> users;
  final List<_CargoOption> cargoOptions;

  const _UserFilterBar({
    required this.statusFilter,
    required this.onStatusFilterChanged,
    required this.selectedCargoId,
    required this.onCargoFilterChanged,
    required this.users,
    required this.cargoOptions,
  });

  @override
  Widget build(BuildContext context) {
    final total = users.length;
    final working = users.where((u) => u.isCurrentlyWorking).length;
    final off = total - working;

    return Container(
      padding: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: Colors.black.withValues(alpha: 0.06),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Linha 1: Status de Serviço (Todos / Em Plantão / Fora) ──
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                _StatusPill(
                  label: 'Todos',
                  count: total,
                  icon: Icons.people_outline,
                  color: AppColors.primary,
                  isSelected: statusFilter == 'all',
                  onTap: () => onStatusFilterChanged('all'),
                ),
                const SizedBox(width: 8),
                _StatusPill(
                  label: 'Em Plantão',
                  count: working,
                  icon: Icons.check_circle,
                  color: const Color(0xFF16A34A),
                  isSelected: statusFilter == 'working',
                  onTap: () => onStatusFilterChanged('working'),
                ),
                const SizedBox(width: 8),
                _StatusPill(
                  label: 'Fora de Serviço',
                  count: off,
                  icon: Icons.nightlight_round,
                  color: const Color(0xFFD97706),
                  isSelected: statusFilter == 'off',
                  onTap: () => onStatusFilterChanged('off'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // ── Linha 2: Função / Especialidade ──
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: cargoOptions.map((opt) {
                final isAll = opt.id == 'all';
                final count = isAll
                    ? total
                    : users.where((u) => opt.matches(u.cargo)).length;

                // Não exibir chips com zero membros se não for a opção 'Todas'
                if (!isAll && count == 0) return const SizedBox.shrink();

                final isSelected = selectedCargoId == opt.id;

                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    showCheckmark: false,
                    avatar: Icon(
                      opt.icon,
                      size: 14,
                      color: isSelected ? Colors.white : AppColors.neutral600,
                    ),
                    label: Text(
                      '${opt.label} ($count)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected ? Colors.white : AppColors.neutral700,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    backgroundColor: Colors.grey.shade100,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: isSelected
                            ? AppColors.primary
                            : Colors.grey.shade300,
                        width: 0.8,
                      ),
                    ),
                    onSelected: (_) => onCargoFilterChanged(opt.id),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _StatusPill({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.14)
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade300,
              width: isSelected ? 1.4 : 0.8,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 13,
                  color: isSelected ? color : AppColors.neutral500),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? color : AppColors.neutral700,
                ),
              ),
              const SizedBox(width: 5),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withValues(alpha: 0.22)
                      : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? color : AppColors.neutral600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterEmptyView extends StatelessWidget {
  final VoidCallback onClear;
  const _FilterEmptyView({required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.neutral100,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.filter_alt_off_outlined,
                  size: 40, color: AppColors.neutral400),
            ),
            const SizedBox(height: 12),
            const Text(
              'Nenhum colaborador encontrado',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            const Text(
              'Tente alterar os filtros de status ou de função acima para visualizar outros colegas.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.neutral500, fontSize: 13),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Limpar filtros'),
            ),
          ],
        ),
      ),
    );
  }
}
