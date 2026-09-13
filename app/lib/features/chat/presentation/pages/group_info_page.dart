import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/conversation_entity.dart';
import '../../data/repositories/conversation_repository.dart';
import '../providers/chat_provider.dart';
import '../widgets/conversation_avatar.dart';

class GroupInfoPage extends ConsumerStatefulWidget {
  final String conversationId;

  const GroupInfoPage({
    super.key,
    required this.conversationId,
  });

  @override
  ConsumerState<GroupInfoPage> createState() => _GroupInfoPageState();
}

class _GroupInfoPageState extends ConsumerState<GroupInfoPage> {
  ConversationEntity? _conversation;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadGroupDetails();
  }

  Future<void> _loadGroupDetails() async {
    // 1. Carrega imediatamente do cache se disponível para abrir em 0ms
    final allConvs = ref.read(conversationsProvider).valueOrNull ?? [];
    final cached = allConvs.where((c) => c.id == widget.conversationId).firstOrNull;
    if (cached != null && _conversation == null) {
      setState(() {
        _conversation = cached;
        _isLoading = false;
      });
    }

    try {
      if (_conversation == null) {
        setState(() {
          _isLoading = true;
          _error = null;
        });
      }
      final repo = ref.read(conversationRepositoryProvider);
      final data = await repo.getConversation(widget.conversationId);
      if (mounted) {
        setState(() {
          _conversation = data;
          _isLoading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        if (_conversation == null) {
          setState(() {
            _error = e.toString().replaceAll('Exception: ', '');
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _editGroupName() async {
    if (_conversation == null) return;
    final controller = TextEditingController(text: _conversation!.nome);

    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar nome do grupo'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 80,
          decoration: const InputDecoration(
            hintText: 'Digite o nome do grupo',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && newName != _conversation!.nome) {
      try {
        final repo = ref.read(conversationRepositoryProvider);
        await repo.updateGroup(_conversation!.id, nome: newName);
        ref.invalidate(conversationsProvider);
        _loadGroupDetails();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Nome do grupo atualizado.')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _editGroupDescription() async {
    if (_conversation == null) return;
    final controller = TextEditingController(text: _conversation!.descricao ?? '');

    final newDesc = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Descrição do grupo'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 4,
          maxLength: 500,
          decoration: const InputDecoration(
            hintText: 'Adicione uma descrição para o grupo...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );

    if (newDesc != null) {
      try {
        final repo = ref.read(conversationRepositoryProvider);
        await repo.updateGroup(_conversation!.id, descricao: newDesc);
        ref.invalidate(conversationsProvider);
        _loadGroupDetails();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Descrição atualizada com sucesso.')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  static const _presetPhotos = [
    ('Geral / Hospital', 'https://images.unsplash.com/photo-1586773860418-d37222d8fce3?w=150&auto=format&fit=crop&q=80'),
    ('Equipe Médica', 'https://images.unsplash.com/photo-1622253692010-333f2da6031d?w=150&auto=format&fit=crop&q=80'),
    ('Enfermagem', 'https://images.unsplash.com/photo-1576765608535-5f04d1e3f289?w=150&auto=format&fit=crop&q=80'),
    ('UTI / Emergência', 'https://images.unsplash.com/photo-1516549655169-df83a0774514?w=150&auto=format&fit=crop&q=80'),
    ('Farmácia', 'https://images.unsplash.com/photo-1471864190281-a93a3070b6de?w=150&auto=format&fit=crop&q=80'),
    ('Centro Cirúrgico', 'https://images.unsplash.com/photo-1579684385127-1ef15d508118?w=150&auto=format&fit=crop&q=80'),
  ];

  Future<void> _pickGroupPhoto(ImageSource source) async {
    if (_conversation == null) return;
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      await _applyGroupPhoto(base64Image);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Não foi possível carregar a imagem: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _applyGroupPhoto(String? photoUrl) async {
    if (_conversation == null) return;
    try {
      final repo = ref.read(conversationRepositoryProvider);
      await repo.updateGroup(_conversation!.id, fotoUrl: photoUrl);
      ref.invalidate(conversationsProvider);
      _loadGroupDetails();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto do grupo atualizada com sucesso.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar foto: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _editGroupPhoto() async {
    if (_conversation == null) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Foto do Grupo',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFE3F2FD),
                  child: Icon(Icons.camera_alt_outlined, color: AppColors.primary),
                ),
                title: const Text('Tirar Foto com a Câmera'),
                subtitle: const Text('Usar câmera do dispositivo'),
                onTap: () {
                  Navigator.pop(bCtx);
                  _pickGroupPhoto(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFE8F5E9),
                  child: Icon(Icons.photo_library_outlined, color: AppColors.success),
                ),
                title: const Text('Escolher da Galeria / Arquivos'),
                subtitle: const Text('Selecionar foto salva no dispositivo'),
                onTap: () {
                  Navigator.pop(bCtx);
                  _pickGroupPhoto(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFFFF3E0),
                  child: Icon(Icons.collections_outlined, color: Color(0xFFE65100)),
                ),
                title: const Text('Escolher Ícone Temático Hospitalar'),
                subtitle: const Text('Fotos prontas de enfermagem, UTI, etc.'),
                onTap: () {
                  Navigator.pop(bCtx);
                  _showPresetPhotosDialog();
                },
              ),
              if (_conversation!.fotoUrl != null && _conversation!.fotoUrl!.isNotEmpty)
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFFFEBEE),
                    child: Icon(Icons.delete_outline, color: Colors.red),
                  ),
                  title: const Text('Remover Foto do Grupo', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(bCtx);
                    _applyGroupPhoto(null);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPresetPhotosDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Escolha uma foto temática'),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.8,
            ),
            itemCount: _presetPhotos.length,
            itemBuilder: (_, i) {
              final item = _presetPhotos[i];
              return InkWell(
                onTap: () {
                  Navigator.pop(ctx);
                  _applyGroupPhoto(item.$2);
                },
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundImage: NetworkImage(item.$2),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.$1,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fechar')),
        ],
      ),
    );
  }

  Future<void> _showAddMembersDialog() async {
    if (_conversation == null) return;
    try {
      final repo = ref.read(conversationRepositoryProvider);
      final availableUsers = await repo.listAvailableUsers();
      final existingIds = _conversation!.participantes.map((p) => p.id).toSet();
      final candidates = availableUsers.where((u) => !existingIds.contains(u.id)).toList();

      if (!mounted) return;

      if (candidates.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não há novos contatos elegíveis para adicionar.')),
        );
        return;
      }

      final selectedIds = <String>{};

      await showDialog(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: const Text('Adicionar Participantes'),
              content: SizedBox(
                width: 400,
                height: 380,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: candidates.length,
                  itemBuilder: (context, i) {
                    final user = candidates[i];
                    final isSelected = selectedIds.contains(user.id);
                    return CheckboxListTile(
                      value: isSelected,
                      activeColor: AppColors.primary,
                      title: Text(user.nome, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('${user.cargo} • ${user.setorNome}', style: const TextStyle(fontSize: 12)),
                      secondary: ConversationAvatar(
                        name: user.nome,
                        photoUrl: user.fotoUrl,
                        size: 36,
                      ),
                      onChanged: (val) {
                        setModalState(() {
                          if (val == true) {
                            selectedIds.add(user.id);
                          } else {
                            selectedIds.remove(user.id);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: selectedIds.isEmpty
                      ? null
                      : () async {
                          Navigator.pop(ctx);
                          if (!mounted) return;
                          final messenger = ScaffoldMessenger.of(context);
                          try {
                            await repo.addGroupMembers(_conversation!.id, selectedIds.toList());
                            ref.invalidate(conversationsProvider);
                            _loadGroupDetails();
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text('${selectedIds.length} participante(s) adicionado(s).'),
                              ),
                            );
                          } catch (e) {
                            messenger.showSnackBar(
                              SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
                            );
                          }
                        },
                  child: Text('Adicionar (${selectedIds.length})'),
                ),
              ],
            );
          },
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar participantes: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showParticipantOptions(ConversationParticipant participant, bool isCurrentUserAdmin) {
    final currentUserId = ref.read(currentUserIdProvider);
    final isCreator = participant.id == _conversation?.criadoPor;
    final isSelf = participant.id == currentUserId;

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
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('Ver perfil'),
                onTap: () {
                  Navigator.pop(ctx);
                  context.push('/employees/${participant.id}');
                },
              ),
              if (isCurrentUserAdmin && !isSelf) ...[
                if (!participant.isAdmin)
                  ListTile(
                    leading: const Icon(Icons.shield_outlined, color: Colors.blue),
                    title: const Text('Tornar admin do grupo'),
                    onTap: () async {
                      Navigator.pop(ctx);
                      _updateAdminRole(participant.id, true);
                    },
                  )
                else if (!isCreator)
                  ListTile(
                    leading: const Icon(Icons.remove_moderator_outlined, color: Colors.orange),
                    title: const Text('Remover como admin'),
                    onTap: () async {
                      Navigator.pop(ctx);
                      _updateAdminRole(participant.id, false);
                    },
                  ),
                if (!isCreator)
                  ListTile(
                    leading: const Icon(Icons.person_remove_outlined, color: Colors.red),
                    title: Text(
                      'Remover ${participant.nome}',
                      style: const TextStyle(color: Colors.red),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      _confirmRemoveMember(participant);
                    },
                  ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _updateAdminRole(String userId, bool isAdmin) async {
    if (_conversation == null) return;
    try {
      final repo = ref.read(conversationRepositoryProvider);
      await repo.updateMemberRole(_conversation!.id, userId, isAdmin);
      ref.invalidate(conversationsProvider);
      _loadGroupDetails();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isAdmin ? 'Promovido a admin do grupo.' : 'Status de admin revogado.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _confirmRemoveMember(ConversationParticipant participant) async {
    if (_conversation == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remover participante'),
        content: Text('Tem certeza que deseja remover ${participant.nome} deste grupo?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remover'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final repo = ref.read(conversationRepositoryProvider);
        await repo.removeGroupMember(_conversation!.id, participant.id);
        ref.invalidate(conversationsProvider);
        _loadGroupDetails();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${participant.nome} foi removido(s) do grupo.')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _confirmLeaveGroup() async {
    if (_conversation == null) return;
    final currentUserId = ref.read(currentUserIdProvider);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sair do grupo'),
        content: const Text('Você não receberá mais mensagens deste grupo. Deseja realmente sair?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sair do grupo'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final repo = ref.read(conversationRepositoryProvider);
        await repo.removeGroupMember(_conversation!.id, currentUserId);
        ref.invalidate(conversationsProvider);
        if (mounted) {
          context.go('/conversations');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _confirmDeleteGroup() async {
    if (_conversation == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir grupo'),
        content: const Text('Esta ação desativará o grupo para todos os participantes. Deseja continuar?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final repo = ref.read(conversationRepositoryProvider);
        await repo.deleteGroup(_conversation!.id);
        ref.invalidate(conversationsProvider);
        if (mounted) {
          context.go('/conversations');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = ref.watch(currentUserIdProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final pageBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);
    final dividerColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: pageBg,
        appBar: AppBar(title: const Text('Dados do Grupo')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _conversation == null) {
      return Scaffold(
        backgroundColor: pageBg,
        appBar: AppBar(title: const Text('Dados do Grupo')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error ?? 'Grupo não encontrado.', style: TextStyle(color: textPrimary)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _loadGroupDetails,
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    final conv = _conversation!;
    final isCurrentUserAdmin = conv.isCurrentUserAdmin(currentUserId);
    final isCreator = conv.criadoPor == currentUserId;

    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        title: const Text('Dados do Grupo'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          // ─── Cabeçalho: Foto e Título ─────────────────────────────────────
          Container(
            color: cardBg,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    ConversationAvatar(
                      name: conv.displayName(currentUserId),
                      photoUrl: conv.fotoUrl,
                      isGroup: true,
                      size: 96,
                    ),
                    if (isCurrentUserAdmin)
                      InkWell(
                        onTap: _editGroupPhoto,
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        conv.displayName(currentUserId),
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    if (isCurrentUserAdmin) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20, color: AppColors.primary),
                        onPressed: _editGroupName,
                        tooltip: 'Editar nome do grupo',
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Grupo • ${conv.participantes.length} participantes',
                  style: TextStyle(color: textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ─── Card de Descrição ────────────────────────────────────────────
          Container(
            color: cardBg,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Descrição do grupo',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                    if (isCurrentUserAdmin)
                      TextButton(
                        onPressed: _editGroupDescription,
                        child: const Text('Editar', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  (conv.descricao != null && conv.descricao!.trim().isNotEmpty)
                      ? conv.descricao!
                      : 'Nenhuma descrição informada.',
                  style: TextStyle(
                    fontSize: 14,
                    color: (conv.descricao != null && conv.descricao!.trim().isNotEmpty)
                        ? textPrimary
                        : textSecondary,
                    fontStyle: (conv.descricao == null || conv.descricao!.trim().isEmpty)
                        ? FontStyle.italic
                        : FontStyle.normal,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ─── Card de Mensagens Temporárias (Auto-exclusão 24h) ───────────
          Container(
            color: cardBg,
            child: SwitchListTile(
              secondary: const Icon(Icons.timer_outlined, color: AppColors.primary),
              title: Text('Mensagens temporárias (24h)', style: TextStyle(fontWeight: FontWeight.w600, color: textPrimary)),
              subtitle: Text(
                'Quando ativo, as mensagens deste grupo expiram e somem após 24 horas.${!isCurrentUserAdmin ? '\n(Apenas administradores do grupo podem alterar)' : ''}',
                style: TextStyle(fontSize: 12, color: textSecondary),
              ),
              value: conv.autoExcluir24h,
              activeTrackColor: AppColors.primary,
              onChanged: isCurrentUserAdmin
                  ? (val) async {
                      final messenger = ScaffoldMessenger.of(context);
                      try {
                        final repo = ref.read(conversationRepositoryProvider);
                        await repo.updateGroup(conv.id, autoExcluir24h: val);
                        ref.read(conversationsProvider.notifier).toggleAutoExcluir24h(conv.id, val);
                        _loadGroupDetails();
                      } catch (e) {
                        messenger.showSnackBar(
                          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
                        );
                      }
                    }
                  : null,
            ),
          ),
          const SizedBox(height: 12),

          // ─── Lista de Participantes ───────────────────────────────────────
          Container(
            color: cardBg,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${conv.participantes.length} participantes',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textPrimary),
                      ),
                    ],
                  ),
                ),
                if (isCurrentUserAdmin)
                  ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1B4D3E) : const Color(0xFFE8F5E9),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.person_add,
                        color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF2E7D32),
                        size: 22,
                      ),
                    ),
                    title: Text(
                      'Adicionar participantes',
                      style: TextStyle(
                        color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF2E7D32),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: _showAddMembersDialog,
                  ),
                Divider(height: 1, color: dividerColor),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: conv.participantes.length,
                  separatorBuilder: (_, __) => Divider(height: 1, indent: 70, color: dividerColor),
                  itemBuilder: (context, idx) {
                    final p = conv.participantes[idx];
                    final isSelf = p.id == currentUserId;
                    final isAdmin = p.isAdmin || p.id == conv.criadoPor;

                    return ListTile(
                      leading: ConversationAvatar(
                        name: p.nome,
                        photoUrl: p.fotoUrl,
                        size: 40,
                      ),
                      title: Row(
                        children: [
                          Flexible(
                            child: Text(
                              isSelf ? '${p.nome} (Você)' : p.nome,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14.5,
                                color: textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isAdmin) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1B4D3E) : const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Admin do grupo',
                                style: TextStyle(
                                  color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF2E7D32),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      subtitle: Text(
                        '${p.cargo} • ${p.setorNome}',
                        style: TextStyle(fontSize: 12.5, color: textSecondary, fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () => _showParticipantOptions(p, isCurrentUserAdmin),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ─── Ações de Saída / Exclusão ───────────────────────────────────
          Container(
            color: cardBg,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.exit_to_app, color: Colors.red),
                  title: const Text(
                    'Sair do grupo',
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 14.5),
                  ),
                  onTap: _confirmLeaveGroup,
                ),
                if (isCreator) ...[
                  Divider(height: 1, color: dividerColor),
                  ListTile(
                    leading: const Icon(Icons.delete_forever, color: Colors.red),
                    title: const Text(
                      'Excluir grupo',
                      style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 14.5),
                    ),
                    onTap: _confirmDeleteGroup,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
