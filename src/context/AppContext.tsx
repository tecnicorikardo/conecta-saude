import React, { createContext, useContext, useState, useEffect, useCallback, useRef } from 'react';
import {
  User,
  Channel,
  Announcement,
  Conversation,
  Message,
  NotificationItem,
  AuditLog,
  Report,
  AppView,
} from '../types';
import {
  INITIAL_USERS,
  INITIAL_CHANNELS,
  INITIAL_ANNOUNCEMENTS,
  INITIAL_CONVERSATIONS,
  INITIAL_MESSAGES,
  INITIAL_NOTIFICATIONS,
  INITIAL_AUDIT_LOGS,
  INITIAL_REPORTS,
} from '../data/initialData';
import { api, setApiUser, getApiUser } from '../services/api';

interface AppContextType {
  currentUser: User;
  setCurrentUser: (user: User) => void;
  switchProfile: (userId: string) => Promise<void>;
  availableProfiles: User[];
  currentView: AppView;
  setCurrentView: (view: AppView) => void;
  users: User[];
  addUser: (userData: Omit<User, 'id' | 'firebaseUid'>) => Promise<void>;
  toggleUserStatus: (userId: string) => Promise<void>;
  channels: Channel[];
  createChannel: (data: { nome: string; descricao: string; tipo: 'institucional' | 'setor' | 'emergencia'; setorId?: string }) => Promise<void>;
  announcements: Announcement[];
  addAnnouncement: (
    data: Omit<
      Announcement,
      'id' | 'publicadoEm' | 'visualizacoesPorcentagem' | 'lidoPorMim'
    >
  ) => Promise<void>;
  markAnnouncementAsRead: (id: string) => Promise<void>;
  conversations: Conversation[];
  startConversationWith: (targetUserId: string) => Promise<string>;
  createGroup: (data: { nome: string; participantIds: string[]; fotoUrl?: string; autoExcluir24h?: boolean }) => Promise<string>;
  deleteConversation: (conversationId: string) => Promise<void>;
  clearConversation: (conversationId: string) => Promise<void>;
  addConversationMembers: (conversationId: string, userIds: string[]) => Promise<void>;
  updateConversation: (conversationId: string, data: { nome?: string; fotoUrl?: string; autoExcluir24h?: boolean }) => Promise<void>;
  activeConversationId: string | null;
  setActiveConversationId: (id: string | null) => void;
  markConversationAsRead: (conversationId: string) => Promise<void>;
  activeChannelId: string | null;
  setActiveChannelId: (id: string | null) => void;
  messages: Message[];
  sendMessage: (
    conversationId: string | undefined,
    channelId: string | undefined,
    texto: string,
    tipo?: 'texto' | 'audio' | 'alerta'
  ) => Promise<void>;
  deleteMessage: (msgId: string) => Promise<void>;
  notifications: NotificationItem[];
  markNotificationAsRead: (id: string) => Promise<void>;
  deleteNotification: (id: string) => Promise<void>;
  clearNotifications: () => Promise<void>;
  reports: Report[];
  addReport: (motivo: string, descricao: string, mensagemTrecho?: string, sigiloso?: boolean) => Promise<void>;
  updateReportStatus: (id: string, status: 'pendente' | 'em_analise' | 'resolvido', observacoes?: string) => Promise<void>;
  auditLogs: AuditLog[];
  refreshAuditLogs: () => Promise<void>;
  emergencyAlertActive: boolean;
  emergencyAlertMessage: string | null;
  triggerEmergencyAlert: (msg: string) => Promise<void>;
  dismissEmergencyAlert: () => Promise<void>;
  backendOnline: boolean;
  isSyncing: boolean;
  // Permissions & Isolation
  isAdmin: boolean;
  isCoord: boolean;
  canManageEmployees: boolean;
  canViewReports: boolean;
  canViewAudit: boolean;
  canPublishAnnouncement: boolean;
  userCenterSigla: 'CCDTI' | 'CCO' | 'CCE' | 'DIRECAO';
}

const AppContext = createContext<AppContextType | undefined>(undefined);

