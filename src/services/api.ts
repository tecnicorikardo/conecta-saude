import {
  User,
  Sector,
  Channel,
  Conversation,
  Message,
  Announcement,
  EmergencyState,
  Report,
  AuditLog,
  NotificationItem,
} from '../types';

let currentUserId = 'usr-carlos';

export const setApiUser = (userId: string) => {
  currentUserId = userId;
  localStorage.setItem('cs_api_user_id', userId);
};

export const getApiUser = (): string => {
  const saved = localStorage.getItem('cs_api_user_id');
  if (saved) {
    currentUserId = saved;
  }
  return currentUserId;
};

// Helper fetch com cabeçalho de autenticação, contexto de usuário e timeout
async function apiRequest<T>(endpoint: string, options: RequestInit = {}): Promise<T> {
  const userId = getApiUser();
  const headers = new Headers(options.headers || {});
  headers.set('Content-Type', 'application/json');
  headers.set('x-user-id', userId);
  headers.set('Authorization', `Bearer ${userId}`);

  // Timeout de 8 segundos para evitar spinner indefinido
  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), 8000);

  try {
    const res = await fetch(`/api${endpoint}`, {
      ...options,
      headers,
      signal: controller.signal,
    });

    const json = await res.json().catch(() => ({}));

    if (!res.ok) {
      throw new Error(json.error || `Erro na requisição (${res.status})`);
    }

    return json.data !== undefined ? json.data : json;
  } catch (err: any) {
    if (err.name === 'AbortError') {
      throw new Error('A conexão com o servidor excedeu o tempo limite. Tente novamente.');
    }
    throw err;
  } finally {
    clearTimeout(timeoutId);
  }
}

