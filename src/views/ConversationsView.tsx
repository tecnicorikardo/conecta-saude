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
  Phone,
  Video,
  Info,
  X,
  Loader2,
  AlertCircle,
  MessageSquare,
} from 'lucide-react';
import { Message, User } from '../types';

interface ConversationsViewProps {
  onOpenReportModal: (msgSnippet?: string, senderName?: string) => void;
}

export const ConversationsView: React.FC<ConversationsViewProps> = ({ onOpenReportModal }) => {
  const {
    currentUser,
    conversations,
    startConversationWith,
    activeConversationId,
    setActiveConversationId,
    markConversationAsRead,
    messages,
    sendMessage,
    deleteMessage,
    users,
  } = useApp();

  const [searchTerm, setSearchTerm] = useState('');
  const [inputText, setInputText] = useState('');
  const [isRecordingAudio, setIsRecordingAudio] = useState(false);
  const [audioPlayingId, setAudioPlayingId] = useState<string | null>(null);
  const [showNewChatModal, setShowNewChatModal] = useState(false);
  const [modalSearch, setModalSearch] = useState('');
  const [isStartingChat, setIsStartingChat] = useState<string | null>(null);
  const [modalError, setModalError] = useState<string | null>(null);

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
      <div className="w-full md:w-80 border-r border-gray-200 flex flex-col bg-[#F9FAFB]">
        {/* Top bar with search & new chat */}
        <div className="p-3 border-b border-gray-200 bg-white">
          <div className="flex items-center justify-between mb-2">
            <h2 className="font-bold text-sm text-gray-900">Conversas Diretas</h2>
            <button
              onClick={() => {
                setModalError(null);
                setModalSearch('');
                setShowNewChatModal(true);
              }}
              className="p-1.5 text-blue-700 bg-blue-50 hover:bg-blue-100 rounded-lg text-xs font-semibold flex items-center gap-1.5 transition"
              title="Iniciar nova conversa"
            >
              <UserPlus className="w-4 h-4" />
              <span className="text-[11px]">Nova</span>
            </button>
          </div>

          <div className="relative">
            <Search className="w-3.5 h-3.5 absolute left-3 top-2.5 text-gray-400" />
            <input
              type="text"
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              placeholder="Buscar colega ou cargo..."
              className="w-full pl-8 pr-3 py-1.5 text-xs bg-gray-100 border-none rounded-xl focus:ring-2 focus:ring-blue-500 focus:outline-none"
            />
          </div>
        </div>

        {/* List items */}
        <div className="flex-1 overflow-y-auto divide-y divide-gray-100">
          {filteredConversations.length === 0 ? (
            <div className="p-6 text-center text-gray-400 text-xs">
              <p>Nenhuma conversa ativa no momento.</p>
              <button
                onClick={() => {
                  setModalError(null);
                  setModalSearch('');
                  setShowNewChatModal(true);
                }}
                className="mt-3 text-blue-600 hover:underline font-semibold"
              >
                + Iniciar nova conversa
              </button>
            </div>
          ) : (
            filteredConversations.map((conv) => {
              const member: User =
                conv.membros?.find((m) => m.id !== currentUser.id) ||
                conv.membros?.[0] ||
                (conv as any).outroMembro ||
                currentUser;
              const isSelected = conv.id === activeConv?.id;

              return (
                <button
                  key={conv.id}
                  onClick={() => {
                    setActiveConversationId(conv.id);
                    markConversationAsRead(conv.id);
                  }}
                  className={`w-full text-left p-3.5 flex items-start gap-3 transition ${
                    isSelected ? 'bg-blue-50/70 border-l-4 border-[#1565C0]' : 'hover:bg-gray-100/70'
                  }`}
                >
                  <div className="relative">
                    <div className="w-10 h-10 rounded-full bg-blue-600 text-white font-bold text-sm flex items-center justify-center flex-shrink-0">
                      {(member.nome || 'U').charAt(0)}
                    </div>
                    <span className="absolute bottom-0 right-0 w-2.5 h-2.5 rounded-full bg-green-500 border-2 border-white" />
                  </div>

                  <div className="flex-1 min-w-0">
                    <div className="flex items-center justify-between">
                      <h4 className="font-semibold text-xs text-gray-900 truncate">
                        {member.nome}
                      </h4>
                      <span className="text-[10px] text-gray-400">
                        {conv.ultimaMensagemHora || '10:00'}
                      </span>
                    </div>

                    <p className="text-[11px] text-gray-500 truncate">{member.cargo}</p>

                    <p className="text-xs text-gray-600 truncate mt-1">
                      {conv.ultimaMensagem || 'Iniciar conversa...'}
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
            <div className="p-3.5 border-b border-gray-200 flex items-center justify-between bg-white">
              <div className="flex items-center gap-3">
                <div className="w-9 h-9 rounded-full bg-blue-600 text-white font-bold text-sm flex items-center justify-center">
                  {otherMember.nome.charAt(0)}
                </div>
                <div>
                  <div className="flex items-center gap-2">
                    <h3 className="font-bold text-sm text-gray-900">{otherMember.nome}</h3>
                    <HierarchyBadge level={otherMember.hierarquiaNivel} size="sm" />
                  </div>
                  <p className="text-[11px] text-gray-500">
                    {otherMember.cargo} · {otherMember.setorNome}
                  </p>
                </div>
              </div>

              <div className="flex items-center gap-2 text-gray-400">
                <span className="text-[11px] font-semibold text-green-700 bg-green-50 px-2 py-0.5 rounded-full border border-green-200">
                  ● Online no Plantão
                </span>
              </div>
            </div>

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
                      <span className="text-[9px] text-blue-600 font-bold flex items-center">
                        <CheckCheck className="w-3 h-3" />
                        {msg.lida ? 'Lida' : 'Enviada'}
                      </span>
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
    </div>
  );
};