export const AppProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [currentUser, setCurrentUserState] = useState<User>(() => {
    const saved = localStorage.getItem('cs_current_user');
    if (saved) {
      try {
        return JSON.parse(saved);
      } catch (e) {
        // fallback
      }
    }
    return INITIAL_USERS[0]; // Dr. Carlos Mendes
  });

  const [availableProfiles, setAvailableProfiles] = useState<User[]>(INITIAL_USERS);
  const [currentView, setCurrentView] = useState<AppView>('home');
  const [users, setUsers] = useState<User[]>(INITIAL_USERS);
  const [channels, setChannels] = useState<Channel[]>(INITIAL_CHANNELS);
  const [announcements, setAnnouncements] = useState<Announcement[]>(INITIAL_ANNOUNCEMENTS);
  const [conversations, setConversations] = useState<Conversation[]>(INITIAL_CONVERSATIONS);
  const [activeConversationId, setActiveConversationId] = useState<string | null>('conv-1');
  const [activeChannelId, setActiveChannelId] = useState<string | null>('chn-emergencia');
  const [messages, setMessages] = useState<Message[]>(INITIAL_MESSAGES);
  const [notifications, setNotifications] = useState<NotificationItem[]>(INITIAL_NOTIFICATIONS);
  const [reports, setReports] = useState<Report[]>(INITIAL_REPORTS);
  const [auditLogs, setAuditLogs] = useState<AuditLog[]>(INITIAL_AUDIT_LOGS);
  const [emergencyAlertActive, setEmergencyAlertActive] = useState<boolean>(false);
  const [emergencyAlertMessage, setEmergencyAlertMessage] = useState<string | null>(null);
  const [backendOnline, setBackendOnline] = useState<boolean>(true);
  const [isSyncing, setIsSyncing] = useState<boolean>(false);

  // Load all data from real backend endpoints — PARALLELIZED
  const loadBackendData = useCallback(async (userIdToLoad?: string) => {
    const activeUid = userIdToLoad || getApiUser();
    setIsSyncing(true);

    try {
      // Lote 1: auth (necessário para permissões no lote 2)
      const [profiles, me] = await Promise.all([
        api.getAllProfiles().catch(() => INITIAL_USERS),
        api.getMe().catch(() => null),
      ]);

      setAvailableProfiles(profiles);
      if (me) {
        setCurrentUserState(me);
        localStorage.setItem('cs_current_user', JSON.stringify(me));
      }

      // Lote 2: todos os dados em paralelo (não dependem uns dos outros)
      const userLevel = me ? me.hierarquiaNivel : (userIdToLoad === 'usr-carlos' ? 1 : 4);

      const promises: Promise<any>[] = [
        api.getUsers().catch(() => []),
        api.getChannels().catch(() => []),
        api.getAnnouncements().catch(() => []),
        api.getConversations().catch(() => []),
        api.getNotifications().catch(() => []),
        api.getReports().catch(() => []),
        api.getEmergencyStatus().catch(() => null),
      ];

      // Auditoria só para Direção
      if (userLevel === 1) {
        promises.push(api.getAuditLogs().catch(() => []));
      }

      const [usersData, channelsData, annData, convData, notifs, repData, emg, logs] =
        await Promise.all(promises);

      // Atualiza state apenas quando temos dados (stale-while-revalidate)
      if (usersData && usersData.length > 0) setUsers(usersData);
      if (channelsData && channelsData.length > 0) setChannels(channelsData);
      if (annData && annData.length > 0) setAnnouncements(annData);
      if (convData) setConversations(convData);
      if (notifs) setNotifications(notifs);
      if (repData) setReports(repData);
      if (emg) {
        setEmergencyAlertActive(emg.alertActive);
        setEmergencyAlertMessage(emg.alertMessage);
      }
      if (userLevel === 1 && logs) {
        setAuditLogs(logs);
      } else if (userLevel !== 1) {
        setAuditLogs([]);
      }

      setBackendOnline(true);
    } catch (err) {
      console.warn('[AppContext] Erro ao sincronizar com backend:', err);
      setBackendOnline(false);
    } finally {
      setIsSyncing(false);
    }
  }, []);

  // Inicialização no mount
  useEffect(() => {
    setApiUser(currentUser.id);
    loadBackendData(currentUser.id);
  }, [loadBackendData]);

  // Carrega mensagens do canal ativo quando muda
  useEffect(() => {
    if (activeChannelId) {
      api.getChannelMessages(activeChannelId)
        .then((channelMsgs) => {
          setMessages((prev) => {
            const others = prev.filter((m) => m.channelId !== activeChannelId);
            return [...others, ...channelMsgs];
          });
        })
        .catch((err) => console.log('Canal protegido ou sem acesso:', err.message));
    }
  }, [activeChannelId]);

  // Carrega mensagens da conversa ativa quando muda — PARALLELIZED
  useEffect(() => {
    if (activeConversationId) {
      // 1. Atualizações locais imediatas (sem esperar backend)
      setConversations((prev) =>
        prev.map((c) => (c.id === activeConversationId ? { ...c, naoLidas: 0 } : c))
      );
      setNotifications((prev) =>
        prev.map((n) => {
          if (n.tipo === 'mensagem' && (n.conversaId === activeConversationId || !n.conversaId)) {
            return { ...n, lida: true };
          }
          return n;
        })
      );

      // 2. Backend em paralelo: marcar lida + buscar mensagens + atualizar notificações
      Promise.all([
        api.getConversationMessages(activeConversationId).catch(() => null),
        api.markConversationRead(activeConversationId)
          .then(() => api.getNotifications())
          .catch(() => null),
      ]).then(([convMsgs, freshNotifs]) => {
        if (convMsgs) {
          setMessages((prev) => {
            const others = prev.filter((m) => m.conversationId !== activeConversationId);
            return [...others, ...convMsgs];
          });
        }
        if (freshNotifs) setNotifications(freshNotifs);
      });
    }
  }, [activeConversationId]);

  // Ref para evitar recriar o timer a cada troca de conversa
  const activeConvRef = useRef(activeConversationId);
  useEffect(() => {
    activeConvRef.current = activeConversationId;
  }, [activeConversationId]);

  // Polling otimizado — intervalo de 12s em vez de 4s, usa ref estável
  useEffect(() => {
    const timer = setInterval(async () => {
      try {
        const currentConvId = activeConvRef.current;

        const promises: Promise<any>[] = [
          api.getNotifications().catch(() => null),
          api.getConversations().catch(() => null),
        ];

        // Só busca mensagens se há conversa ativa
        if (currentConvId) {
          promises.push(api.getConversationMessages(currentConvId).catch(() => null));
        }

        const [notifs, convs, msgs] = await Promise.all(promises);

        if (notifs) {
          setNotifications((prev) => {
            if (currentConvId) {
              return notifs.map((n: any) =>
                n.conversaId === currentConvId ? { ...n, lida: true } : n
              );
            }
            return notifs;
          });
        }

        if (convs) {
          setConversations((prev) =>
            convs.map((c: any) =>
              c.id === currentConvId ? { ...c, naoLidas: 0 } : c
            )
          );
        }

        if (msgs && currentConvId) {
          setMessages((prev) => {
            const others = prev.filter((m) => m.conversationId !== currentConvId);
            return [...others, ...msgs];
          });
        }
      } catch (err) {
        // Silencioso em caso de instabilidade
      }
    }, 12000);

    return () => clearInterval(timer);
  }, []); // Timer estável — não recria ao trocar conversa

  // Troca de usuário / perfil com recarga imediata de permissões e isolamento
  const switchProfile = async (userId: string) => {
    setApiUser(userId);
    const target = availableProfiles.find((u) => u.id === userId);
    if (target) {
      setCurrentUserState(target);
      localStorage.setItem('cs_current_user', JSON.stringify(target));
    }
    await loadBackendData(userId);
  };

  const setCurrentUser = (user: User) => {
    switchProfile(user.id);
  };

  // Permissões
  const isAdmin = currentUser.hierarquiaNivel === 1;
  const isCoord = currentUser.hierarquiaNivel <= 2;
  const canManageEmployees = currentUser.hierarquiaNivel === 1;
  const canViewReports = currentUser.hierarquiaNivel === 1;
  const canViewAudit = currentUser.hierarquiaNivel === 1;
  const canPublishAnnouncement = currentUser.hierarquiaNivel <= 2;

  const getUserCenterSigla = (user: User): 'CCDTI' | 'CCO' | 'CCE' | 'DIRECAO' => {
    if (user.setorId === 'sec-ccdti' || user.cargo.includes('CCDTI')) return 'CCDTI';
    if (user.setorId === 'sec-cco' || user.cargo.includes('CCO')) return 'CCO';
    if (user.setorId === 'sec-cce' || user.cargo.includes('CCE')) return 'CCE';
    return 'DIRECAO';
  };

  const userCenterSigla = getUserCenterSigla(currentUser);

  // Ações conectadas à API
  const addUser = async (userData: Omit<User, 'id' | 'firebaseUid'>) => {
    try {
      const created = await api.createUser(userData);
      setUsers((prev) => [created, ...prev]);
      if (isAdmin) {
        const logs = await api.getAuditLogs();
        setAuditLogs(logs);
      }
    } catch (err: any) {
      alert(err.message || 'Falha ao cadastrar colaborador');
    }
  };

  const toggleUserStatus = async (userId: string) => {
    try {
      const updated = await api.toggleUserStatus(userId);
      setUsers((prev) => prev.map((u) => (u.id === userId ? updated : u)));
      if (isAdmin) {
        const logs = await api.getAuditLogs();
        setAuditLogs(logs);
      }
    } catch (err: any) {
      alert(err.message || 'Falha ao alterar status');
    }
  };

  const createChannel = async (data: {
    nome: string;
    descricao: string;
    tipo: 'institucional' | 'setor' | 'emergencia';
    setorId?: string;
  }) => {
    try {
      const newChn = await api.createChannel(data);
      setChannels((prev) => [...prev, newChn]);
    } catch (err: any) {
      alert(err.message || 'Falha ao criar canal');
    }
  };

  const addAnnouncement = async (
    data: Omit<
      Announcement,
      'id' | 'publicadoEm' | 'visualizacoesPorcentagem' | 'lidoPorMim'
    >
  ) => {
    try {
      const newAnn = await api.createAnnouncement({
        titulo: data.titulo,
        mensagem: data.mensagem,
        prioridade: data.prioridade,
        setorId: data.setorId,
      });
      setAnnouncements((prev) => [newAnn, ...prev]);
      // Recarrega notificações
      const notifs = await api.getNotifications();
      setNotifications(notifs);
    } catch (err: any) {
      alert(err.message || 'Falha ao publicar comunicado');
    }
  };

  const markAnnouncementAsRead = async (id: string) => {
    try {
      await api.confirmAnnouncementRead(id);
      setAnnouncements((prev) =>
        prev.map((a) =>
          a.id === id
            ? {
                ...a,
                lidoPorMim: true,
                visualizacoesPorcentagem: Math.min(100, a.visualizacoesPorcentagem + 10),
              }
            : a
        )
      );
    } catch (err: any) {
      console.warn('Erro ao confirmar leitura:', err.message);
    }
  };

  const sendMessage = async (
    conversationId: string | undefined,
    channelId: string | undefined,
    texto: string,
    tipo: 'texto' | 'audio' | 'alerta' = 'texto'
  ) => {
    if (!texto.trim() && tipo !== 'audio') return;

    // 1. Criar mensagem local otimista (aparece imediatamente)
    const tempId = `temp-${Date.now()}-${Math.random().toString(36).slice(2, 7)}`;
    const now = new Date();
    const horaStr = `${now.getHours().toString().padStart(2, '0')}:${now.getMinutes().toString().padStart(2, '0')}`;

    const optimisticMsg: Message = {
      id: tempId,
      conversationId,
      channelId,
      remetenteId: currentUser.id,
      remetenteNome: currentUser.nome,
      remetenteCargo: currentUser.cargo,
      texto,
      createdAt: horaStr,
      lida: false,
      tipo,
      audioDuracaoSegundos: tipo === 'audio' ? 14 : undefined,
      status: 'sending',
    };

    // Inserir imediatamente no state
    setMessages((prev) => [...prev, optimisticMsg]);

    // Atualizar a lista de conversas localmente (última mensagem)
    if (conversationId) {
      setConversations((prev) =>
        prev.map((c) =>
          c.id === conversationId
            ? { ...c, ultimaMensagem: texto, ultimaMensagemHora: horaStr }
            : c
        )
      );
    }

    // 2. Enviar para o backend em background
    try {
      let postedMsg: Message;
      if (channelId) {
        postedMsg = await api.postChannelMessage(channelId, {
          texto,
          tipo,
          audioDuracaoSegundos: tipo === 'audio' ? 14 : undefined,
        });
      } else if (conversationId) {
        postedMsg = await api.postConversationMessage(conversationId, {
          texto,
          tipo,
          audioDuracaoSegundos: tipo === 'audio' ? 14 : undefined,
        });
      } else {
        return;
      }

      // 3. Substituir mensagem temporária pela confirmada do servidor
      setMessages((prev) =>
        prev.map((m) =>
          m.id === tempId ? { ...postedMsg, status: 'sent' } : m
        )
      );

      // Atualiza conversas em background (sem bloquear)
      if (conversationId) {
        api.getConversations()
          .then((updatedConvs) => setConversations(updatedConvs))
          .catch(() => {});
      }
    } catch (err: any) {
      // 4. Marcar como falha — manter a mensagem visível com status 'failed'
      setMessages((prev) =>
        prev.map((m) =>
          m.id === tempId ? { ...m, status: 'failed' } : m
        )
      );
      console.warn('Falha ao enviar mensagem:', err.message);
    }
  };

  const deleteMessage = async (msgId: string) => {
    try {
      await api.deleteMessage(msgId);
      setMessages((prev) =>
        prev.map((m) =>
          m.id === msgId ? { ...m, apagada: true, texto: 'Esta mensagem foi apagada pelo remetente.' } : m
        )
      );
    } catch (err: any) {
      alert(err.message || 'Não foi possível apagar a mensagem');
    }
  };

  const startConversationWith = async (targetUserId: string): Promise<string> => {
    try {
      const conv = await api.createConversation(targetUserId);
      const [convs, msgs] = await Promise.all([
        api.getConversations(),
        api.getConversationMessages(conv.id).catch(() => []),
      ]);
      setConversations(convs);
      setMessages((prev) => {
        const others = prev.filter((m) => m.conversationId !== conv.id);
        return [...others, ...msgs];
      });
      setActiveConversationId(conv.id);
      return conv.id;
    } catch (err: any) {
      alert(err.message || 'Falha ao iniciar conversa');
      throw err;
    }
  };

  const createGroup = async (data: {
    nome: string;
    participantIds: string[];
    fotoUrl?: string;
    autoExcluir24h?: boolean;
  }): Promise<string> => {
    try {
      const conv = await api.createGroup(data);
      setConversations((prev) => [conv, ...prev]);
      setActiveConversationId(conv.id);
      return conv.id;
    } catch (err: any) {
      alert(err.message || 'Falha ao criar grupo');
      throw err;
    }
  };

  const deleteConversation = async (conversationId: string) => {
    try {
      setConversations((prev) => prev.filter((c) => c.id !== conversationId));
      setMessages((prev) => prev.filter((m) => m.conversationId !== conversationId));
      if (activeConversationId === conversationId) {
        setActiveConversationId(null);
      }
      await api.deleteConversation(conversationId);
    } catch (err: any) {
      console.warn('Erro ao excluir conversa:', err.message);
      api.getConversations().then(setConversations).catch(() => {});
    }
  };

  const clearConversation = async (conversationId: string) => {
    try {
      setMessages((prev) => prev.filter((m) => m.conversationId !== conversationId));
      setConversations((prev) =>
        prev.map((c) =>
          c.id === conversationId
            ? { ...c, ultimaMensagem: 'Histórico de mensagens limpo.', ultimaMensagemHora: 'Agora' }
            : c
        )
      );
      await api.clearConversation(conversationId);
    } catch (err: any) {
      console.warn('Erro ao limpar conversa:', err.message);
    }
  };

  const addConversationMembers = async (conversationId: string, userIds: string[]) => {
    try {
      const updated = await api.addConversationMembers(conversationId, userIds);
      setConversations((prev) =>
        prev.map((c) => (c.id === conversationId ? { ...c, ...updated } : c))
      );
    } catch (err: any) {
      alert(err.message || 'Falha ao adicionar participantes');
    }
  };

  const updateConversation = async (
    conversationId: string,
    data: { nome?: string; fotoUrl?: string; autoExcluir24h?: boolean }
  ) => {
    try {
      setConversations((prev) =>
        prev.map((c) => (c.id === conversationId ? { ...c, ...data } : c))
      );
      await api.updateConversation(conversationId, data);
    } catch (err: any) {
      console.warn('Erro ao atualizar conversa:', err.message);
    }
  };

  const markConversationAsRead = async (convId: string) => {
    // 1. Zera contagem de não lidas na conversa imediatamente no estado local
    setConversations((prev) =>
      prev.map((c) => (c.id === convId ? { ...c, naoLidas: 0 } : c))
    );

    // 2. Marca mensagens como lidas
    setMessages((prev) =>
      prev.map((m) => (m.conversationId === convId ? { ...m, lida: true } : m))
    );

    // 3. Marca como lida as notificações dessa conversa no estado
    setNotifications((prev) =>
      prev.map((n) => {
        if (n.tipo === 'mensagem' && (n.conversaId === convId || !n.conversaId)) {
          return { ...n, lida: true };
        }
        return n;
      })
    );

    // 4. Dispara atualização no backend
    try {
      await api.markConversationRead(convId);
      const freshNotifs = await api.getNotifications().catch(() => null);
      if (freshNotifs) setNotifications(freshNotifs);
    } catch (e) {
      // tolerante a falhas
    }
  };

  const markNotificationAsRead = async (id: string) => {
    try {
      await api.markNotificationRead(id);
      setNotifications((prev) => prev.map((n) => (n.id === id ? { ...n, lida: true } : n)));
    } catch (e) {
      // fallback local
      setNotifications((prev) => prev.map((n) => (n.id === id ? { ...n, lida: true } : n)));
    }
  };

  const deleteNotification = async (id: string) => {
    // Imediatamente remove da lista (faz a notificação subir/sumir)
    setNotifications((prev) => prev.filter((n) => n.id !== id));
    try {
      await api.deleteNotification(id);
    } catch (e) {
      // tolerante
    }
  };

  const clearNotifications = async () => {
    try {
      await api.clearNotifications();
      setNotifications((prev) => prev.map((n) => ({ ...n, lida: true })));
    } catch (e) {
      setNotifications((prev) => prev.map((n) => ({ ...n, lida: true })));
    }
  };

  const addReport = async (motivo: string, descricao: string, mensagemTrecho?: string, sigiloso = false) => {
    try {
      const rep = await api.createReport({ motivo, descricao, mensagemTrecho, sigiloso });
      setReports((prev) => [rep, ...prev]);
    } catch (err: any) {
      alert(err.message || 'Erro ao registrar relato na Ouvidoria');
    }
  };

  const updateReportStatus = async (
    id: string,
    status: 'pendente' | 'em_analise' | 'resolvido',
    observacoes?: string
  ) => {
    try {
      const updated = await api.updateReportStatus(id, status, observacoes);
      setReports((prev) => prev.map((r) => (r.id === id ? updated : r)));
    } catch (err: any) {
      alert(err.message || 'Erro ao atualizar denúncia');
    }
  };

  const refreshAuditLogs = async () => {
    if (isAdmin) {
      try {
        const logs = await api.getAuditLogs();
        setAuditLogs(logs);
      } catch (e) {
        console.warn('Erro ao carregar auditoria:', e);
      }
    }
  };

  const triggerEmergencyAlert = async (msg: string) => {
    try {
      const emg = await api.triggerEmergencyAlert(msg);
      setEmergencyAlertActive(emg.alertActive);
      setEmergencyAlertMessage(emg.alertMessage);

      // Recarrega canais e notificações
      const chns = await api.getChannels();
      setChannels(chns);
      const notifs = await api.getNotifications();
      setNotifications(notifs);
    } catch (err: any) {
      alert(err.message || 'Erro ao acionar emergência');
    }
  };

  const dismissEmergencyAlert = async () => {
    try {
      const emg = await api.dismissEmergencyAlert();
      setEmergencyAlertActive(emg.alertActive);
      setEmergencyAlertMessage(emg.alertMessage);
    } catch (err: any) {
      alert(err.message || 'Erro ao encerrar emergência');
    }
  };

  return (
    <AppContext.Provider
      value={{
        currentUser,
        setCurrentUser,
        switchProfile,
        availableProfiles,
        currentView,
        setCurrentView,
        users,
        addUser,
        toggleUserStatus,
        channels,
        createChannel,
        announcements,
        addAnnouncement,
        markAnnouncementAsRead,
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
        activeChannelId,
        setActiveChannelId,
        messages,
        sendMessage,
        deleteMessage,
        notifications,
        markNotificationAsRead,
        deleteNotification,
        clearNotifications,
        reports,
        addReport,
        updateReportStatus,
        auditLogs,
        refreshAuditLogs,
        emergencyAlertActive,
        emergencyAlertMessage,
        triggerEmergencyAlert,
        dismissEmergencyAlert,
        backendOnline,
        isSyncing,
        isAdmin,
        isCoord,
        canManageEmployees,
        canViewReports,
        canViewAudit,
        canPublishAnnouncement,
        userCenterSigla,
      }}
    >
      {children}
    </AppContext.Provider>
  );
};

export const useApp = () => {
  const context = useContext(AppContext);
  if (!context) throw new Error('useApp must be used within an AppProvider');
  return context;
};