export const api = {
  // ─── AUTH & ME ──────────────────────────────────────────────────────────
  getMe: async (): Promise<User & { permissoes: any }> => {
    return apiRequest<User & { permissoes: any }>('/auth/me');
  },

  getAllProfiles: async (): Promise<User[]> => {
    return apiRequest<User[]>('/auth/profiles');
  },

  // ─── SETORES ────────────────────────────────────────────────────────────
  getSectors: async (): Promise<Sector[]> => {
    return apiRequest<Sector[]>('/sectors');
  },

  // ─── USUÁRIOS & ISOLAMENTO ──────────────────────────────────────────────
  getUsers: async (filters?: { setorId?: string; ativo?: boolean; search?: string }): Promise<User[]> => {
    const params = new URLSearchParams();
    if (filters?.setorId) params.set('setorId', filters.setorId);
    if (filters?.ativo !== undefined) params.set('ativo', String(filters.ativo));
    if (filters?.search) params.set('search', filters.search);

    const query = params.toString() ? `?${params.toString()}` : '';
    return apiRequest<User[]>(`/users${query}`);
  },

  createUser: async (userData: Omit<User, 'id' | 'firebaseUid'>): Promise<User> => {
    return apiRequest<User>('/users', {
      method: 'POST',
      body: JSON.stringify(userData),
    });
  },

  toggleUserStatus: async (userId: string): Promise<User> => {
    return apiRequest<User>(`/users/${userId}/toggle-status`, {
      method: 'PATCH',
    });
  },

  // ─── CANAIS ─────────────────────────────────────────────────────────────
  getChannels: async (): Promise<Channel[]> => {
    return apiRequest<Channel[]>('/channels');
  },

  createChannel: async (data: {
    nome: string;
    descricao: string;
    tipo: 'institucional' | 'setor' | 'emergencia';
    setorId?: string;
  }): Promise<Channel> => {
    return apiRequest<Channel>('/channels', {
      method: 'POST',
      body: JSON.stringify(data),
    });
  },

  getChannelMessages: async (channelId: string): Promise<Message[]> => {
    return apiRequest<Message[]>(`/channels/${channelId}/messages`);
  },

  postChannelMessage: async (
    channelId: string,
    data: { texto: string; tipo?: 'texto' | 'audio' | 'alerta'; audioDuracaoSegundos?: number }
  ): Promise<Message> => {
    return apiRequest<Message>(`/channels/${channelId}/messages`, {
      method: 'POST',
      body: JSON.stringify(data),
    });
  },

  // ─── CONVERSAS (CHAT PRIVADO) ───────────────────────────────────────────
  getConversations: async (): Promise<Conversation[]> => {
    return apiRequest<Conversation[]>('/conversations');
  },

  createConversation: async (targetUserId: string): Promise<Conversation> => {
    return apiRequest<Conversation>('/conversations', {
      method: 'POST',
      body: JSON.stringify({ targetUserId }),
    });
  },

  createGroup: async (data: {
    nome: string;
    participantIds: string[];
    fotoUrl?: string;
    autoExcluir24h?: boolean;
  }): Promise<Conversation> => {
    return apiRequest<Conversation>('/conversations', {
      method: 'POST',
      body: JSON.stringify({
        tipo: 'grupo',
        ...data,
      }),
    });
  },

  updateConversation: async (
    conversationId: string,
    data: { nome?: string; fotoUrl?: string; autoExcluir24h?: boolean }
  ): Promise<Conversation> => {
    return apiRequest<Conversation>(`/conversations/${conversationId}`, {
      method: 'PATCH',
      body: JSON.stringify(data),
    });
  },

  deleteConversation: async (conversationId: string): Promise<void> => {
    await apiRequest(`/conversations/${conversationId}`, {
      method: 'DELETE',
    });
  },

  clearConversation: async (conversationId: string): Promise<void> => {
    await apiRequest(`/conversations/${conversationId}/clear`, {
      method: 'POST',
    });
  },

  addConversationMembers: async (conversationId: string, userIds: string[]): Promise<Conversation> => {
    return apiRequest<Conversation>(`/conversations/${conversationId}/members`, {
      method: 'POST',
      body: JSON.stringify({ userIds }),
    });
  },

  getConversationMessages: async (conversationId: string): Promise<Message[]> => {
    return apiRequest<Message[]>(`/conversations/${conversationId}/messages`);
  },

  postConversationMessage: async (
    conversationId: string,
    data: { texto: string; tipo?: 'texto' | 'audio' | 'alerta'; audioDuracaoSegundos?: number }
  ): Promise<Message> => {
    return apiRequest<Message>(`/conversations/${conversationId}/messages`, {
      method: 'POST',
      body: JSON.stringify(data),
    });
  },

  deleteMessage: async (messageId: string): Promise<void> => {
    await apiRequest(`/messages/${messageId}`, {
      method: 'DELETE',
    });
  },

  // ─── COMUNICADOS ────────────────────────────────────────────────────────
  getAnnouncements: async (): Promise<Announcement[]> => {
    return apiRequest<Announcement[]>('/announcements');
  },

  createAnnouncement: async (data: {
    titulo: string;
    mensagem: string;
    prioridade: 'normal' | 'alta' | 'urgente';
    setorId?: string;
  }): Promise<Announcement> => {
    return apiRequest<Announcement>('/announcements', {
      method: 'POST',
      body: JSON.stringify(data),
    });
  },

  confirmAnnouncementRead: async (announcementId: string): Promise<void> => {
    await apiRequest(`/announcements/${announcementId}/confirm-read`, {
      method: 'POST',
    });
  },

  // ─── EMERGÊNCIA ─────────────────────────────────────────────────────────
  getEmergencyStatus: async (): Promise<EmergencyState> => {
    return apiRequest<EmergencyState>('/emergency/status');
  },

  triggerEmergencyAlert: async (message: string): Promise<EmergencyState> => {
    return apiRequest<EmergencyState>('/emergency/alert', {
      method: 'POST',
      body: JSON.stringify({ message }),
    });
  },

  dismissEmergencyAlert: async (): Promise<EmergencyState> => {
    return apiRequest<EmergencyState>('/emergency/dismiss', {
      method: 'POST',
    });
  },

  // ─── OUVIDORIA & DENÚNCIAS ──────────────────────────────────────────────
  getReports: async (): Promise<Report[]> => {
    return apiRequest<Report[]>('/reports');
  },

  createReport: async (data: {
    motivo: string;
    descricao: string;
    mensagemTrecho?: string;
    sigiloso?: boolean;
  }): Promise<Report> => {
    return apiRequest<Report>('/reports', {
      method: 'POST',
      body: JSON.stringify(data),
    });
  },

  updateReportStatus: async (
    reportId: string,
    status: 'pendente' | 'em_analise' | 'resolvido',
    observacoes?: string
  ): Promise<Report> => {
    return apiRequest<Report>(`/reports/${reportId}/status`, {
      method: 'PATCH',
      body: JSON.stringify({ status, observacoes }),
    });
  },

  // ─── AUDITORIA & DASHBOARD EXECUTIVO (DIREÇÃO) ──────────────────────────
  getAuditLogs: async (search?: string): Promise<AuditLog[]> => {
    const query = search ? `?search=${encodeURIComponent(search)}` : '';
    return apiRequest<AuditLog[]>(`/admin/audit-logs${query}`);
  },

  getAdminStats: async (): Promise<any> => {
    return apiRequest<any>('/admin/stats');
  },

  // ─── NOTIFICAÇÕES ───────────────────────────────────────────────────────
  getNotifications: async (): Promise<NotificationItem[]> => {
    return apiRequest<NotificationItem[]>('/notifications');
  },

  markNotificationRead: async (id: string): Promise<void> => {
    await apiRequest(`/notifications/${id}/read`, {
      method: 'PATCH',
    });
  },

  deleteNotification: async (id: string): Promise<void> => {
    await apiRequest(`/notifications/${id}`, {
      method: 'DELETE',
    });
  },

  markConversationRead: async (conversationId: string): Promise<void> => {
    await apiRequest(`/conversations/${conversationId}/read`, {
      method: 'POST',
    });
  },

  clearNotifications: async (): Promise<void> => {
    await apiRequest('/notifications/clear', {
      method: 'POST',
    });
  },
};
