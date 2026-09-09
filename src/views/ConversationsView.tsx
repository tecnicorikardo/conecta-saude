import React, { useState } from 'react';
import { useApp } from '../context/AppContext';
import { HierarchyBadge } from '../components/HierarchyBadge';
import {
  Search,
  Send,
  Mic,
  Trash2,
  Flag,
  UserPlus,
  Play,
  Pause,
  CheckCheck,
  Check,
  Phone,
  Video,
  Info,
  X,
  Loader2,
  AlertCircle,
  MessageSquare,
  Clock,
  RefreshCw,
  Users,
  MoreVertical,
  Camera,
  Plus,
  Eraser,
  Sparkles,
  Settings,
  Image as ImageIcon,
} from 'lucide-react';
import { Message, User, Conversation } from '../types';

interface ConversationsViewProps {
  onOpenReportModal: (msgSnippet?: string, senderName?: string) => void;
}

export const ConversationsView: React.FC<ConversationsViewProps> = ({ onOpenReportModal }) => {
  const {
    currentUser,
    conversations,
    startConversationWith,
    createGroup,
    deleteConversation,
    clearConversation,
    addConversationMembers,
    updateConversation,
    activeConversationId,
    setActiveConversationId,
    markConversationAsRead,
    messages,
    sendMessage,
    deleteMessage,
    users,
    isSyncing,
  } = useApp();

  const [activeTab, setActiveTab] = useState<'all' | 'direct' | 'groups'>('all');
  const [searchTerm, setSearchTerm] = useState('');
  const [inputText, setInputText] = useState('');
  const [isRecordingAudio, setIsRecordingAudio] = useState(false);
  const [audioPlayingId, setAudioPlayingId] = useState<string | null>(null);

  // Modais
  const [showNewChatModal, setShowNewChatModal] = useState(false);
  const [showNewGroupModal, setShowNewGroupModal] = useState(false);
  const [showAddMembersModal, setShowAddMembersModal] = useState(false);
  const [showEditGroupModal, setShowEditGroupModal] = useState(false);
  const [showOptionsMenu, setShowOptionsMenu] = useState(false);
  const [modalSearch, setModalSearch] = useState('');
  const [isStartingChat, setIsStartingChat] = useState<string | null>(null);
  const [modalError, setModalError] = useState<string | null>(null);

  // Diálogo de confirmação (Limpar ou Excluir)
  const [confirmDialog, setConfirmDialog] = useState<{
    open: boolean;
    title: string;
    description: string;
    actionType: 'clear' | 'delete';
  } | null>(null);

  // Formulário: Novo Grupo
  const [newGroupName, setNewGroupName] = useState('');
  const [newGroupPhoto, setNewGroupPhoto] = useState('');
  const [newGroupAutoDelete, setNewGroupAutoDelete] = useState(false);
  const [selectedGroupMemberIds, setSelectedGroupMemberIds] = useState<string[]>([]);
  const [isCreatingGroup, setIsCreatingGroup] = useState(false);

  // Formulário: Adicionar membros ao grupo ativo
  const [membersToAdd, setMembersToAdd] = useState<string[]>([]);
  const [isAddingMembers, setIsAddingMembers] = useState(false);

  // Formulário: Editar grupo
  const [editGroupName, setEditGroupName] = useState('');
  const [editGroupPhoto, setEditGroupPhoto] = useState('');
  const [isUpdatingGroup, setIsUpdatingGroup] = useState(false);

  // Active conversation
  const activeConv =
    (conversations && conversations.find((c) => c.id === activeConversationId)) ||
    conversations?.[0];

  // The other member in this individual chat
  const otherMember: User =
    activeConv?.membros?.find((m) => m.id !== currentUser.id) ||
    activeConv?.membros?.[0] ||
    (activeConv as any)?.outroMembro ||
    currentUser;

  // Filtered messages for this conversation
  const convMessages = activeConv
    ? messages.filter((m) => m.conversationId === activeConv.id)
    : [];

  const handleSend = (e: React.FormEvent) => {
    e.preventDefault();
    if (!inputText.trim() || !activeConv) return;
    sendMessage(activeConv.id, undefined, inputText, 'texto');
    setInputText('');
  };

  const handleSendAudioSim = () => {
    if (!activeConv) return;
    setIsRecordingAudio(true);
    setTimeout(() => {
      setIsRecordingAudio(false);
      sendMessage(activeConv.id, undefined, 'Mensagem de áudio gravada (0:14)', 'audio');
    }, 1200);
  };

  // Filter conversations
  const filteredConversations = (conversations || []).filter((c) => {
    const names = (c.membros || []).map((m) => m.nome?.toLowerCase() || '').join(' ');
    const otherName = (c as any).outroMembro?.nome?.toLowerCase() || '';
    return names.includes(searchTerm.toLowerCase()) || otherName.includes(searchTerm.toLowerCase());
  });

  const handleSelectUser = async (targetUser: User) => {
    try {
      setIsStartingChat(targetUser.id);
      setModalError(null);
      const convId = await startConversationWith(targetUser.id);
      setActiveConversationId(convId);
      markConversationAsRead(convId);
      setSearchTerm('');
      setShowNewChatModal(false);
      setModalSearch('');
    } catch (err: any) {
      setModalError(err.message || 'Não foi possível iniciar a conversa.');
    } finally {
      setIsStartingChat(null);
    }
  };

  const handleCreateGroupSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newGroupName.trim() || selectedGroupMemberIds.length === 0) {
      setModalError('Informe o nome do grupo e selecione ao menos um participante.');
      return;
    }
    try {
      setIsCreatingGroup(true);
      setModalError(null);
      const convId = await createGroup({
        nome: newGroupName.trim(),
        participantIds: selectedGroupMemberIds,
        fotoUrl: newGroupPhoto.trim() || undefined,
        autoExcluir24h: newGroupAutoDelete,
      });
      setShowNewGroupModal(false);
      setNewGroupName('');
      setNewGroupPhoto('');
      setSelectedGroupMemberIds([]);
      setNewGroupAutoDelete(false);
      setActiveConversationId(convId);
    } catch (err: any) {
      setModalError(err.message || 'Erro ao criar grupo hospitalar.');
    } finally {
      setIsCreatingGroup(false);
    }
  };

  const handleAddMembersSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!activeConv || membersToAdd.length === 0) return;
    try {
      setIsAddingMembers(true);
      await addConversationMembers(activeConv.id, membersToAdd);
      setShowAddMembersModal(false);
      setMembersToAdd([]);
    } catch (err: any) {
      alert(err.message || 'Erro ao adicionar participantes.');
    } finally {
      setIsAddingMembers(false);
    }
  };

  const handleUpdateGroupSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!activeConv) return;
    try {
      setIsUpdatingGroup(true);
      await updateConversation(activeConv.id, {
        nome: editGroupName.trim() || undefined,
        fotoUrl: editGroupPhoto.trim() || undefined,
      });
      setShowEditGroupModal(false);
    } catch (err: any) {
      alert(err.message || 'Erro ao atualizar grupo.');
    } finally {
      setIsUpdatingGroup(false);
    }
  };

  const handleConfirmAction = async () => {
    if (!confirmDialog || !activeConv) return;
    if (confirmDialog.actionType === 'clear') {
      await clearConversation(activeConv.id);
    } else if (confirmDialog.actionType === 'delete') {
      await deleteConversation(activeConv.id);
    }
    setConfirmDialog(null);
    setShowOptionsMenu(false);
  };

  // Contagens para as abas
  const countAll = (conversations || []).length;
  const countDirect = (conversations || []).filter((c) => c.tipo !== 'grupo').length;
  const countGroups = (conversations || []).filter((c) => c.tipo === 'grupo').length;

  // Filtro refinado por busca e aba ativa
  const filteredConversations = (conversations || []).filter((c) => {
    if (activeTab === 'direct' && c.tipo === 'grupo') return false;
    if (activeTab === 'groups' && c.tipo !== 'grupo') return false;

    if (!searchTerm.trim()) return true;
    const term = searchTerm.toLowerCase();
    const groupName = c.nome?.toLowerCase() || '';
    const names = (c.membros || []).map((m) => m.nome?.toLowerCase() || '').join(' ');
    const otherName = (c as any).outroMembro?.nome?.toLowerCase() || '';
    return groupName.includes(term) || names.includes(term) || otherName.includes(term);
  });

  const availableColleagues = users.filter((u) => {
    if (u.id === currentUser.id || !u.ativo) return false;
    if (!modalSearch.trim()) return true;
    const s = modalSearch.toLowerCase();
    return (
      u.nome.toLowerCase().includes(s) ||
      u.cargo.toLowerCase().includes(s) ||
      (u.setorNome && u.setorNome.toLowerCase().includes(s)) ||
      (u.matricula && u.matricula.toLowerCase().includes(s))
    );
  });

  return (
    <div className="h-[calc(100vh-8rem)] flex flex-col md:flex-row bg-white rounded-2xl border border-gray-200 overflow-hidden shadow-xs">
      {/* ─── Left Pane: Conversation List ──────────────────────────────── */}
      <div className="w-full md:w-84 border-r border-gray-200 flex flex-col bg-[#F9FAFB]">
        {/* Top bar with search & actions */}
        <div className="p-3 border-b border-gray-200 bg-white">
          <div className="flex items-center justify-between mb-2">
            <h2 className="font-bold text-sm text-gray-900 flex items-center gap-1.5">
              <MessageSquare className="w-4 h-4 text-blue-600" />
              Mensagens
            </h2>
            <div className="flex items-center gap-1">
              <button
                onClick={() => {
                  setModalError(null);
                  setNewGroupName('');
                  setNewGroupPhoto('');
                  setSelectedGroupMemberIds([]);
                  setNewGroupAutoDelete(false);
                  setShowNewGroupModal(true);
                }}
                className="p-1.5 text-indigo-700 bg-indigo-50 hover:bg-indigo-100 rounded-lg text-xs font-semibold flex items-center gap-1 transition"
                title="Criar novo grupo hospitalar"
              >
                <Users className="w-3.5 h-3.5" />
                <span className="text-[11px]">Grupo</span>
              </button>
              <button
                onClick={() => {
                  setModalError(null);
                  setModalSearch('');
                  setShowNewChatModal(true);
                }}
                className="p-1.5 text-blue-700 bg-blue-50 hover:bg-blue-100 rounded-lg text-xs font-semibold flex items-center gap-1 transition"
                title="Iniciar nova conversa direta"
              >
                <UserPlus className="w-3.5 h-3.5" />
                <span className="text-[11px]">Direta</span>
              </button>
            </div>
          </div>

          <div className="relative mb-2">
            <Search className="w-3.5 h-3.5 absolute left-3 top-2.5 text-gray-400" />
            <input
              type="text"
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              placeholder="Buscar colega, cargo ou grupo..."
              className="w-full pl-8 pr-3 py-1.5 text-xs bg-gray-100 border-none rounded-xl focus:ring-2 focus:ring-blue-500 focus:outline-none"
            />
          </div>

          {/* Abas de filtro: Todas / Diretas / Grupos */}
          <div className="flex items-center gap-1 bg-gray-100 p-1 rounded-xl text-xs font-medium">
            <button
              onClick={() => setActiveTab('all')}
              className={`flex-1 py-1 px-2 rounded-lg text-center transition flex items-center justify-center gap-1 ${
                activeTab === 'all'
                  ? 'bg-white text-gray-900 font-bold shadow-xs'
                  : 'text-gray-500 hover:text-gray-900'
              }`}
            >
              <span>Todas</span>
              <span className="text-[10px] bg-gray-200/80 px-1.5 py-0.2 rounded-full">{countAll}</span>
            </button>
            <button
              onClick={() => setActiveTab('direct')}
              className={`flex-1 py-1 px-2 rounded-lg text-center transition flex items-center justify-center gap-1 ${
                activeTab === 'direct'
                  ? 'bg-white text-blue-900 font-bold shadow-xs'
                  : 'text-gray-500 hover:text-gray-900'
              }`}
            >
              <span>Diretas</span>
              <span className="text-[10px] bg-blue-100 text-blue-800 px-1.5 py-0.2 rounded-full">{countDirect}</span>
            </button>
            <button
              onClick={() => setActiveTab('groups')}
              className={`flex-1 py-1 px-2 rounded-lg text-center transition flex items-center justify-center gap-1 ${
                activeTab === 'groups'
                  ? 'bg-white text-indigo-900 font-bold shadow-xs'
                  : 'text-gray-500 hover:text-gray-900'
              }`}
            >
              <Users className="w-3 h-3 text-indigo-600" />
              <span>Grupos</span>
              <span className="text-[10px] bg-indigo-100 text-indigo-800 px-1.5 py-0.2 rounded-full">{countGroups}</span>
            </button>
          </div>
        </div>

        {/* List items */}
        <div className="flex-1 overflow-y-auto divide-y divide-gray-100">
          {filteredConversations.length === 0 && isSyncing ? (
            /* Skeleton loading — conversas carregando */
            <div className="divide-y divide-gray-100">
              {[1, 2, 3, 4].map((i) => (
                <div key={i} className="p-3.5 flex items-start gap-3 animate-pulse">
                  <div className="w-10 h-10 rounded-full bg-gray-200 flex-shrink-0" />
                  <div className="flex-1 space-y-2">
                    <div className="flex items-center justify-between">
                      <div className="h-3 bg-gray-200 rounded w-24" />
                      <div className="h-2 bg-gray-100 rounded w-10" />
                    </div>
                    <div className="h-2 bg-gray-100 rounded w-20" />
                    <div className="h-3 bg-gray-200 rounded w-40" />
                  </div>
                </div>
              ))}
            </div>
          ) : filteredConversations.length === 0 ? (
            <div className="p-6 text-center text-gray-400 text-xs">
              <p>
                {activeTab === 'groups'
                  ? 'Nenhum grupo hospitalar encontrado.'
                  : activeTab === 'direct'
                  ? 'Nenhuma conversa direta ativa.'
                  : 'Nenhuma conversa ativa no momento.'}
              </p>
              <div className="flex items-center justify-center gap-2 mt-3">
                <button
                  onClick={() => {
                    setModalError(null);
                    setModalSearch('');
                    setShowNewChatModal(true);
                  }}
                  className="text-blue-600 hover:underline font-semibold"
                >
                  + Nova Direta
                </button>
                <span className="text-gray-300">·</span>
                <button
                  onClick={() => {
                    setModalError(null);
                    setShowNewGroupModal(true);
                  }}
                  className="text-indigo-600 hover:underline font-semibold"
                >
                  + Criar Grupo
                </button>
              </div>
            </div>
          ) : (
            filteredConversations.map((conv) => {
              const isGroup = conv.tipo === 'grupo';
              const member: User =
                conv.membros?.find((m) => m.id !== currentUser.id) ||
                conv.membros?.[0] ||
                (conv as any).outroMembro ||
                currentUser;
              const isSelected = conv.id === activeConv?.id;
              const displayName = isGroup ? (conv.nome || 'Grupo Hospitalar') : member.nome;

              return (
                <button
                  key={conv.id}
                  onClick={() => {
                    setActiveConversationId(conv.id);
                    markConversationAsRead(conv.id);
                  }}
                  className={`w-full text-left p-3.5 flex items-start gap-3 transition ${
                    isSelected
                      ? isGroup
                        ? 'bg-indigo-50/70 border-l-4 border-indigo-600'
                        : 'bg-blue-50/70 border-l-4 border-[#1565C0]'
                      : 'hover:bg-gray-100/70'
                  }`}
                >
                  {/* Avatar do Card */}
                  <div className="relative flex-shrink-0">
                    {isGroup ? (
                      conv.fotoUrl ? (
                        <img
                          src={conv.fotoUrl}
                          alt={displayName}
                          className="w-10 h-10 rounded-2xl object-cover border border-indigo-200 shadow-2xs"
                        />
                      ) : (
                        <div className="w-10 h-10 rounded-2xl bg-gradient-to-br from-indigo-500 to-blue-600 text-white flex items-center justify-center shadow-2xs font-bold">
                          <Users className="w-5 h-5" />
                        </div>
                      )
                    ) : (
                      <div className="w-10 h-10 rounded-full bg-blue-600 text-white font-bold text-sm flex items-center justify-center">
                        {(member.nome || 'U').charAt(0)}
                      </div>
                    )}
                    {!isGroup && (
                      <span className="absolute bottom-0 right-0 w-2.5 h-2.5 rounded-full bg-green-500 border-2 border-white" />
                    )}
                  </div>

                  <div className="flex-1 min-w-0">
                    <div className="flex items-center justify-between">
                      <div className="flex items-center gap-1.5 min-w-0 pr-1">
                        <h4 className={`font-semibold text-xs truncate ${isGroup ? 'text-indigo-950 font-bold' : 'text-gray-900'}`}>
                          {displayName}
                        </h4>
                        {isGroup && (
                          <span className="text-[9px] font-bold px-1.5 py-0.2 bg-indigo-100 text-indigo-700 rounded-md shrink-0 flex items-center gap-0.5">
                            <Users className="w-2.5 h-2.5" />
                            Grupo
                          </span>
                        )}
                      </div>
                      <span className="text-[10px] text-gray-400 shrink-0">
                        {conv.ultimaMensagemHora || '10:00'}
                      </span>
                    </div>

                    <div className="flex items-center gap-1.5 mt-0.5">
                      <p className="text-[11px] text-gray-500 truncate">
                        {isGroup ? `${conv.membros?.length || 2} participantes` : member.cargo}
                      </p>
                      {conv.autoExcluir24h && (
                        <span className="text-[9px] bg-amber-50 text-amber-700 border border-amber-200 px-1 py-0.2 rounded font-medium flex items-center gap-0.5" title="Auto-exclusão 24h ativada">
                          <Clock className="w-2.5 h-2.5 text-amber-600" />
                          24h
                        </span>
                      )}
                    </div>

                    <p className="text-xs text-gray-600 truncate mt-1">
                      {conv.ultimaMensagem || (isGroup ? 'Grupo criado.' : 'Iniciar conversa...')}
                    </p>
                  </div>

                  {conv.naoLidas > 0 && (
                    <span className="w-4 h-4 rounded-full bg-blue-600 text-white text-[10px] font-bold flex items-center justify-center flex-shrink-0 self-center">
                      {conv.naoLidas}
                    </span>
                  )}
                </button>
              );
            })
          )}
        </div>
      </div>

      {/* ─── Right Pane: Active Chat Window ─────────────────────────────── */}
      <div className="flex-1 flex flex-col bg-white">
        {!activeConv ? (
          <div className="flex-1 flex flex-col items-center justify-center p-8 text-center bg-[#F8FAFC]">
            <div className="w-14 h-14 rounded-2xl bg-blue-50 text-blue-600 flex items-center justify-center mb-3 border border-blue-100 shadow-xs">
              <MessageSquare className="w-6 h-6 text-blue-600" />
            </div>
            <h3 className="font-bold text-sm text-gray-900 mb-1">Nenhuma conversa selecionada</h3>
            <p className="text-xs text-gray-500 max-w-sm mb-4 leading-relaxed">
              Selecione um diálogo na lista à esquerda ou inicie uma nova conversa segura com um profissional da equipe hospitalar.
            </p>
            <button
              onClick={() => {
                setModalError(null);
                setModalSearch('');
                setShowNewChatModal(true);
              }}
              className="px-4 py-2 bg-[#1565C0] text-white text-xs font-semibold rounded-xl hover:bg-[#0D47A1] transition shadow-xs flex items-center gap-1.5"
            >
              <UserPlus className="w-4 h-4" />
              Iniciar Nova Conversa
            </button>
          </div>
        ) : (
          <>
            {/* Chat Header */}
            <div className="p-3.5 border-b border-gray-200 flex items-center justify-between bg-white relative z-20">
              <div className="flex items-center gap-3 min-w-0">
                {activeConv.tipo === 'grupo' ? (
                  <div
                    className="relative group cursor-pointer"
                    onClick={() => {
                      setEditGroupName(activeConv.nome || '');
                      setEditGroupPhoto(activeConv.fotoUrl || '');
                      setShowEditGroupModal(true);
                    }}
                    title="Alterar foto ou nome do grupo"
                  >
                    {activeConv.fotoUrl ? (
                      <img
                        src={activeConv.fotoUrl}
                        alt={activeConv.nome || 'Grupo'}
                        className="w-10 h-10 rounded-2xl object-cover border border-indigo-200 shadow-xs"
                      />
                    ) : (
                      <div className="w-10 h-10 rounded-2xl bg-gradient-to-br from-indigo-600 to-blue-600 text-white flex items-center justify-center font-bold shadow-xs">
                        <Users className="w-5 h-5" />
                      </div>
                    )}
                    <span className="absolute -bottom-1 -right-1 bg-white p-0.5 rounded-full shadow-xs border border-gray-200">
                      <Camera className="w-3 h-3 text-indigo-700" />
                    </span>
                  </div>
                ) : (
                  <div className="relative">
                    <div className="w-10 h-10 rounded-full bg-blue-600 text-white font-bold text-sm flex items-center justify-center">
                      {otherMember.nome.charAt(0)}
                    </div>
                    <span className="absolute bottom-0 right-0 w-2.5 h-2.5 rounded-full bg-green-500 border-2 border-white" />
                  </div>
                )}

                <div className="min-w-0">
                  <div className="flex items-center gap-2">
                    <h3 className="font-bold text-sm text-gray-900 truncate">
                      {activeConv.tipo === 'grupo' ? (activeConv.nome || 'Grupo Hospitalar') : otherMember.nome}
                    </h3>
                    {activeConv.tipo === 'grupo' ? (
                      <span className="text-[10px] font-bold px-2 py-0.5 bg-indigo-100 text-indigo-700 rounded-md shrink-0 flex items-center gap-1">
                        <Users className="w-3 h-3" />
                        GRUPO
                      </span>
                    ) : (
                      <HierarchyBadge level={otherMember.hierarquiaNivel} size="sm" />
                    )}
                    {activeConv.autoExcluir24h && (
                      <span className="text-[10px] bg-amber-50 text-amber-800 border border-amber-200 font-semibold px-2 py-0.5 rounded-md shrink-0 flex items-center gap-1" title="Auto-exclusão 24h ativada">
                        <Clock className="w-3 h-3 text-amber-600" />
                        24h
                      </span>
                    )}
                  </div>
                  <p className="text-[11px] text-gray-500 truncate mt-0.5">
                    {activeConv.tipo === 'grupo'
                      ? `${activeConv.membros?.length || 2} membros · ${(activeConv.membros || []).map((m) => m.nome.split(' ')[0]).join(', ')}`
                      : `${otherMember.cargo} · ${otherMember.setorNome || 'Unidade Hospitalar'}`}
                  </p>
                </div>
              </div>

              {/* Botões de Ação do Cabeçalho */}
              <div className="flex items-center gap-1.5 shrink-0">
                {activeConv.tipo === 'grupo' && (
                  <button
                    onClick={() => {
                      setMembersToAdd([]);
                      setShowAddMembersModal(true);
                    }}
                    className="px-2.5 py-1.5 bg-indigo-50 hover:bg-indigo-100 text-indigo-700 text-xs font-semibold rounded-xl transition flex items-center gap-1 border border-indigo-200/60 shadow-2xs"
                    title="Adicionar participantes ao grupo"
                  >
                    <Plus className="w-3.5 h-3.5" />
                    <span className="hidden sm:inline">Adicionar</span>
                  </button>
                )}

                {/* Dropdown de Mais Opções */}
                <div className="relative">
                  <button
                    onClick={() => setShowOptionsMenu(!showOptionsMenu)}
                    className="p-1.5 text-gray-500 hover:text-gray-700 hover:bg-gray-100 rounded-xl transition"
                    title="Opções da conversa"
                  >
                    <MoreVertical className="w-4 h-4" />
                  </button>

                  {showOptionsMenu && (
                    <div className="absolute right-0 mt-1 w-56 bg-white rounded-2xl shadow-xl border border-gray-200 py-1.5 text-xs text-gray-700 z-50 animate-in fade-in zoom-in-95 duration-100">
                      {activeConv.tipo === 'grupo' && (
                        <button
                          onClick={() => {
                            setEditGroupName(activeConv.nome || '');
                            setEditGroupPhoto(activeConv.fotoUrl || '');
                            setShowEditGroupModal(true);
                            setShowOptionsMenu(false);
                          }}
                          className="w-full text-left px-3.5 py-2 hover:bg-gray-50 flex items-center gap-2"
                        >
                          <Settings className="w-4 h-4 text-gray-500" />
                          <span>Editar foto e nome do grupo</span>
                        </button>
                      )}

                      <button
                        onClick={async () => {
                          const novoStatus = !activeConv.autoExcluir24h;
                          await updateConversation(activeConv.id, { autoExcluir24h: novoStatus });
                          setShowOptionsMenu(false);
                        }}
                        className="w-full text-left px-3.5 py-2 hover:bg-gray-50 flex items-center justify-between gap-2"
                      >
                        <div className="flex items-center gap-2">
                          <Clock className={`w-4 h-4 ${activeConv.autoExcluir24h ? 'text-amber-600' : 'text-gray-500'}`} />
                          <span>Auto-exclusão (24h)</span>
                        </div>
                        <span className={`text-[10px] font-bold px-1.5 py-0.2 rounded-full ${
                          activeConv.autoExcluir24h ? 'bg-amber-100 text-amber-800' : 'bg-gray-100 text-gray-500'
                        }`}>
                          {activeConv.autoExcluir24h ? 'Ativo' : 'Desligado'}
                        </span>
                      </button>

                      <div className="my-1 border-t border-gray-100" />

                      <button
                        onClick={() => {
                          setConfirmDialog({
                            open: true,
                            title: 'Limpar histórico da conversa?',
                            description: 'Todas as mensagens trocadas nesta conversa serão apagadas permanentemente. A conversa continuará ativa na sua lista.',
                            actionType: 'clear',
                          });
                          setShowOptionsMenu(false);
                        }}
                        className="w-full text-left px-3.5 py-2 hover:bg-amber-50 text-amber-700 flex items-center gap-2 font-medium"
                      >
                        <Eraser className="w-4 h-4 text-amber-600" />
                        <span>Limpar conversa</span>
                      </button>

                      <button
                        onClick={() => {
                          setConfirmDialog({
                            open: true,
                            title: activeConv.tipo === 'grupo' ? 'Sair e excluir grupo?' : 'Excluir esta conversa?',
                            description: activeConv.tipo === 'grupo'
                              ? 'Você sairá deste grupo e ele será removido da sua lista de conversas.'
                              : 'Esta conversa e todo o seu histórico serão excluídos da sua lista.',
                            actionType: 'delete',
                          });
                          setShowOptionsMenu(false);
                        }}
                        className="w-full text-left px-3.5 py-2 hover:bg-red-50 text-red-700 flex items-center gap-2 font-medium"
                      >
                        <Trash2 className="w-4 h-4 text-red-600" />
                        <span>Excluir conversa</span>
                      </button>
                    </div>
                  )}
                </div>
              </div>
            </div>

            {/* Banner de Mensagens Temporárias (se ativo) */}
            {activeConv.autoExcluir24h && (
              <div className="bg-gradient-to-r from-amber-50 to-orange-50 border-b border-amber-200 px-4 py-2 flex items-center justify-between text-xs text-amber-800">
                <div className="flex items-center gap-2">
                  <Clock className="w-4 h-4 text-amber-600 shrink-0" />
                  <span>
                    <strong>Mensagens temporárias de 24 horas ativadas.</strong> O histórico expira após 24 horas para conformidade e segurança clínica.
                  </span>
                </div>
                <button
                  onClick={() => updateConversation(activeConv.id, { autoExcluir24h: false })}
                  className="text-[11px] text-amber-700 hover:text-amber-900 underline font-bold shrink-0 ml-2"
                >
                  Desativar
                </button>
              </div>
            )}

        {/* Messages Stream */}
        <div className="flex-1 p-4 overflow-y-auto space-y-3 bg-[#F8FAFC]">
          <div className="text-center my-2">
            <span className="text-[10px] font-semibold text-gray-400 bg-gray-200/80 px-2.5 py-1 rounded-full">
              Comunicação Segura — Conexão Hospitalar Criptografada
            </span>
          </div>

          {convMessages.length === 0 ? (
            <div className="text-center py-12 text-gray-400 text-xs">
              Nenhuma mensagem trocada ainda. Envie uma mensagem para iniciar o atendimento.
            </div>
          ) : (
            convMessages.map((msg) => {
              const isMine = msg.remetenteId === currentUser.id;

              return (
                <div
                  key={msg.id}
                  className={`flex flex-col group ${isMine ? 'items-end' : 'items-start'}`}
                >
                  <div className="flex items-center gap-1.5 mb-0.5">
                    <span className="text-[10px] font-semibold text-gray-500">
                      {isMine ? 'Você' : msg.remetenteNome}
                    </span>
                    <span className="text-[9px] text-gray-400">{msg.createdAt}</span>
                  </div>

                  <div
                    className={`relative max-w-sm sm:max-w-md rounded-2xl px-3.5 py-2 text-xs shadow-xs leading-relaxed ${
                      msg.apagada
                        ? 'bg-gray-100 text-gray-400 italic border border-gray-200'
                        : isMine
                        ? 'bg-[#1565C0] text-white rounded-tr-xs'
                        : 'bg-white text-gray-800 border border-gray-200 rounded-tl-xs'
                    }`}
                  >
                    {msg.tipo === 'audio' ? (
                      <div className="flex items-center gap-2 py-1">
                        <button
                          onClick={() =>
                            setAudioPlayingId(audioPlayingId === msg.id ? null : msg.id)
                          }
                          className={`w-7 h-7 rounded-full flex items-center justify-center ${
                            isMine ? 'bg-white/20 text-white' : 'bg-blue-100 text-blue-700'
                          }`}
                        >
                          {audioPlayingId === msg.id ? (
                            <Pause className="w-3.5 h-3.5" />
                          ) : (
                            <Play className="w-3.5 h-3.5 translate-x-0.5" />
                          )}
                        </button>
                        <div className="flex-1">
                          <div
                            className={`h-1.5 rounded-full ${
                              isMine ? 'bg-white/30' : 'bg-gray-200'
                            }`}
                          >
                            <div
                              className={`h-full rounded-full transition-all ${
                                isMine ? 'bg-white' : 'bg-blue-600'
                              } ${audioPlayingId === msg.id ? 'w-3/4' : 'w-1/4'}`}
                            />
                          </div>
                          <span className="text-[9px] opacity-80 mt-0.5 block">0:14 Áudio gravado</span>
                        </div>
                      </div>
                    ) : (
                      <span>{msg.texto}</span>
                    )}

                    {/* Quick actions on hover */}
                    {!msg.apagada && (
                      <div
                        className={`absolute top-1 ${
                          isMine ? '-left-14' : '-right-14'
                        } hidden group-hover:flex items-center gap-1 bg-white p-1 rounded-lg border border-gray-200 shadow-xs z-10`}
                      >
                        {isMine && (
                          <button
                            onClick={() => deleteMessage(msg.id)}
                            className="p-1 text-gray-400 hover:text-red-600 transition"
                            title="Apagar mensagem"
                          >
                            <Trash2 className="w-3 h-3" />
                          </button>
                        )}
                        <button
                          onClick={() => onOpenReportModal(msg.texto, msg.remetenteNome)}
                          className="p-1 text-gray-400 hover:text-amber-600 transition"
                          title="Denunciar conduta"
                        >
                          <Flag className="w-3 h-3" />
                        </button>
                      </div>
                    )}
                  </div>

                  <div className="flex items-center gap-1 mt-0.5">
                    {isMine && (
                      msg.status === 'sending' ? (
                        <span className="text-[9px] text-gray-400 font-bold flex items-center gap-0.5">
                          <Clock className="w-3 h-3 animate-pulse" />
                          Enviando...
                        </span>
                      ) : msg.status === 'failed' ? (
                        <span className="text-[9px] text-red-500 font-bold flex items-center gap-1">
                          <AlertCircle className="w-3 h-3" />
                          Falha
                          <button
                            type="button"
                            onClick={() => {
                              sendMessage(msg.conversationId, msg.channelId, msg.texto, msg.tipo || 'texto');
                              deleteMessage(msg.id);
                            }}
                            className="ml-1 text-blue-600 hover:underline flex items-center gap-0.5"
                          >
                            <RefreshCw className="w-2.5 h-2.5" />
                            Reenviar
                          </button>
                        </span>
                      ) : (
                        <span className="text-[9px] text-blue-600 font-bold flex items-center">
                          {msg.lida ? (
                            <><CheckCheck className="w-3 h-3" />Lida</>
                          ) : (
                            <><Check className="w-3 h-3" />Enviada</>
                          )}
                        </span>
                      )
                    )}
                  </div>
                </div>
              );
            })
          )}
        </div>

        {/* Input Bar */}
        <form onSubmit={handleSend} className="p-3 border-t border-gray-200 bg-white">
          <div className="flex items-center gap-2">
            <button
              type="button"
              onClick={handleSendAudioSim}
              className={`p-2 rounded-xl border transition ${
                isRecordingAudio
                  ? 'bg-red-600 text-white border-red-600 animate-pulse'
                  : 'text-gray-500 border-gray-200 hover:bg-gray-100'
              }`}
              title="Gravar áudio institucional"
            >
              <Mic className="w-4 h-4" />
            </button>

            <input
              type="text"
              value={inputText}
              onChange={(e) => setInputText(e.target.value)}
              placeholder="Digite sua mensagem institucional..."
              className="flex-1 text-xs p-2.5 border border-gray-300 rounded-xl focus:ring-2 focus:ring-blue-500 focus:outline-none"
            />

            <button
              type="submit"
              disabled={!inputText.trim()}
              className="p-2.5 bg-[#1565C0] text-white rounded-xl hover:bg-[#0D47A1] disabled:opacity-40 transition shadow-xs"
            >
              <Send className="w-4 h-4" />
            </button>
          </div>
        </form>
        </>
      )}
      </div>

      {/* Modal: New Chat */}
      {showNewChatModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-xs">
          <div className="bg-white rounded-2xl max-w-md w-full p-5 shadow-2xl border border-gray-200 animate-in fade-in zoom-in-95 duration-150">
            <div className="flex items-center justify-between mb-2">
              <div className="flex items-center gap-2">
                <div className="w-8 h-8 rounded-lg bg-blue-100 text-blue-700 flex items-center justify-center font-bold">
                  <UserPlus className="w-4 h-4" />
                </div>
                <div>
                  <h3 className="font-bold text-sm text-gray-900">Iniciar Nova Conversa</h3>
                  <p className="text-[11px] text-gray-500">
                    Selecione um profissional do complexo hospitalar
                  </p>
                </div>
              </div>
              <button
                onClick={() => {
                  setShowNewChatModal(false);
                  setModalError(null);
                }}
                className="p-1.5 text-gray-400 hover:text-gray-600 hover:bg-gray-100 rounded-lg transition"
              >
                <X className="w-4 h-4" />
              </button>
            </div>

            {modalError && (
              <div className="mb-3 p-3 bg-red-50 border border-red-200 rounded-xl flex items-start gap-2 text-xs text-red-700">
                <AlertCircle className="w-4 h-4 text-red-600 shrink-0 mt-0.5" />
                <span>{modalError}</span>
              </div>
            )}

            {/* Search within Modal */}
            <div className="relative my-3">
              <Search className="w-3.5 h-3.5 absolute left-3 top-2.5 text-gray-400" />
              <input
                type="text"
                value={modalSearch}
                onChange={(e) => setModalSearch(e.target.value)}
                placeholder="Filtrar por nome, cargo ou centro hospitalar..."
                className="w-full pl-8 pr-3 py-2 text-xs bg-gray-50 border border-gray-200 rounded-xl focus:ring-2 focus:ring-blue-500 focus:bg-white focus:outline-none"
                autoFocus
              />
            </div>

            {/* Colleagues List */}
            <div className="max-h-64 overflow-y-auto divide-y divide-gray-100 border border-gray-100 rounded-xl">
              {availableColleagues.length === 0 ? (
                <div className="p-6 text-center text-gray-400 text-xs">
                  {modalSearch
                    ? 'Nenhum profissional encontrado com esse termo.'
                    : 'Nenhum outro profissional disponível no seu centro de atuação.'}
                </div>
              ) : (
                availableColleagues.map((u) => {
                  const hasExisting = (conversations || []).some(
                    (c) => c.membros?.some((m) => m.id === u.id) || (c as any).membroIds?.includes(u.id)
                  );
                  const isBusy = isStartingChat === u.id;

                  return (
                    <button
                      key={u.id}
                      type="button"
                      disabled={isStartingChat !== null}
                      onClick={() => handleSelectUser(u)}
                      className="w-full text-left p-3 hover:bg-blue-50/70 transition text-xs flex items-center justify-between gap-3 disabled:opacity-60 cursor-pointer"
                    >
                      <div className="flex items-center gap-2.5 min-w-0">
                        <div className="w-8 h-8 rounded-full bg-blue-600 text-white font-bold text-xs flex items-center justify-center shrink-0">
                          {u.nome.charAt(0)}
                        </div>
                        <div className="min-w-0">
                          <div className="font-semibold text-gray-900 truncate flex items-center gap-1.5">
                            <span className="truncate">{u.nome}</span>
                            {hasExisting && (
                              <span className="text-[9px] font-normal px-1.5 py-0.2 bg-blue-100 text-blue-700 rounded-full shrink-0">
                                Conversa existente
                              </span>
                            )}
                          </div>
                          <div className="text-[10px] text-gray-500 truncate">
                            {u.cargo} · {u.setorNome || 'Unidade Hospitalar'}
                          </div>
                        </div>
                      </div>

                      <div className="shrink-0 flex items-center gap-1.5">
                        {isBusy ? (
                          <span className="flex items-center gap-1 text-[11px] text-blue-700 font-semibold">
                            <Loader2 className="w-3.5 h-3.5 animate-spin" />
                            Abrindo...
                          </span>
                        ) : (
                          <HierarchyBadge level={u.hierarquiaNivel} size="sm" />
                        )}
                      </div>
                    </button>
                  );
                })
              )}
            </div>

            <div className="mt-4 flex items-center justify-between pt-2 border-t border-gray-100 text-xs">
              <span className="text-[11px] text-gray-400">
                {availableColleagues.length} profissional(is) listado(s)
              </span>
              <button
                type="button"
                onClick={() => {
                  setShowNewChatModal(false);
                  setModalError(null);
                }}
                className="px-3 py-1.5 text-xs text-gray-600 hover:bg-gray-100 rounded-lg transition"
              >
                Cancelar
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Modal: Novo Grupo Hospitalar */}
      {showNewGroupModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-xs">
          <div className="bg-white rounded-2xl max-w-lg w-full p-5 shadow-2xl border border-gray-200 animate-in fade-in zoom-in-95 duration-150">
            <div className="flex items-center justify-between mb-3 pb-2 border-b border-gray-100">
              <div className="flex items-center gap-2">
                <div className="w-8 h-8 rounded-lg bg-indigo-100 text-indigo-700 flex items-center justify-center font-bold">
                  <Users className="w-4 h-4" />
                </div>
                <div>
                  <h3 className="font-bold text-sm text-gray-900">Criar Novo Grupo Hospitalar</h3>
                  <p className="text-[11px] text-gray-500">
                    Comunicação em equipe com isolamento setorial seguro
                  </p>
                </div>
              </div>
              <button
                onClick={() => {
                  setShowNewGroupModal(false);
                  setModalError(null);
                }}
                className="p-1.5 text-gray-400 hover:text-gray-600 hover:bg-gray-100 rounded-lg transition"
              >
                <X className="w-4 h-4" />
              </button>
            </div>

            {modalError && (
              <div className="mb-3 p-3 bg-red-50 border border-red-200 rounded-xl flex items-start gap-2 text-xs text-red-700">
                <AlertCircle className="w-4 h-4 text-red-600 shrink-0 mt-0.5" />
                <span>{modalError}</span>
              </div>
            )}

            <form onSubmit={handleCreateGroupSubmit} className="space-y-3.5">
              <div>
                <label className="block text-xs font-semibold text-gray-700 mb-1">
                  Nome do Grupo *
                </label>
                <input
                  type="text"
                  required
                  value={newGroupName}
                  onChange={(e) => setNewGroupName(e.target.value)}
                  placeholder="Ex: Plantão CCO - Equipe Noturna"
                  className="w-full text-xs p-2.5 bg-gray-50 border border-gray-200 rounded-xl focus:ring-2 focus:ring-indigo-500 focus:bg-white focus:outline-none"
                />
              </div>

              <div>
                <label className="block text-xs font-semibold text-gray-700 mb-1">
                  Foto do Grupo (URL opcional)
                </label>
                <div className="flex items-center gap-2">
                  <input
                    type="url"
                    value={newGroupPhoto}
                    onChange={(e) => setNewGroupPhoto(e.target.value)}
                    placeholder="https://exemplo.com/foto.jpg"
                    className="flex-1 text-xs p-2.5 bg-gray-50 border border-gray-200 rounded-xl focus:ring-2 focus:ring-indigo-500 focus:bg-white focus:outline-none"
                  />
                  {newGroupPhoto && (
                    <img
                      src={newGroupPhoto}
                      alt="Preview"
                      className="w-9 h-9 rounded-xl object-cover border border-gray-200 shrink-0"
                      onError={() => setNewGroupPhoto('')}
                    />
                  )}
                </div>
              </div>

              {/* Toggle Auto-exclusão 24h */}
              <div className="p-3 bg-amber-50/70 border border-amber-200/80 rounded-xl flex items-center justify-between">
                <div className="flex items-start gap-2 pr-3">
                  <Clock className="w-4 h-4 text-amber-600 mt-0.5 shrink-0" />
                  <div>
                    <h5 className="text-xs font-bold text-amber-900">Auto-exclusão após 24 horas</h5>
                    <p className="text-[11px] text-amber-700">
                      As mensagens deste grupo expiram automaticamente após 24h (ideal para trocas de plantão).
                    </p>
                  </div>
                </div>
                <input
                  type="checkbox"
                  checked={newGroupAutoDelete}
                  onChange={(e) => setNewGroupAutoDelete(e.target.checked)}
                  className="w-4 h-4 rounded text-indigo-600 focus:ring-indigo-500 cursor-pointer"
                />
              </div>

              <div>
                <label className="block text-xs font-semibold text-gray-700 mb-1">
                  Selecione os Participantes ({selectedGroupMemberIds.length} selecionados) *
                </label>
                <div className="max-h-48 overflow-y-auto divide-y divide-gray-100 border border-gray-200 rounded-xl bg-gray-50/50">
                  {availableColleagues.map((u) => {
                    const isSelected = selectedGroupMemberIds.includes(u.id);
                    return (
                      <div
                        key={u.id}
                        onClick={() => {
                          if (isSelected) {
                            setSelectedGroupMemberIds(selectedGroupMemberIds.filter((id) => id !== u.id));
                          } else {
                            setSelectedGroupMemberIds([...selectedGroupMemberIds, u.id]);
                          }
                        }}
                        className={`p-2.5 flex items-center justify-between cursor-pointer transition text-xs ${
                          isSelected ? 'bg-indigo-50/80' : 'hover:bg-gray-100/70'
                        }`}
                      >
                        <div className="flex items-center gap-2 min-w-0">
                          <input
                            type="checkbox"
                            checked={isSelected}
                            onChange={() => {}}
                            className="w-3.5 h-3.5 rounded text-indigo-600 focus:ring-indigo-500 pointer-events-none"
                          />
                          <div className="w-7 h-7 rounded-full bg-blue-600 text-white font-bold text-[11px] flex items-center justify-center shrink-0">
                            {u.nome.charAt(0)}
                          </div>
                          <div className="min-w-0">
                            <p className="font-semibold text-gray-900 truncate">{u.nome}</p>
                            <p className="text-[10px] text-gray-500 truncate">{u.cargo} · {u.setorNome}</p>
                          </div>
                        </div>
                        <HierarchyBadge level={u.hierarquiaNivel} size="sm" />
                      </div>
                    );
                  })}
                </div>
              </div>

              <div className="flex items-center justify-end gap-2 pt-2 border-t border-gray-100">
                <button
                  type="button"
                  onClick={() => setShowNewGroupModal(false)}
                  className="px-3 py-2 text-xs text-gray-600 hover:bg-gray-100 rounded-xl transition font-medium"
                >
                  Cancelar
                </button>
                <button
                  type="submit"
                  disabled={isCreatingGroup || !newGroupName.trim() || selectedGroupMemberIds.length === 0}
                  className="px-4 py-2 bg-indigo-600 text-white text-xs font-semibold rounded-xl hover:bg-indigo-700 disabled:opacity-50 transition shadow-xs flex items-center gap-1.5"
                >
                  {isCreatingGroup ? (
                    <>
                      <Loader2 className="w-3.5 h-3.5 animate-spin" />
                      Criando...
                    </>
                  ) : (
                    <>
                      <Users className="w-3.5 h-3.5" />
                      Criar Grupo
                    </>
                  )}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Modal: Adicionar Participantes ao Grupo Ativo */}
      {showAddMembersModal && activeConv && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-xs">
          <div className="bg-white rounded-2xl max-w-md w-full p-5 shadow-2xl border border-gray-200 animate-in fade-in zoom-in-95 duration-150">
            <div className="flex items-center justify-between mb-3 pb-2 border-b border-gray-100">
              <div className="flex items-center gap-2">
                <div className="w-8 h-8 rounded-lg bg-indigo-100 text-indigo-700 flex items-center justify-center font-bold">
                  <Plus className="w-4 h-4" />
                </div>
                <div>
                  <h3 className="font-bold text-sm text-gray-900">Adicionar Participantes</h3>
                  <p className="text-[11px] text-gray-500">
                    Ao grupo: {activeConv.nome || 'Grupo Hospitalar'}
                  </p>
                </div>
              </div>
              <button
                onClick={() => setShowAddMembersModal(false)}
                className="p-1.5 text-gray-400 hover:text-gray-600 hover:bg-gray-100 rounded-lg transition"
              >
                <X className="w-4 h-4" />
              </button>
            </div>

            <form onSubmit={handleAddMembersSubmit} className="space-y-3.5">
              <div className="max-h-60 overflow-y-auto divide-y divide-gray-100 border border-gray-200 rounded-xl bg-gray-50/50">
                {users
                  .filter((u) => u.ativo && !(activeConv.membros || []).some((m) => m.id === u.id))
                  .map((u) => {
                    const isSelected = membersToAdd.includes(u.id);
                    return (
                      <div
                        key={u.id}
                        onClick={() => {
                          if (isSelected) {
                            setMembersToAdd(membersToAdd.filter((id) => id !== u.id));
                          } else {
                            setMembersToAdd([...membersToAdd, u.id]);
                          }
                        }}
                        className={`p-2.5 flex items-center justify-between cursor-pointer transition text-xs ${
                          isSelected ? 'bg-indigo-50/80' : 'hover:bg-gray-100/70'
                        }`}
                      >
                        <div className="flex items-center gap-2 min-w-0">
                          <input
                            type="checkbox"
                            checked={isSelected}
                            onChange={() => {}}
                            className="w-3.5 h-3.5 rounded text-indigo-600 focus:ring-indigo-500 pointer-events-none"
                          />
                          <div className="w-7 h-7 rounded-full bg-blue-600 text-white font-bold text-[11px] flex items-center justify-center shrink-0">
                            {u.nome.charAt(0)}
                          </div>
                          <div className="min-w-0">
                            <p className="font-semibold text-gray-900 truncate">{u.nome}</p>
                            <p className="text-[10px] text-gray-500 truncate">{u.cargo} · {u.setorNome}</p>
                          </div>
                        </div>
                        <HierarchyBadge level={u.hierarquiaNivel} size="sm" />
                      </div>
                    );
                  })}
              </div>

              <div className="flex items-center justify-end gap-2 pt-2 border-t border-gray-100">
                <button
                  type="button"
                  onClick={() => setShowAddMembersModal(false)}
                  className="px-3 py-2 text-xs text-gray-600 hover:bg-gray-100 rounded-xl transition font-medium"
                >
                  Cancelar
                </button>
                <button
                  type="submit"
                  disabled={isAddingMembers || membersToAdd.length === 0}
                  className="px-4 py-2 bg-indigo-600 text-white text-xs font-semibold rounded-xl hover:bg-indigo-700 disabled:opacity-50 transition shadow-xs flex items-center gap-1.5"
                >
                  {isAddingMembers ? (
                    <>
                      <Loader2 className="w-3.5 h-3.5 animate-spin" />
                      Adicionando...
                    </>
                  ) : (
                    <>
                      <Plus className="w-3.5 h-3.5" />
                      Adicionar {membersToAdd.length} participante(s)
                    </>
                  )}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Modal: Editar Nome e Foto do Grupo */}
      {showEditGroupModal && activeConv && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-xs">
          <div className="bg-white rounded-2xl max-w-md w-full p-5 shadow-2xl border border-gray-200 animate-in fade-in zoom-in-95 duration-150">
            <div className="flex items-center justify-between mb-3 pb-2 border-b border-gray-100">
              <div className="flex items-center gap-2">
                <div className="w-8 h-8 rounded-lg bg-indigo-100 text-indigo-700 flex items-center justify-center font-bold">
                  <Camera className="w-4 h-4" />
                </div>
                <div>
                  <h3 className="font-bold text-sm text-gray-900">Editar Grupo</h3>
                  <p className="text-[11px] text-gray-500">
                    Altere o nome ou a foto deste grupo
                  </p>
                </div>
              </div>
              <button
                onClick={() => setShowEditGroupModal(false)}
                className="p-1.5 text-gray-400 hover:text-gray-600 hover:bg-gray-100 rounded-lg transition"
              >
                <X className="w-4 h-4" />
              </button>
            </div>

            <form onSubmit={handleUpdateGroupSubmit} className="space-y-3.5">
              <div>
                <label className="block text-xs font-semibold text-gray-700 mb-1">
                  Nome do Grupo
                </label>
                <input
                  type="text"
                  required
                  value={editGroupName}
                  onChange={(e) => setEditGroupName(e.target.value)}
                  className="w-full text-xs p-2.5 bg-gray-50 border border-gray-200 rounded-xl focus:ring-2 focus:ring-indigo-500 focus:bg-white focus:outline-none"
                />
              </div>

              <div>
                <label className="block text-xs font-semibold text-gray-700 mb-1">
                  URL da Foto do Grupo
                </label>
                <div className="flex items-center gap-2">
                  <input
                    type="url"
                    value={editGroupPhoto}
                    onChange={(e) => setEditGroupPhoto(e.target.value)}
                    placeholder="https://exemplo.com/foto.jpg"
                    className="flex-1 text-xs p-2.5 bg-gray-50 border border-gray-200 rounded-xl focus:ring-2 focus:ring-indigo-500 focus:bg-white focus:outline-none"
                  />
                  {editGroupPhoto && (
                    <img
                      src={editGroupPhoto}
                      alt="Preview"
                      className="w-9 h-9 rounded-xl object-cover border border-gray-200 shrink-0"
                      onError={() => setEditGroupPhoto('')}
                    />
                  )}
                </div>
              </div>

              <div className="flex items-center justify-end gap-2 pt-2 border-t border-gray-100">
                <button
                  type="button"
                  onClick={() => setShowEditGroupModal(false)}
                  className="px-3 py-2 text-xs text-gray-600 hover:bg-gray-100 rounded-xl transition font-medium"
                >
                  Cancelar
                </button>
                <button
                  type="submit"
                  disabled={isUpdatingGroup || !editGroupName.trim()}
                  className="px-4 py-2 bg-indigo-600 text-white text-xs font-semibold rounded-xl hover:bg-indigo-700 disabled:opacity-50 transition shadow-xs flex items-center gap-1.5"
                >
                  {isUpdatingGroup ? (
                    <>
                      <Loader2 className="w-3.5 h-3.5 animate-spin" />
                      Salvando...
                    </>
                  ) : (
                    'Salvar Alterações'
                  )}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Diálogo de Confirmação: Limpar Conversa ou Excluir Conversa */}
      {confirmDialog && confirmDialog.open && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-xs">
          <div className="bg-white rounded-2xl max-w-sm w-full p-5 shadow-2xl border border-gray-200 animate-in fade-in zoom-in-95 duration-150">
            <div className="flex items-center gap-3 mb-3">
              <div className={`w-10 h-10 rounded-2xl flex items-center justify-center shrink-0 ${
                confirmDialog.actionType === 'clear' ? 'bg-amber-100 text-amber-700' : 'bg-red-100 text-red-700'
              }`}>
                {confirmDialog.actionType === 'clear' ? (
                  <Eraser className="w-5 h-5" />
                ) : (
                  <Trash2 className="w-5 h-5" />
                )}
              </div>
              <div>
                <h4 className="font-bold text-sm text-gray-900">{confirmDialog.title}</h4>
                <p className="text-[11px] text-gray-500 mt-0.5">{confirmDialog.description}</p>
              </div>
            </div>

            <div className="flex items-center justify-end gap-2 mt-4 pt-3 border-t border-gray-100">
              <button
                type="button"
                onClick={() => setConfirmDialog(null)}
                className="px-3 py-1.5 text-xs text-gray-600 hover:bg-gray-100 rounded-xl transition font-medium"
              >
                Cancelar
              </button>
              <button
                type="button"
                onClick={handleConfirmAction}
                className={`px-4 py-1.5 text-xs font-semibold rounded-xl text-white transition shadow-xs ${
                  confirmDialog.actionType === 'clear'
                    ? 'bg-amber-600 hover:bg-amber-700'
                    : 'bg-red-600 hover:bg-red-700'
                }`}
              >
                {confirmDialog.actionType === 'clear' ? 'Sim, Limpar Histórico' : 'Sim, Excluir Conversa'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
