import React, { useState } from 'react';
import { useApp } from '../context/AppContext';
import {
  Radio,
  Lock,
  Users,
  Send,
  AlertTriangle,
  Building2,
  ShieldCheck,
  CheckCircle2,
  Info,
} from 'lucide-react';
import { Channel } from '../types';

export const ChannelsView: React.FC = () => {
  const {
    currentUser,
    channels,
    activeChannelId,
    setActiveChannelId,
    messages,
    sendMessage,
    isAdmin,
    userCenterSigla,
    isSyncing,
  } = useApp();

  const [inputMessage, setInputMessage] = useState('');

  // Check channel access rules according to institutional isolation
  const canAccessChannel = (ch?: Channel) => {
    if (!ch) return false;
    // Direção Geral has global access to all channels
    if (isAdmin) return true;
    // Institutional and Emergency channels are open to all hospital staff
    if (ch.tipo === 'institucional' || ch.tipo === 'emergencia') return true;
    // Sector channels: only matching center
    if (ch.setorSigla === userCenterSigla) return true;
    return false;
  };

  const activeChannel =
    (channels && channels.find((c) => c.id === activeChannelId)) || channels?.[0];
  const hasAccessToActive = activeChannel ? canAccessChannel(activeChannel) : false;

  const channelMessages = activeChannel
    ? messages.filter((m) => m.channelId === activeChannel.id)
    : [];

  const handleSendMessage = (e: React.FormEvent) => {
    e.preventDefault();
    if (!inputMessage.trim() || !hasAccessToActive || !activeChannel) return;
    sendMessage(undefined, activeChannel.id, inputMessage, 'texto');
    setInputMessage('');
  };

  return (
    <div className="h-[calc(100vh-8rem)] flex flex-col md:flex-row bg-white rounded-2xl border border-gray-200 overflow-hidden shadow-xs">
      {/* ─── Left Pane: Channels Directory ─────────────────────────────── */}
      <div className="w-full md:w-80 border-r border-gray-200 flex flex-col bg-[#F9FAFB]">
        <div className="p-3.5 border-b border-gray-200 bg-white">
          <div className="flex items-center gap-2">
            <Radio className="w-4 h-4 text-[#1565C0]" />
            <h2 className="font-bold text-sm text-gray-900">Canais Oficiais</h2>
          </div>
          <p className="text-[11px] text-gray-500 mt-0.5">
            Isolamento estrito conforme setor hospitalar
          </p>
        </div>

        <div className="p-2 border-b border-gray-200 bg-blue-50/50 flex items-center justify-between text-[11px]">
          <span className="text-gray-600">Seu Setor:</span>
          <span className="font-bold text-blue-900 bg-white px-2 py-0.5 rounded border border-blue-200">
            {userCenterSigla}
          </span>
        </div>

        <div className="flex-1 overflow-y-auto p-2 space-y-1">
          {channels.length === 0 && isSyncing ? (
            /* Skeleton loading — canais carregando */
            <div className="space-y-1">
              {[1, 2, 3].map((i) => (
                <div key={i} className="p-3 rounded-xl flex items-start gap-2.5 animate-pulse">
                  <div className="w-8 h-8 rounded-lg bg-gray-200 flex-shrink-0" />
                  <div className="flex-1 space-y-2">
                    <div className="h-3 bg-gray-200 rounded w-32" />
                    <div className="h-2 bg-gray-100 rounded w-48" />
                  </div>
                </div>
              ))}
            </div>
          ) : channels.length === 0 ? (
            <div className="p-4 text-center text-gray-400 text-xs">
              Carregando canais disponíveis...
            </div>
          ) : (
            channels.map((ch) => {
              const isSelected = ch.id === activeChannel?.id;
              const accessible = canAccessChannel(ch);
              const isEmergency = ch.tipo === 'emergencia';

              return (
                <button
                  key={ch.id}
                  onClick={() => setActiveChannelId(ch.id)}
                  className={`w-full text-left p-3 rounded-xl transition flex items-start gap-2.5 ${
                    isSelected
                      ? isEmergency
                        ? 'bg-red-50 border border-red-300'
                        : 'bg-blue-50/80 border border-blue-200 shadow-xs'
                      : 'hover:bg-gray-100/70'
                  } ${!accessible ? 'opacity-50' : ''}`}
                >
                  <div
                    className={`w-8 h-8 rounded-lg flex items-center justify-center flex-shrink-0 text-xs font-bold ${
                      isEmergency
                        ? 'bg-red-600 text-white'
                        : accessible
                        ? 'bg-blue-100 text-blue-800'
                        : 'bg-gray-200 text-gray-500'
                    }`}
                  >
                    {isEmergency ? '🚨' : accessible ? '#' : <Lock className="w-3.5 h-3.5" />}
                  </div>

                  <div className="flex-1 min-w-0">
                    <div className="flex items-center justify-between">
                      <h4
                        className={`font-semibold text-xs truncate ${
                          isSelected ? 'text-blue-900 font-bold' : 'text-gray-800'
                        }`}
                      >
                        {ch.nome}
                      </h4>
                      {!accessible && (
                        <span className="text-[9px] bg-gray-200 text-gray-600 px-1.5 py-0.5 rounded font-mono">
                          Bloqueado
                        </span>
                      )}
                    </div>
                    <p className="text-[11px] text-gray-500 truncate mt-0.5">{ch.descricao}</p>
                  </div>
                </button>
              );
            })
          )}
        </div>
      </div>

      {/* ─── Right Pane: Channel Feed ──────────────────────────────────── */}
      <div className="flex-1 flex flex-col bg-white">
        {!activeChannel ? (
          <div className="flex-1 flex items-center justify-center text-gray-400 text-xs">
            Selecione um canal para visualizar as mensagens
          </div>
        ) : (
          <>
            {/* Channel Header */}
            <div
              className={`p-3.5 border-b flex items-center justify-between ${
                activeChannel.tipo === 'emergencia'
                  ? 'bg-red-50 border-red-200'
                  : 'bg-white border-gray-200'
              }`}
            >
              <div>
                <div className="flex items-center gap-2">
                  <h3 className="font-bold text-sm text-gray-900">{activeChannel.nome}</h3>
                  {activeChannel.tipo === 'emergencia' ? (
                    <span className="text-[10px] bg-red-600 text-white font-extrabold px-2 py-0.5 rounded-full uppercase">
                      Prioridade Máxima
                    </span>
                  ) : activeChannel.setorSigla ? (
                    <span className="text-[10px] bg-blue-100 text-blue-800 font-semibold px-2 py-0.5 rounded-full">
                      Exclusivo {activeChannel.setorSigla}
                    </span>
                  ) : (
                    <span className="text-[10px] bg-gray-100 text-gray-700 font-semibold px-2 py-0.5 rounded-full">
                      Institucional Aberto
                    </span>
                  )}
                </div>
                <p className="text-xs text-gray-500 mt-0.5">{activeChannel.descricao}</p>
              </div>

              <div className="flex items-center gap-2 text-xs text-gray-500">
                <Users className="w-4 h-4 text-gray-400" />
                <span>{activeChannel.membrosCount || 0} colaboradores</span>
              </div>
            </div>

        {/* Access Locked Warning or Message Stream */}
        {!hasAccessToActive ? (
          <div className="flex-1 flex flex-col items-center justify-center p-6 text-center bg-gray-50">
            <div className="w-16 h-16 rounded-full bg-amber-100 text-amber-700 flex items-center justify-center mb-3">
              <Lock className="w-8 h-8" />
            </div>
            <h3 className="text-base font-bold text-gray-900">
              Acesso Restrito ao Centro {activeChannel.setorSigla}
            </h3>
            <p className="text-xs text-gray-600 max-w-md mt-1.5 leading-relaxed">
              Por diretriz de <strong>Isolamento Institucional da Rede SUS</strong>, colaboradores
              lotados no centro <strong>{userCenterSigla}</strong> só podem visualizar e interagir
              com canais do seu próprio setor, canais institucionais gerais ou o canal prioritário de
              emergência.
            </p>
            <p className="text-[11px] text-gray-400 mt-3">
              * Dica: Você pode alternar o usuário no topo para a <strong>Direção Geral</strong> ou para a
              coordenação respectiva para auditar este canal.
            </p>
          </div>
        ) : (
          <>
            {/* Stream */}
            <div className="flex-1 p-4 overflow-y-auto space-y-3 bg-[#F8FAFC]">
              {channelMessages.length === 0 ? (
                <div className="text-center py-12 text-gray-400 text-xs">
                  Nenhuma mensagem recente neste canal. Seja o primeiro a colaborar!
                </div>
              ) : (
                channelMessages.map((msg) => {
                  const isMine = msg.remetenteId === currentUser.id;
                  const isAlerta = msg.tipo === 'alerta';

                  return (
                    <div
                      key={msg.id}
                      className={`p-3 rounded-2xl border ${
                        isAlerta
                          ? 'bg-red-50/80 border-red-300'
                          : isMine
                          ? 'bg-blue-50/40 border-blue-200'
                          : 'bg-white border-gray-200 shadow-xs'
                      }`}
                    >
                      <div className="flex items-center justify-between mb-1">
                        <div className="flex items-center gap-2">
                          <div className="w-6 h-6 rounded-full bg-blue-600 text-white font-bold text-[10px] flex items-center justify-center">
                            {msg.remetenteNome.charAt(0)}
                          </div>
                          <span className="font-bold text-xs text-gray-900">
                            {msg.remetenteNome}
                          </span>
                          {msg.remetenteCargo && (
                            <span className="text-[10px] text-gray-500">
                              · {msg.remetenteCargo}
                            </span>
                          )}
                        </div>
                        <span className="text-[10px] text-gray-400">{msg.createdAt}</span>
                      </div>

                      <p
                        className={`text-xs pl-8 leading-relaxed ${
                          isAlerta ? 'font-bold text-red-900' : 'text-gray-800'
                        }`}
                      >
                        {msg.texto}
                      </p>
                    </div>
                  );
                })
              )}
            </div>

            {/* Input Bar */}
            <form onSubmit={handleSendMessage} className="p-3 border-t border-gray-200 bg-white">
              <div className="flex items-center gap-2">
                <input
                  type="text"
                  value={inputMessage}
                  onChange={(e) => setInputMessage(e.target.value)}
                  placeholder={`Enviar mensagem no canal ${activeChannel.nome}...`}
                  className="flex-1 text-xs p-2.5 border border-gray-300 rounded-xl focus:ring-2 focus:ring-blue-500 focus:outline-none"
                />
                <button
                  type="submit"
                  disabled={!inputMessage.trim()}
                  className="p-2.5 bg-[#1565C0] text-white rounded-xl hover:bg-[#0D47A1] disabled:opacity-40 transition shadow-xs"
                >
                  <Send className="w-4 h-4" />
                </button>
              </div>
            </form>
          </>
        )}
      </>
    )}
      </div>
    </div>
  );
};
