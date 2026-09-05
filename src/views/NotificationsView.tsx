import React, { useState } from 'react';
import { useApp } from '../context/AppContext';
import {
  Bell,
  CheckCheck,
  AlertOctagon,
  FileText,
  MessageSquare,
  ShieldCheck,
  Trash2,
  ChevronRight,
  Sparkles,
} from 'lucide-react';
import { NotificationItem } from '../types';

export const NotificationsView: React.FC = () => {
  const {
    notifications,
    markNotificationAsRead,
    deleteNotification,
    clearNotifications,
    setCurrentView,
    setActiveConversationId,
    markConversationAsRead,
    conversations,
  } = useApp();

  const [filter, setFilter] = useState<'all' | 'unread'>('all');

  const filtered = notifications.filter((n) => {
    if (filter === 'unread') return !n.lida;
    return true;
  });

  const getIcon = (tipo: string) => {
    switch (tipo) {
      case 'emergencia':
        return <AlertOctagon className="w-5 h-5 text-red-600" />;
      case 'comunicado':
        return <FileText className="w-5 h-5 text-emerald-600" />;
      case 'mensagem':
        return <MessageSquare className="w-5 h-5 text-blue-600" />;
      default:
        return <ShieldCheck className="w-5 h-5 text-purple-600" />;
    }
  };

  const handleNotificationClick = async (item: NotificationItem) => {
    // 1. Marca notificação individual como lida
    await markNotificationAsRead(item.id);

    // 2. Navega e abre o módulo de destino
    if (item.tipo === 'mensagem') {
      let targetConvId = item.conversaId;

      // Se não tiver conversaId explícito, tenta deduzir pela conversa com o remetente
      if (!targetConvId && item.remetenteId) {
        const matching = conversations.find(
          (c) =>
            c.membros?.some((m) => m.id === item.remetenteId) ||
            (c as any).membroIds?.includes(item.remetenteId)
        );
        if (matching) targetConvId = matching.id;
      }

      if (targetConvId) {
        setActiveConversationId(targetConvId);
        await markConversationAsRead(targetConvId);
      }
      setCurrentView('conversations');
    } else if (item.tipo === 'comunicado') {
      setCurrentView('announcements');
    } else if (item.tipo === 'emergencia') {
      setCurrentView('emergency');
    }
  };

  const handleDeleteRead = () => {
    const readItems = notifications.filter((n) => n.lida);
    readItems.forEach((n) => deleteNotification(n.id));
  };

  const unreadCount = notifications.filter((n) => !n.lida).length;
  const readCount = notifications.filter((n) => n.lida).length;

  return (
    <div className="max-w-3xl mx-auto space-y-6 pb-12">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 bg-white p-5 rounded-2xl border border-gray-200 shadow-xs">
        <div>
          <div className="flex items-center gap-2">
            <div className="w-8 h-8 rounded-xl bg-blue-50 text-blue-600 flex items-center justify-center border border-blue-100">
              <Bell className="w-4 h-4 text-[#1565C0]" />
            </div>
            <h2 className="font-bold text-lg text-gray-900">Central de Notificações</h2>
          </div>
          <p className="text-xs text-gray-500 mt-1">
            Alertas de emergência, comunicados oficiais e avisos de novas mensagens hospitalares.
          </p>
        </div>

        <div className="flex items-center gap-2 flex-wrap">
          <button
            onClick={clearNotifications}
            disabled={unreadCount === 0}
            className={`flex items-center gap-1.5 px-3.5 py-1.5 rounded-xl text-xs font-semibold transition border ${
              unreadCount === 0
                ? 'bg-gray-50 text-gray-400 border-gray-200 cursor-not-allowed'
                : 'text-blue-700 bg-blue-50 hover:bg-blue-100/70 border-blue-200 shadow-2xs'
            }`}
            title="Marcar todas como lidas"
          >
            <CheckCheck className="w-4 h-4" />
            <span>Marcar lidas ({unreadCount})</span>
          </button>

          {readCount > 0 && (
            <button
              onClick={handleDeleteRead}
              className="flex items-center gap-1.5 text-gray-600 hover:text-red-700 hover:bg-red-50 px-3 py-1.5 rounded-xl text-xs font-semibold transition border border-gray-200 hover:border-red-200"
              title="Remover notificações já lidas da lista"
            >
              <Trash2 className="w-3.5 h-3.5" />
              <span>Limpar lidas</span>
            </button>
          )}
        </div>
      </div>

      {/* Filter Tabs */}
      <div className="flex items-center justify-between gap-2">
        <div className="flex items-center gap-2">
          <button
            onClick={() => setFilter('all')}
            className={`px-3.5 py-1.5 rounded-xl text-xs font-semibold transition ${
              filter === 'all'
                ? 'bg-[#1565C0] text-white shadow-xs'
                : 'bg-white text-gray-600 hover:bg-gray-100 border border-gray-200'
            }`}
          >
            Todas ({notifications.length})
          </button>
          <button
            onClick={() => setFilter('unread')}
            className={`px-3.5 py-1.5 rounded-xl text-xs font-semibold transition flex items-center gap-1.5 ${
              filter === 'unread'
                ? 'bg-[#1565C0] text-white shadow-xs'
                : 'bg-white text-gray-600 hover:bg-gray-100 border border-gray-200'
            }`}
          >
            <span>Não Lidas</span>
            {unreadCount > 0 && (
              <span
                className={`text-[10px] px-1.5 py-0.2 rounded-full font-bold ${
                  filter === 'unread' ? 'bg-white text-[#1565C0]' : 'bg-red-500 text-white'
                }`}
              >
                {unreadCount}
              </span>
            )}
          </button>
        </div>

        {filter === 'unread' && unreadCount > 0 && (
          <span className="text-[11px] text-gray-400 hidden sm:inline">
            Clique na notificação para abri-la e marcá-la como lida
          </span>
        )}
      </div>

      {/* Notifications List */}
      <div className="space-y-3">
        {filtered.length === 0 ? (
          <div className="p-10 text-center bg-white rounded-2xl border border-gray-200 text-gray-400 text-xs">
            <div className="w-10 h-10 rounded-full bg-gray-50 text-gray-400 flex items-center justify-center mx-auto mb-2 border border-gray-100">
              <Sparkles className="w-5 h-5 text-gray-400" />
            </div>
            {filter === 'unread'
              ? 'Tudo em dia! Você não possui notificações pendentes.'
              : 'Nenhuma notificação encontrada no histórico.'}
          </div>
        ) : (
          filtered.map((item) => (
            <div
              key={item.id}
              onClick={() => handleNotificationClick(item)}
              className={`p-4 rounded-2xl border transition flex items-start gap-3.5 cursor-pointer group hover:shadow-xs ${
                item.lida
                  ? 'bg-white border-gray-200 hover:border-gray-300'
                  : 'bg-blue-50/60 border-blue-200 shadow-2xs hover:border-blue-300'
              }`}
            >
              <div className="p-2.5 rounded-xl bg-gray-50 flex-shrink-0 group-hover:bg-white transition border border-gray-100">
                {getIcon(item.tipo)}
              </div>

              <div className="flex-1 min-w-0">
                <div className="flex items-center justify-between gap-2">
                  <div className="flex items-center gap-2 min-w-0">
                    <h4
                      className={`text-xs truncate ${
                        item.lida ? 'font-medium text-gray-800' : 'font-bold text-blue-950'
                      }`}
                    >
                      {item.titulo}
                    </h4>
                    {!item.lida && (
                      <span className="text-[10px] bg-blue-600 text-white font-semibold px-1.5 py-0.2 rounded-full flex-shrink-0">
                        Nova
                      </span>
                    )}
                  </div>
                  <span className="text-[10px] text-gray-400 whitespace-nowrap">
                    {item.timestamp}
                  </span>
                </div>

                <p className="text-xs text-gray-600 mt-1 leading-relaxed line-clamp-2">
                  {item.descricao}
                </p>

                <div className="mt-2 flex items-center justify-between">
                  <span className="text-[11px] font-semibold text-[#1565C0] group-hover:underline flex items-center gap-1">
                    {item.tipo === 'mensagem' && 'Abrir conversa direta'}
                    {item.tipo === 'comunicado' && 'Ler comunicado oficial'}
                    {item.tipo === 'emergencia' && 'Ver protocolo de emergência'}
                    {item.tipo === 'sistema' && 'Ver detalhes'}
                    <ChevronRight className="w-3.5 h-3.5" />
                  </span>

                  <button
                    onClick={(e) => {
                      e.stopPropagation();
                      deleteNotification(item.id);
                    }}
                    className="opacity-0 group-hover:opacity-100 transition p-1 hover:bg-red-50 text-gray-400 hover:text-red-600 rounded-lg text-xs"
                    title="Excluir notificação"
                  >
                    <Trash2 className="w-3.5 h-3.5" />
                  </button>
                </div>
              </div>

              {!item.lida && (
                <span className="w-2.5 h-2.5 rounded-full bg-blue-600 flex-shrink-0 self-center" />
              )}
            </div>
          ))
        )}
      </div>
    </div>
  );
};
