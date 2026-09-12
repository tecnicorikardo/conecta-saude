import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme_provider.dart';
import '../../domain/entities/conversation_entity.dart';
import '../../domain/entities/message_entity.dart';
import '../providers/chat_provider.dart';
import '../widgets/conversation_avatar.dart';
import 'new_conversation_page.dart';

class ConversationsPage extends ConsumerStatefulWidget {
  const ConversationsPage({super.key});

  @override
  ConsumerState<ConversationsPage> createState() => _ConversationsPageState();
}

class _ConversationsPageState extends ConsumerState<ConversationsPage>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = '';
  int _selectedFilterTab = 0; // 0: Todas, 1: Diretas, 2: Grupos

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildFilterTabs(List<ConversationEntity> allConvs) {
    final tokens = context.appTokens;
    final directCount = allConvs.where((c) => !c.isGroup).length;
    final groupCount = allConvs.where((c) => c.isGroup).length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: tokens.surface,
        border: Border(
          bottom: BorderSide(
            color: tokens.border,
            width: 1,
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _filterChip(label: 'Todas', count: allConvs.length, index: 0),
            const SizedBox(width: 8),
            _filterChip(label: 'Diretas', count: directCount, index: 1),
            const SizedBox(width: 8),
            _filterChip(label: 'Grupos', count: groupCount, index: 2, isGroupTag: true),
          ],
        ),
      ),
    );
  }

  Widget _filterChip({required String label, required int count, required int index, bool isGroupTag = false}) {
    final tokens = context.appTokens;
    final isSelected = _selectedFilterTab == index;
    return ChoiceChip(
      showCheckmark: false,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isGroupTag) ...[
            Icon(Icons.groups, size: 14, color: isSelected ? tokens.themeAccentColor : tokens.textSecondary),
            const SizedBox(width: 4),
          ],
          Text('$label ($count)'),
        ],
      ),
      selected: isSelected,
      selectedColor: tokens.iconContainerColor,
      backgroundColor: tokens.surface,
      side: BorderSide(
        color: isSelected ? tokens.themeAccentColor : tokens.border,
        width: 1,
      ),
      labelStyle: TextStyle(
        color: isSelected ? tokens.themeAccentColor : tokens.textSecondary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        fontSize: 12,
      ),
      onSelected: (_) => setState(() => _selectedFilterTab = index),
    );
  }

  void _showConversationActions(ConversationEntity conv) {
    final isGroup = conv.isGroup;
    final displayName = conv.displayName(ref.read(currentUserIdProvider));

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Text(
                displayName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.cleaning_services_outlined, color: Colors.amber),
              title: const Text('Limpar conversa'),
              subtitle: const Text('Apaga todas as mensagens do histórico'),
              onTap: () async {
                Navigator.pop(ctx);
                final messenger = ScaffoldMessenger.of(context);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (dCtx) => AlertDialog(
                    title: const Text('Limpar conversa?'),
                    content: Text('Deseja apagar todas as mensagens de "$displayName"? A conversa será mantida.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(dCtx, false), child: const Text('Cancelar')),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade700, foregroundColor: Colors.white),
                        onPressed: () => Navigator.pop(dCtx, true),
                        child: const Text('Limpar Histórico'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  try {
                    await ref.read(messagesProvider(conv.id).notifier).clearConversation();
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Histórico limpo com sucesso.')),
                    );
                  } catch (e) {
                    messenger.showSnackBar(
                      SnackBar(content: Text('Erro: $e')),
                    );
                  }
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: Text(isGroup ? 'Sair e excluir grupo' : 'Excluir conversa', style: const TextStyle(color: Colors.red)),
              subtitle: Text(isGroup ? 'Você sairá e o grupo será removido' : 'Remove a conversa da sua lista'),
              onTap: () async {
                Navigator.pop(ctx);
                final messenger = ScaffoldMessenger.of(context);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (dCtx) => AlertDialog(
                    title: Text(isGroup ? 'Sair e excluir grupo?' : 'Excluir conversa?'),
                    content: Text('Deseja realmente excluir "$displayName" e todo o histórico?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(dCtx, false), child: const Text('Cancelar')),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                        onPressed: () => Navigator.pop(dCtx, true),
                        child: const Text('Excluir'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  try {
                    await ref.read(conversationsProvider.notifier).deleteConversation(conv.id);
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Conversa excluída com sucesso.')),
                    );
                  } catch (e) {
                    messenger.showSnackBar(
                      SnackBar(content: Text('Erro: $e')),
                    );
                  }
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final conversationsAsync = ref.watch(conversationsProvider);
    final currentUserId = ref.watch(currentUserIdProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          // ─── Barra de busca (quando ativa) ──────────────────────────────
          if (_isSearching) _buildSearchBar(),

          // ─── Abas de filtro: Todas / Diretas / Grupos ─────────────────────
          conversationsAsync.maybeWhen(
            data: (conversations) => _buildFilterTabs(conversations),
            orElse: () => const SizedBox.shrink(),
          ),

          // ─── Lista de conversas ──────────────────────────────────────────
          Expanded(
            child: conversationsAsync.when(
              loading: () => _buildShimmerList(),
              error: (e, _) => _buildError(context),
              data: (conversations) {
                var filtered = conversations;
                if (_selectedFilterTab == 1) {
                  filtered = filtered.where((c) => !c.isGroup).toList();
                } else if (_selectedFilterTab == 2) {
                  filtered = filtered.where((c) => c.isGroup).toList();
                }

                if (_searchQuery.isNotEmpty) {
                  filtered = filtered.where((c) {
                    final name = c.displayName(currentUserId).toLowerCase();
                    return name.contains(_searchQuery.toLowerCase());
                  }).toList();
                }

                if (filtered.isEmpty) {
                  return _buildEmpty(context);
                }

                final tokens = context.appTokens;
                return ListView.separated(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    color: tokens.border,
                    indent: 76,
                  ),
                  itemBuilder: (context, index) {
                    return _ConversationTile(
                      key: ValueKey(filtered[index].id),
                      conversation: filtered[index],
                      currentUserId: currentUserId,
                      onTap: () {
                        context.push(
                          '/chat/${filtered[index].id}',
                          extra: filtered[index],
                        );
                      },
                      onLongPress: () => _showConversationActions(filtered[index]),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: context.appTokens.themeAccentColor,
        foregroundColor: Colors.white,
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => DraggableScrollableSheet(
              initialChildSize: 0.9,
              maxChildSize: 0.95,
              minChildSize: 0.5,
              builder: (_, scrollController) => const ClipRRect(
                borderRadius: BorderRadius.vertical(
                    top: Radius.circular(20)),
                child: NewConversationPage(),
              ),
            ),
          );
        },
        tooltip: 'Nova conversa',
        child: const Icon(Icons.chat_outlined),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final tokens = context.appTokens;
    return AppBar(
      backgroundColor: tokens.primaryDark,
      foregroundColor: Colors.white,
      bottom: tokens.identityRainbow.isNotEmpty
          ? PreferredSize(
              preferredSize: const Size.fromHeight(3.0),
              child: tokens.buildHorizontalAccent(height: 3.0),
            )
          : (tokens.accent != null
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(2.5),
                  child: tokens.buildHorizontalAccent(height: 2.5),
                )
              : null),
      title: _isSearching
          ? null
          : const Text(
              'Conversas',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                letterSpacing: 0.2,
              ),
            ),
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: tokens.primaryDark,
        statusBarIconBrightness: Brightness.light,
      ),
      actions: [
        IconButton(
          icon: Icon(_isSearching ? Icons.close : Icons.search),
          onPressed: () {
            setState(() {
              _isSearching = !_isSearching;
              if (!_isSearching) {
                _searchQuery = '';
                _searchController.clear();
              }
            });
          },
          tooltip: _isSearching ? 'Fechar busca' : 'Buscar',
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onSelected: (value) {
            if (value == 'novo_grupo') {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => DraggableScrollableSheet(
                  initialChildSize: 0.9,
                  maxChildSize: 0.95,
                  minChildSize: 0.5,
                  builder: (_, __) => const ClipRRect(
                    borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20)),
                    child: NewConversationPage(),
                  ),
                ),
              );
            } else if (value == 'recarregar') {
              ref.read(conversationsProvider.notifier).load();
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'novo_grupo', child: Text('Novo grupo')),
            PopupMenuItem(value: 'recarregar', child: Text('Recarregar')),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: AppColors.primaryDeep,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: TextField(
        controller: _searchController,
        autofocus: true,
        style: const TextStyle(color: Colors.white),
        cursorColor: Colors.white,
        decoration: InputDecoration(
          hintText: 'Buscar conversa...',
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.12),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.white, width: 1.5),
          ),
          prefixIcon: Icon(Icons.search, color: Colors.white.withValues(alpha: 0.7)),
        ),
        onChanged: (v) => setState(() => _searchQuery = v),
      ),
    );
  }

  Widget _buildShimmerList() {
    return ListView.separated(
      itemCount: 6,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
      itemBuilder: (_, __) => const _ShimmerTile(),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.chat_bubble_outline,
              size: 64, color: AppColors.neutral400),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty
                ? 'Nenhuma conversa ainda.'
                : 'Nenhum resultado para "$_searchQuery".',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.neutral500),
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.error),
          const SizedBox(height: 12),
          Text('Não foi possível carregar as conversas.',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => ref.invalidate(conversationsProvider),
            icon: const Icon(Icons.refresh),
            label: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }
}

// ─── Tile de conversa ────────────────────────────────────────────────────────
class _ConversationTile extends StatelessWidget {
  final ConversationEntity conversation;
  final String currentUserId;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _ConversationTile({
    super.key,
    required this.conversation,
    required this.currentUserId,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.appTokens;
    final isGroup = conversation.tipo == 'grupo' || conversation.tipo == 'setor';
    final otherParticipant = isGroup ? null : conversation.otherParticipant(currentUserId);
    final isWorking = otherParticipant?.isCurrentlyWorking;
    final displayName = conversation.displayName(currentUserId);
    final photoUrl = conversation.displayPhoto(currentUserId);
    final subtitle = conversation.displaySubtitle(currentUserId);
    final lastMsg = conversation.lastMessage;
    final hasUnread = conversation.unreadCount > 0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        color: tokens.surface,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (hasUnread)
                tokens.buildVerticalStripe(width: 3.5),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      // ─── Avatar ───────────────────────────────────────────────────
                      ConversationAvatar(
                        name: displayName,
                        photoUrl: photoUrl,
                        isGroup: isGroup,
                        size: 50,
                        isWorking: isWorking,
                      ),
                      const SizedBox(width: 12),

                      // ─── Conteúdo ─────────────────────────────────────────────────
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Linha 1: Nome + Destaque Grupo + Auto-exclusão + Horário
                            Row(
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          displayName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: hasUnread
                                                ? FontWeight.w700
                                                : FontWeight.w600,
                                            color: tokens.textPrimary,
                                          ),
                                        ),
                                      ),
                                      if (!isGroup && otherParticipant != null) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 1.5),
                                          decoration: BoxDecoration(
                                            color: isWorking == true
                                                ? const Color(0xFF22C55E).withValues(alpha: 0.12)
                                                : const Color(0xFFF59E0B).withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(
                                              color: isWorking == true
                                                  ? const Color(0xFF22C55E).withValues(alpha: 0.3)
                                                  : const Color(0xFFF59E0B).withValues(alpha: 0.3),
                                              width: 0.8,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                isWorking == true
                                                    ? Icons.check_circle_outline
                                                    : Icons.nightlight_round,
                                                size: 10,
                                                color: isWorking == true
                                                    ? const Color(0xFF16A34A)
                                                    : const Color(0xFFD97706),
                                              ),
                                              const SizedBox(width: 3),
                                              Text(
                                                isWorking == true ? 'Em Plantão' : 'Fora de Serviço',
                                                style: TextStyle(
                                                  color: isWorking == true
                                                      ? const Color(0xFF16A34A)
                                                      : const Color(0xFFD97706),
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 9.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                      if (isGroup) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: tokens.iconContainerColor,
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(
                                                color: tokens.themeAccentColor.withValues(alpha: 0.25)),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.groups,
                                                  size: 12, color: tokens.themeAccentColor),
                                              const SizedBox(width: 3),
                                              Text(
                                                'GRUPO • ${conversation.participantes.length}',
                                                style: TextStyle(
                                                  color: tokens.themeAccentColor,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 10,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                if (lastMsg != null) ...[
                                  const SizedBox(width: 8),
                                  Text(
                                    _formatTime(lastMsg.criadoEm),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: hasUnread
                                          ? tokens.themeAccentColor
                                          : tokens.textSecondary,
                                      fontWeight: hasUnread
                                          ? FontWeight.w700
                                          : FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),

                            // Linha 2: Cargo/setor + última mensagem + badge
                            Row(
                              children: [
                                Expanded(
                                  child: lastMsg != null
                                      ? _buildLastMessage(lastMsg, currentUserId, isDark)
                                      : Text(
                                          subtitle,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: tokens.textSecondary,
                                          ),
                                        ),
                                ),
                                if (hasUnread) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: tokens.themeAccentColor,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      conversation.unreadCount > 99
                                          ? '99+'
                                          : '${conversation.unreadCount}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLastMessage(
      MessageEntity msg, String currentUserId, bool isDark) {
    final isMe = msg.remetente.id == currentUserId;
    final color = isDark ? AppColors.onDarkSurfaceVariant : AppColors.textSecondary;

    if (msg.excluido) {
      return Row(
        children: [
          Icon(Icons.block, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            'Mensagem apagada',
            style: TextStyle(
                fontSize: 13, color: color, fontStyle: FontStyle.italic),
          ),
        ],
      );
    }

    return Row(
      children: [
        // Tick de status para mensagens minhas
        if (isMe) ...[
          _StatusIcon(status: msg.status, size: 14),
          const SizedBox(width: 3),
        ],
        // Prefixo em grupo
        if (!isMe && (msg.remetente.nome.isNotEmpty))
          Flexible(
            child: Text(
              (msg.tipo == MessageType.audio || msg.texto.startsWith('[audio'))
                  ? '🎤 Mensagem de áudio'
                  : msg.texto,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, color: color),
            ),
          )
        else
          Flexible(
            child: Text(
              (msg.tipo == MessageType.audio || msg.texto.startsWith('[audio'))
                  ? '🎤 Mensagem de áudio'
                  : msg.texto,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, color: color),
            ),
          ),
      ],
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) {
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    } else if (diff.inDays == 1) {
      return 'ontem';
    } else if (diff.inDays < 7) {
      const days = ['seg', 'ter', 'qua', 'qui', 'sex', 'sáb', 'dom'];
      return days[dt.weekday - 1];
    } else {
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    }
  }
}

// ─── Ícone de status (ticks) ──────────────────────────────────────────────────
class _StatusIcon extends StatelessWidget {
  final MessageStatus status;
  final double size;

  const _StatusIcon({required this.status, this.size = 16});

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case MessageStatus.sending:
        return Icon(Icons.access_time, size: size, color: AppColors.neutral400);
      case MessageStatus.sent:
        return Icon(Icons.check, size: size, color: AppColors.neutral400);
      case MessageStatus.delivered:
        return Icon(Icons.done_all, size: size, color: AppColors.neutral400);
      case MessageStatus.read:
        return Icon(Icons.done_all, size: size, color: AppColors.primary);
      case MessageStatus.error:
        return Icon(Icons.error_outline, size: size, color: AppColors.error);
    }
  }
}

// ─── Shimmer placeholder ─────────────────────────────────────────────────────
class _ShimmerTile extends StatelessWidget {
  const _ShimmerTile();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 50, height: 50,
            decoration: const BoxDecoration(
              color: AppColors.neutral300,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 14, width: 160, color: AppColors.neutral300,
                    margin: const EdgeInsets.only(bottom: 6)),
                Container(height: 12, color: AppColors.neutral300),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// fim do arquivo
