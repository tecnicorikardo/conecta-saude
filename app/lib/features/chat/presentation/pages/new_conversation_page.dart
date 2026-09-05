import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/conversation_model.dart';
import '../../data/repositories/conversation_repository.dart';
import '../providers/chat_provider.dart';
import '../widgets/conversation_avatar.dart';

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
  bool _loading = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _startConversation(
      BuildContext context, UserSummary user) async {
    setState(() => _loading = true);
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
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ─── Busca ────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.all(12),
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
                        ref
                            .read(usersSearchProvider.notifier)
                            .search('');
                      },
                    )
                  : null,
            ),
            onChanged: (v) =>
                ref.read(usersSearchProvider.notifier).search(v),
          ),
        ),

        // ─── Lista de usuários ─────────────────────────────────────────
        Expanded(
          child: ref.watch(usersSearchProvider).when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => _ErrorView(
              message: e.toString(),
              onRetry: () =>
                  ref.read(usersSearchProvider.notifier).search(''),
            ),
            data: (users) {
              if (users.isEmpty) {
                return const _EmptyView(
                    message: 'Nenhum funcionário encontrado.');
              }
              return ListView.separated(
                itemCount: users.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, indent: 70),
                itemBuilder: (context, i) => _UserTile(
                  user: users[i],
                  trailing: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.chevron_right,
                          color: AppColors.neutral400),
                  onTap: _loading
                      ? null
                      : () => _startConversation(context, users[i]),
                ),
              );
            },
          ),
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
  final _nameCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();
  final Set<UserSummary> _selected = {};
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
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
        // ─── Nome do grupo ─────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
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

        // ─── Lista de usuários ─────────────────────────────────────────
        Expanded(
          child: ref.watch(usersSearchProvider).when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => _ErrorView(
              message: e.toString(),
              onRetry: () =>
                  ref.read(usersSearchProvider.notifier).search(''),
            ),
            data: (users) {
              if (users.isEmpty) {
                return const _EmptyView(
                    message: 'Nenhum funcionário encontrado.');
              }
              return ListView.separated(
                itemCount: users.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, indent: 70),
                itemBuilder: (context, i) {
                  final u = users[i];
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
              );
            },
          ),
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
    return ListTile(
      leading: ConversationAvatar(
        name: user.nome,
        photoUrl: user.fotoUrl,
        size: 44,
      ),
      title: Text(
        user.nome,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '${user.hierarquiaNome} · ${user.setorNome}',
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
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.neutral600),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
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
