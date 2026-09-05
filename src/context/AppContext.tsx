import React, { createContext, useContext, useState, useEffect, useCallback } from 'react';
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

  // Load all data from real backend endpoints
  const loadBackendData = useCallback(async (userIdToLoad?: string) => {
    const activeUid = userIdToLoad || getApiUser();
    setIsSyncing(true);

    try {
      // 1. Carrega todos os perfis para o seletor institucional
      const profiles = await api.getAllProfiles().catch(() => INITIAL_USERS);
      setAvailableProfiles(profiles);

      // 2. Carrega usuário ativo
      const me = await api.getMe().catch(() => null);
      if (me) {
        setCurrentUserState(me);
        localStorage.setItem('cs_current_user', JSON.stringify(me));
      }

      // 3. Usuários filtrados pelo backend conforme isolamento de centro
      const usersData = await api.getUsers().catch(() => []);
      if (usersData && usersData.length > 0) setUsers(usersData);

      // 4. Canais com permissão
      const channelsData = await api.getChannels().catch(() => []);
      if (channelsData && channelsData.length > 0) setChannels(channelsData);

      // 5. Comunicados
      const annData = await api.getAnnouncements().catch(() => []);
      if (annData && annData.length > 0) setAnnouncements(annData);

      // 6. Conversas e mensagens
      const convData = await api.getConversations().catch(() => []);
      if (convData) setConversations(convData);

      // 7. Notificações
      const notifs = await api.getNotifications().catch(() => []);
      if (notifs) setNotifications(notifs);

      // 8. Relatos de ouvidoria
      const repData = await api.getReports().catch(() => []);
      if (repData) setReports(repData);

      // 9. Estado de emergência
      const emg = await api.getEmergencyStatus().catch(() => null);
      if (emg) {
        setEmergencyAlertActive(emg.alertActive);
        setEmergencyAlertMessage(emg.alertMessage);
      }

      // 10. Auditoria (somente se for Direção)
      const userLevel = me ? me.hierarquiaNivel : (userIdToLoad === 'usr-carlos' ? 1 : 4);
      if (userLevel === 1) {
        const logs = await api.getAuditLogs().catch(() => []);
        if (logs) setAuditLogs(logs);
      } else {
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

  // Carrega mensagens da conversa ativa quando muda
  useEffect(() => {
    if (activeConversationId) {
      // 1. Zera contagem de não lidas na conversa imediatamente
      setConversations((prev) =>
        prev.map((c) => (c.id === activeConversationId ? { ...c, naoLidas: 0 } : c))
      );

      // 2. Marca como lida as notificações dessa conversa no state local
      setNotifications((prev) =>
        prev.map((n) => {
          if (n.tipo === 'mensagem' && (n.conversaId === activeConversationId || !n.conversaId)) {
            return { ...n, lida: true };
          }
          return n;
        })
      );

      // 3. Notifica backend e carrega mensagens
      api.markConversationRead(activeConversationId)
        .then(() => api.getNotifications())
        .then((freshNotifs) => {
          if (freshNotifs) setNotifications(freshNotifs);
        })
        .catch(() => {});

      api.getConversationMessages(activeConversationId)
        .then((convMsgs) => {
          setMessages((prev) => {
            const others = prev.filter((m) => m.conversationId !== activeConversationId);
            return [...others, ...convMsgs];
          });
        })
        .catch((err) => console.log('Conversa protegida:', err.message));
    }
  }, [activeConversationId]);

  // Polling leve para sincronizar notificações e mensagens em segundo plano
  useEffect(() => {
    const timer = setInterval(async () => {
      try {
        const [notifs, convs] = await Promise.all([
          api.getNotifications().catch(() => null),
          api.getConversations().catch(() => null),
        ]);

        if (notifs) {
          setNotifications((prev) => {
            // Se a conversa ativa estiver aberta, garantir que as notificações dela continuam lidas
            if (activeConversationId) {
              return notifs.map((n) =>
                n.conversaId === activeConversationId ? { ...n, lida: true } : n
              );
            }
            return notifs;
          });
        }

        if (convs) {
          setConversations((prev) =>
            convs.map((c) =>
              c.id === activeConversationId ? { ...c, naoLidas: 0 } : c
            )
          );
        }

        if (activeConversationId) {
          const msgs = await api.getConversationMessages(activeConversationId).catch(() => null);
          if (msgs) {
            setMessages((prev) => {
              const others = prev.filter((m) => m.conversationId !== activeConversationId);
              return [...others, ...msgs];
            });
          }
        }
      } catch (err) {
        // Silencioso em caso de instabilidade
      }
    }, 4000);

    return () => clearInterval(timer);
  }, [activeConversationId]);

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

      setMessages((prev) => [...prev, postedMsg]);

      // Atualiza lista de conversas
      if (conversationId) {
        const updatedConvs = await api.getConversations();
        setConversations(updatedConvs);
      }
    } catch (err: any) {
      alert(err.message || 'Erro ao enviar mensagem');
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
