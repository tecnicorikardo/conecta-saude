import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

          // ─── Lista de conversas ──────────────────────────────────────────
          Expanded(
            child: conversationsAsync.when(
              loading: () => _buildShimmerList(),
              error: (e, _) => _buildError(context),
              data: (conversations) {
                final filtered = _searchQuery.isEmpty
                    ? conversations
                    : conversations.where((c) {
                        final name = c.displayName(currentUserId).toLowerCase();
                        return name.contains(_searchQuery.toLowerCase());
                      }).toList();

                if (filtered.isEmpty) {
                  return _buildEmpty(context);
                }

                return ListView.builder(
                  itemCount: filtered.length,
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
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => DraggableScrollableSheet(
              initialChildSize: 0.9,
              maxChildSize: 0.95,
              minChildSize: 0.5,
              builder: (_, scrollController) => ClipRRect(
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20)),
                child: const NewConversationPage(),
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
    return AppBar(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      title: _isSearching
          ? null
          : const Text('Conversas'),
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: AppColors.primaryDark,
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
                  builder: (_, __) => ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20)),
                    child: const NewConversationPage(),
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
      color: AppColors.primary,
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: TextField(
        controller: _searchController,
        autofocus: true,
        style: const TextStyle(color: Colors.white),
        cursorColor: Colors.white,
        decoration: InputDecoration(
          hintText: 'Buscar conversa...',
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.15),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
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
          Icon(Icons.chat_bubble_outline,
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

  const _ConversationTile({
    super.key,
    required this.conversation,
    required this.currentUserId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isGroup = conversation.tipo == 'grupo' || conversation.tipo == 'setor';
    final displayName = conversation.displayName(currentUserId);
    final photoUrl = conversation.displayPhoto(currentUserId);
    final subtitle = conversation.displaySubtitle(currentUserId);
    final lastMsg = conversation.lastMessage;
    final hasUnread = conversation.unreadCount > 0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      child: Container(
        color: isDark ? AppColors.darkSurface : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // ─── Avatar ───────────────────────────────────────────────────
            ConversationAvatar(
              name: displayName,
              photoUrl: photoUrl,
              isGroup: isGroup,
              size: 50,
            ),
            const SizedBox(width: 12),

            // ─── Conteúdo ─────────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nome + horário
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: hasUnread
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: isDark
                                ? AppColors.onDarkSurface
                                : AppColors.neutral900,
                          ),
                        ),
                      ),
                      if (lastMsg != null)
                        Text(
                          _formatTime(lastMsg.criadoEm),
                          style: TextStyle(
                            fontSize: 12,
                            color: hasUnread
                                ? AppColors.primary
                                : AppColors.neutral500,
                            fontWeight: hasUnread
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),

                  // Cargo/setor + última mensagem + badge
                  Row(
                    children: [
                      Expanded(
                        child: lastMsg != null
                            ? _buildLastMessage(lastMsg, currentUserId, isDark)
                            : Text(
                                subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.neutral500,
                                ),
                              ),
                      ),
                      if (hasUnread)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
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
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLastMessage(
      MessageEntity msg, String currentUserId, bool isDark) {
    final isMe = msg.remetente.id == currentUserId;
    final color = isDark ? AppColors.onDarkSurfaceVariant : AppColors.neutral600;

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
              msg.tipo == MessageType.audio ? '🎤 Áudio' : msg.texto,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, color: color),
            ),
          )
        else
          Flexible(
            child: Text(
              msg.tipo == MessageType.audio ? '🎤 Áudio' : msg.texto,
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
        return Icon(Icons.done_all, size: size, color: AppColors.primaryLight);
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
