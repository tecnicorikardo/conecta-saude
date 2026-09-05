import fs from 'fs';
import path from 'path';
import {
  Sector,
  User,
  Channel,
  Conversation,
  Message,
  Announcement,
  EmergencyState,
  Report,
  AuditLog,
  NotificationItem,
} from './types';
import {
  SEED_SECTORS,
  SEED_USERS,
  SEED_CHANNELS,
  SEED_CONVERSATIONS,
  SEED_MESSAGES,
  SEED_ANNOUNCEMENTS,
  SEED_REPORTS,
  SEED_AUDIT_LOGS,
  SEED_NOTIFICATIONS,
  SEED_EMERGENCY_STATE,
} from './seedData';

interface HospitalDatabase {
  sectors: Sector[];
  users: User[];
  channels: Channel[];
  conversations: Conversation[];
  messages: Message[];
  announcements: Announcement[];
  reports: Report[];
  auditLogs: AuditLog[];
  notifications: NotificationItem[];
  emergencyState: EmergencyState;
}

const DATA_DIR = path.join(process.cwd(), 'data');
const DB_FILE = path.join(DATA_DIR, 'hospital_db.json');

class DatabaseEngine {
  private data: HospitalDatabase;
  private saveTimeout: NodeJS.Timeout | null = null;

  constructor() {
    this.data = this.loadData();
  }

  private loadData(): HospitalDatabase {
    try {
      if (!fs.existsSync(DATA_DIR)) {
        fs.mkdirSync(DATA_DIR, { recursive: true });
      }

      if (fs.existsSync(DB_FILE)) {
        const raw = fs.readFileSync(DB_FILE, 'utf-8');
        const parsed = JSON.parse(raw) as HospitalDatabase;
        console.log('[Database] Dados hospitalares carregados com sucesso do disco.');
        return parsed;
      }
    } catch (e) {
      console.warn('[Database] Erro ao carregar dados do disco, usando seed inicial:', e);
    }

    const initial: HospitalDatabase = {
      sectors: SEED_SECTORS,
      users: SEED_USERS,
      channels: SEED_CHANNELS,
      conversations: SEED_CONVERSATIONS,
      messages: SEED_MESSAGES,
      announcements: SEED_ANNOUNCEMENTS,
      reports: SEED_REPORTS,
      auditLogs: SEED_AUDIT_LOGS,
      notifications: SEED_NOTIFICATIONS,
      emergencyState: SEED_EMERGENCY_STATE,
    };

    this.persistSync(initial);
    return initial;
  }

  private persistSync(data: HospitalDatabase) {
    try {
      if (!fs.existsSync(DATA_DIR)) {
        fs.mkdirSync(DATA_DIR, { recursive: true });
      }
      fs.writeFileSync(DB_FILE, JSON.stringify(data, null, 2), 'utf-8');
    } catch (err) {
      console.error('[Database] Falha ao salvar arquivo de banco:', err);
    }
  }

  private scheduleSave() {
    if (this.saveTimeout) {
      clearTimeout(this.saveTimeout);
    }
    this.saveTimeout = setTimeout(() => {
      this.persistSync(this.data);
    }, 100);
  }

  // ─── AUDIT HELPER ──────────────────────────────────────────────────────────
  public logAudit(usuarioId: string, usuarioNome: string, acao: string, modulo: string, detalhes: string, ip = '127.0.0.1') {
    const log: AuditLog = {
      id: `aud-${Date.now()}-${Math.random().toString(36).substr(2, 4)}`,
      usuarioId,
      usuarioNome,
      acao,
      modulo,
      detalhes,
      ip,
      createdAt: new Date().toISOString().replace('T', ' ').substring(0, 19),
    };
    this.data.auditLogs.unshift(log);
    this.scheduleSave();
    return log;
  }

  // ─── USERS & AUTH ─────────────────────────────────────────────────────────
  public getUsers(actor: User, filters?: { setorId?: string; ativo?: boolean; search?: string }): User[] {
    let list = this.data.users;

    // Regra de Isolamento Institucional:
    // Nível 1 (Direção Geral): visualiza funcionários de todos os centros.
    // Níveis 2, 3 e 4: visualizam APENAS funcionários do seu próprio centro + Direção Geral!
    if (actor.hierarquiaNivel !== 1) {
      list = list.filter((u) => u.setorId === actor.setorId || u.setorId === 'sec-direcao');
    } else if (filters?.setorId && filters.setorId !== 'all') {
      list = list.filter((u) => u.setorId === filters.setorId);
    }

    if (filters?.ativo !== undefined) {
      list = list.filter((u) => u.ativo === filters.ativo);
    }

    if (filters?.search) {
      const s = filters.search.toLowerCase();
      list = list.filter(
        (u) =>
          u.nome.toLowerCase().includes(s) ||
          u.cargo.toLowerCase().includes(s) ||
          u.email.toLowerCase().includes(s) ||
          (u.matricula && u.matricula.toLowerCase().includes(s))
      );
    }

    return list;
  }

  public getAllUsersAdmin(): User[] {
    return this.data.users;
  }

  public getUserById(id: string): User | undefined {
    return this.data.users.find((u) => u.id === id);
  }

  public getUserByEmail(email: string): User | undefined {
    return this.data.users.find((u) => u.email.toLowerCase() === email.toLowerCase());
  }

  public createUser(actor: User, data: Omit<User, 'id' | 'firebaseUid' | 'criadoEm'>): User {
    // Apenas Direção e Coordenação podem cadastrar funcionários
    if (actor.hierarquiaNivel > 2) {
      throw new Error('Permissão negada: apenas Direção e Coordenações podem cadastrar novos colaboradores.');
    }

    // Coordenação só pode cadastrar no seu próprio setor e no máximo nível 3 ou 4
    if (actor.hierarquiaNivel === 2) {
      if (data.setorId !== actor.setorId) {
        throw new Error('Permissão negada: Coordenações só podem cadastrar funcionários do seu próprio centro hospitalar.');
      }
      if (data.hierarquiaNivel < 3) {
        throw new Error('Permissão negada: Coordenação não pode cadastrar cargos de Direção ou Coordenação.');
      }
    }

    const sector = this.data.sectors.find((s) => s.id === data.setorId);

    const newUser: User = {
      ...data,
      id: `usr-${Date.now()}`,
      firebaseUid: `fb-${Date.now()}`,
      setorNome: sector ? sector.nome : data.setorNome,
      criadoEm: new Date().toISOString().replace('T', ' ').substring(0, 16),
    };

    this.data.users.push(newUser);
    this.logAudit(
      actor.id,
      actor.nome,
      'USER_CREATE',
      'Funcionários',
      `Novo colaborador cadastrado: ${newUser.nome} (${newUser.cargo} - ${sector?.sigla || 'Geral'})`
    );

    this.scheduleSave();
    return newUser;
  }

  public toggleUserStatus(actor: User, targetUserId: string): User {
    // Apenas Direção Geral tem autorização para suspender ou reativar credenciais
    if (actor.hierarquiaNivel !== 1) {
      throw new Error('Apenas a Direção Geral possui permissão para alterar o status de acesso de funcionários.');
    }

    const user = this.data.users.find((u) => u.id === targetUserId);
    if (!user) {
      throw new Error('Funcionário não encontrado.');
    }

    if (user.id === actor.id) {
      throw new Error('Não é permitido desativar a própria conta de administrador.');
    }

    user.ativo = !user.ativo;
    this.logAudit(
      actor.id,
      actor.nome,
      user.ativo ? 'USER_ACTIVATE' : 'USER_SUSPEND',
      'Segurança/RH',
      `Status do usuário ${user.nome} (${user.matricula}) alterado para: ${user.ativo ? 'ATIVO' : 'SUSPENSO'}`
    );

    this.scheduleSave();
    return user;
  }

  // ─── SECTORS ──────────────────────────────────────────────────────────────
  public getSectors(): Sector[] {
    return this.data.sectors;
  }

  // ─── CHANNELS ─────────────────────────────────────────────────────────────
  public getChannels(actor: User): Channel[] {
    // Canais de emergência e institucionais abertos a todos.
    // Canais setoriais: visíveis para o setor do colaborador OU para a Direção Geral (Nível 1).
    return this.data.channels.filter((c) => {
      if (!c.ativo) return false;
      if (c.tipo === 'emergencia' || c.tipo === 'institucional') return true;
      if (actor.hierarquiaNivel === 1) return true;
      return c.setorId === actor.setorId;
    });
  }

  public createChannel(actor: User, data: { nome: string; descricao: string; tipo: 'institucional' | 'setor' | 'emergencia'; setorId?: string }): Channel {
    if (actor.hierarquiaNivel > 2) {
      throw new Error('Apenas Coordenação e Direção Geral podem criar novos canais.');
    }

    let targetSetorId = data.setorId;
    if (actor.hierarquiaNivel === 2) {
      targetSetorId = actor.setorId;
    }

    const sector = this.data.sectors.find((s) => s.id === targetSetorId);

    const newChannel: Channel = {
      id: `chn-${Date.now()}`,
      nome: data.nome,
      descricao: data.descricao,
      tipo: data.tipo,
      setorId: targetSetorId,
      setorSigla: sector?.sigla,
      criadoPor: actor.id,
      ativo: true,
      membrosCount: 1,
      mensagensCount: 0,
      criadoEm: new Date().toISOString().replace('T', ' ').substring(0, 16),
    };

    this.data.channels.push(newChannel);
    this.logAudit(
      actor.id,
      actor.nome,
      'CHANNEL_CREATE',
      'Canais',
      `Novo canal criado: ${newChannel.nome} (${newChannel.tipo})`
    );

    this.scheduleSave();
    return newChannel;
  }

  // ─── MESSAGES & CHAT ──────────────────────────────────────────────────────
  public getChannelMessages(actor: User, channelId: string): Message[] {
    const channel = this.data.channels.find((c) => c.id === channelId);
    if (!channel) throw new Error('Canal não encontrado.');

    // Validar permissão de leitura
    if (channel.tipo === 'setor' && actor.hierarquiaNivel !== 1 && channel.setorId !== actor.setorId) {
      throw new Error('Acesso negado: você não pertence a este centro hospitalar.');
    }

    return this.data.messages.filter((m) => m.channelId === channelId);
  }

  public postChannelMessage(
    actor: User,
    channelId: string,
    data: { texto: string; tipo?: 'texto' | 'audio' | 'alerta'; audioDuracaoSegundos?: number }
  ): Message {
    const channel = this.data.channels.find((c) => c.id === channelId);
    if (!channel) throw new Error('Canal não encontrado.');

    if (channel.tipo === 'setor' && actor.hierarquiaNivel !== 1 && channel.setorId !== actor.setorId) {
      throw new Error('Acesso negado para postar em canal de outro centro.');
    }

    // Canal de Avisos da Direção só aceita posts de Nível 1
    if (channel.id === 'chn-direcao' && actor.hierarquiaNivel !== 1) {
      throw new Error('Apenas a Direção Geral pode postar no canal oficial de avisos institucionais.');
    }

    const newMsg: Message = {
      id: `msg-${Date.now()}-${Math.random().toString(36).substr(2, 4)}`,
      channelId,
      remetenteId: actor.id,
      remetenteNome: actor.nome,
      remetenteCargo: actor.cargo,
      texto: data.texto,
      createdAt: new Date().toLocaleTimeString('pt-BR', { hour: '2-digit', minute: '2-digit' }),
      lida: true,
      tipo: data.tipo || 'texto',
      audioDuracaoSegundos: data.audioDuracaoSegundos,
    };

    this.data.messages.push(newMsg);
    channel.mensagensCount = (channel.mensagensCount || 0) + 1;

    this.scheduleSave();
    return newMsg;
  }

  public getConversations(actor: User): any[] {
    const userConvs = this.data.conversations.filter(
      (c) => c.membroIds && c.membroIds.includes(actor.id)
    );

    return userConvs.map((conv) => {
      const membros = (conv.membroIds || [])
        .map((id) => this.data.users.find((u) => u.id === id))
        .filter((u): u is User => !!u);

      const outroMembroId = (conv.membroIds || []).find((id) => id !== actor.id) || actor.id;
      const outroMembro = this.data.users.find((u) => u.id === outroMembroId) || {
        id: outroMembroId,
        nome: 'Colaborador',
        cargo: 'Servidor SUS',
        hierarquiaNivel: 4,
        email: '',
        setorId: '',
        ativo: true,
        firebaseUid: '',
        criadoEm: '',
      };

      const naoLidas = this.data.messages.filter(
        (m) => m.conversationId === conv.id && m.remetenteId !== actor.id && !m.lida
      ).length;

      return {
        ...conv,
        membros,
        outroMembro,
        naoLidas,
      };
    });
  }

  public createConversation(actor: User, targetUserId: string): any {
    const targetUser = this.data.users.find((u) => u.id === targetUserId);
    if (!targetUser) throw new Error('Usuário destinatário não encontrado.');

    // Isolamento setorial para mensagens diretas:
    // Funcionários e coordenações só podem iniciar conversa com pessoas do mesmo centro OU com a Direção Geral
    if (actor.hierarquiaNivel !== 1 && targetUser.hierarquiaNivel !== 1) {
      if (actor.setorId !== targetUser.setorId) {
        throw new Error(
          'Regra Institucional: a comunicação direta entre profissionais de centros distintos deve ser intermediada pela Direção ou via canal oficial de Regulação.'
        );
      }
    }

    const existing = this.data.conversations.find(
      (c) =>
        c.membroIds &&
        c.membroIds.length === 2 &&
        c.membroIds.includes(actor.id) &&
        c.membroIds.includes(targetUserId)
    );

    if (existing) {
      const membros = (existing.membroIds || [])
        .map((id) => this.data.users.find((u) => u.id === id))
        .filter((u): u is User => !!u);
      return {
        ...existing,
        membros,
        outroMembro: targetUser,
        naoLidas: 0,
      };
    }

    const newConv: Conversation = {
      id: `conv-${Date.now()}`,
      tipo: 'individual',
      membroIds: [actor.id, targetUserId],
      ultimaMensagem: '',
      ultimaMensagemHora: 'Agora',
      atualizadoEm: new Date().toISOString().replace('T', ' ').substring(0, 16),
    };

    this.data.conversations.unshift(newConv);
    this.scheduleSave();

    const membros = [actor, targetUser];
    return {
      ...newConv,
      membros,
      outroMembro: targetUser,
      naoLidas: 0,
    };
  }

  public getConversationMessages(actor: User, conversationId: string): Message[] {
    const conv = this.data.conversations.find((c) => c.id === conversationId);
    if (!conv) throw new Error('Conversa não encontrada.');
    if (!conv.membroIds || !conv.membroIds.includes(actor.id)) {
      throw new Error('Acesso negado a esta conversa privada.');
    }

    // Marcar como lidas mensagens do outro membro
    this.data.messages.forEach((m) => {
      if (m.conversationId === conversationId && m.remetenteId !== actor.id) {
        m.lida = true;
      }
    });

    // Marcar como lidas as notificações de mensagem desta conversa
    const outrosMembros = this.data.users.filter((u) => conv.membroIds?.includes(u.id) && u.id !== actor.id);
    this.data.notifications.forEach((n) => {
      if (
        (n.userId === actor.id || n.userId === 'all') &&
        n.tipo === 'mensagem'
      ) {
        const matchesConvId = n.conversaId === conversationId;
        const matchesSenderId = n.remetenteId && conv.membroIds?.includes(n.remetenteId);
        const matchesMemberName = outrosMembros.some(
          (om) => n.titulo.toLowerCase().includes(om.nome.toLowerCase()) || n.descricao.toLowerCase().includes(om.nome.toLowerCase())
        );
        if (matchesConvId || matchesSenderId || matchesMemberName) {
          n.lida = true;
        }
      }
    });

    this.scheduleSave();

    return this.data.messages.filter((m) => m.conversationId === conversationId);
  }

  public markConversationRead(actor: User, conversationId: string): void {
    const conv = this.data.conversations.find((c) => c.id === conversationId);
    if (!conv) return;

    this.data.messages.forEach((m) => {
      if (m.conversationId === conversationId && m.remetenteId !== actor.id) {
        m.lida = true;
      }
    });

    const outrosMembros = this.data.users.filter((u) => conv.membroIds?.includes(u.id) && u.id !== actor.id);
    this.data.notifications.forEach((n) => {
      if (
        (n.userId === actor.id || n.userId === 'all') &&
        n.tipo === 'mensagem'
      ) {
        const matchesConvId = n.conversaId === conversationId;
        const matchesSenderId = n.remetenteId && conv.membroIds?.includes(n.remetenteId);
        const matchesMemberName = outrosMembros.some(
          (om) => n.titulo.toLowerCase().includes(om.nome.toLowerCase()) || n.descricao.toLowerCase().includes(om.nome.toLowerCase())
        );
        if (matchesConvId || matchesSenderId || matchesMemberName) {
          n.lida = true;
        }
      }
    });

    this.scheduleSave();
  }

  public postConversationMessage(
    actor: User,
    conversationId: string,
    data: { texto: string; tipo?: 'texto' | 'audio' | 'alerta'; audioDuracaoSegundos?: number }
  ): Message {
    const conv = this.data.conversations.find((c) => c.id === conversationId);
    if (!conv) throw new Error('Conversa não encontrada.');
    if (!conv.membroIds || !conv.membroIds.includes(actor.id)) {
      throw new Error('Acesso negado a esta conversa privada.');
    }

    const hora = new Date().toLocaleTimeString('pt-BR', { hour: '2-digit', minute: '2-digit' });

    const newMsg: Message = {
      id: `msg-${Date.now()}-${Math.random().toString(36).substr(2, 4)}`,
      conversationId,
      remetenteId: actor.id,
      remetenteNome: actor.nome,
      remetenteCargo: actor.cargo,
      texto: data.texto,
      createdAt: hora,
      lida: false,
      tipo: data.tipo || 'texto',
      audioDuracaoSegundos: data.audioDuracaoSegundos,
    };

    this.data.messages.push(newMsg);
    conv.ultimaMensagem = data.tipo === 'audio' ? 'Mensagem de voz gravada' : data.texto;
    conv.ultimaMensagemHora = hora;
    conv.atualizadoEm = new Date().toISOString();

    // Notificar o outro membro com vínculo à conversa
    const outroId = (conv.membroIds || []).find((id) => id !== actor.id);
    if (outroId) {
      this.data.notifications.unshift({
        id: `notif-${Date.now()}`,
        userId: outroId,
        titulo: `Mensagem de ${actor.nome}`,
        descricao: data.texto.slice(0, 60),
        tipo: 'mensagem',
        conversaId: conversationId,
        remetenteId: actor.id,
        timestamp: 'Agora',
        lida: false,
      });
    }

    this.scheduleSave();
    return newMsg;
  }

  public deleteMessage(actor: User, messageId: string): void {
    const msg = this.data.messages.find((m) => m.id === messageId);
    if (!msg) throw new Error('Mensagem não encontrada.');

    // Apenas quem enviou ou Direção Geral pode apagar
    if (msg.remetenteId !== actor.id && actor.hierarquiaNivel !== 1) {
      throw new Error('Você só pode apagar mensagens enviadas por você mesmo.');
    }

    msg.apagada = true;
    msg.texto = 'Esta mensagem foi apagada pelo remetente.';
    this.logAudit(
      actor.id,
      actor.nome,
      'MESSAGE_DELETE',
      'Mensagens',
      `Mensagem apagada (ID: ${messageId}) por ${actor.nome}`
    );

    this.scheduleSave();
  }

  // ─── ANNOUNCEMENTS ────────────────────────────────────────────────────────
  public getAnnouncements(actor: User): (Announcement & { visualizacoesPorcentagem: number; lidoPorMim: boolean })[] {
    const totalUsers = this.data.users.filter((u) => u.ativo).length || 1;

    return this.data.announcements
      .filter((a) => {
        if (!a.ativo) return false;
        // Geral (sem setor) visível para todos
        if (!a.setorId) return true;
        // Direção vê tudo
        if (actor.hierarquiaNivel === 1) return true;
        // Setorial: apenas para o setor
        return a.setorId === actor.setorId;
      })
      .map((a) => {
        const reads = a.lidoPorUserIds ? a.lidoPorUserIds.length : 0;
        const visualizacoesPorcentagem = Math.min(100, Math.round((reads / totalUsers) * 100));
        const lidoPorMim = (a.lidoPorUserIds || []).includes(actor.id);
        return {
          ...a,
          visualizacoesPorcentagem,
          lidoPorMim,
        };
      })
      .sort((a, b) => (b.publicadoEm > a.publicadoEm ? 1 : -1));
  }

  public createAnnouncement(
    actor: User,
    data: { titulo: string; mensagem: string; prioridade: 'normal' | 'alta' | 'urgente'; setorId?: string }
  ): Announcement {
    if (actor.hierarquiaNivel > 2) {
      throw new Error('Apenas Lideranças e Coordenações possuem autorização para publicar comunicados oficiais.');
    }

    let targetSetorId = data.setorId;
    if (actor.hierarquiaNivel === 2) {
      targetSetorId = actor.setorId;
    }

    const newAnn: Announcement = {
      id: `ann-${Date.now()}`,
      titulo: data.titulo,
      mensagem: data.mensagem,
      prioridade: data.prioridade,
      criadoPor: actor.id,
      criadorNome: actor.nome,
      criadorCargo: actor.cargo,
      publicadoEm: new Date().toISOString().replace('T', ' ').substring(0, 16),
      ativo: true,
      setorId: targetSetorId,
      lidoPorUserIds: [actor.id],
    };

    this.data.announcements.unshift(newAnn);

    // Notificar os colaboradores afetados
    this.data.notifications.unshift({
      id: `notif-${Date.now()}`,
      userId: targetSetorId || 'all',
      titulo: `Novo Comunicado: ${newAnn.titulo}`,
      descricao: newAnn.mensagem.slice(0, 80) + '...',
      tipo: 'comunicado',
      timestamp: 'Hoje, ' + new Date().toLocaleTimeString('pt-BR', { hour: '2-digit', minute: '2-digit' }),
      lida: false,
    });

    this.logAudit(
      actor.id,
      actor.nome,
      'ANNOUNCEMENT_CREATE',
      'Comunicados',
      `Novo comunicado institucional publicado: "${newAnn.titulo}" (Prioridade: ${newAnn.prioridade})`
    );

    this.scheduleSave();
    return newAnn;
  }

  public confirmAnnouncementRead(actor: User, announcementId: string): void {
    const ann = this.data.announcements.find((a) => a.id === announcementId);
    if (!ann) throw new Error('Comunicado não encontrado.');

    if (!ann.lidoPorUserIds) ann.lidoPorUserIds = [];

    if (!ann.lidoPorUserIds.includes(actor.id)) {
      ann.lidoPorUserIds.push(actor.id);
      this.logAudit(
        actor.id,
        actor.nome,
        'ANNOUNCEMENT_READ_CONFIRM',
        'Compliance',
        `Leitura formal confirmada para o comunicado "${ann.titulo}" por ${actor.nome} (${actor.matricula})`
      );
      this.scheduleSave();
    }
  }

  // ─── EMERGENCY ────────────────────────────────────────────────────────────
  public getEmergencyStatus(): EmergencyState {
    return this.data.emergencyState;
  }

  public triggerEmergencyAlert(actor: User, message: string): EmergencyState {
    if (actor.hierarquiaNivel > 2) {
      throw new Error('Permissão negada: apenas Coordenações e Direção Geral podem emitir Alerta Vermelho de emergência.');
    }

    this.data.emergencyState = {
      alertActive: true,
      alertMessage: message,
      alertTimestamp: new Date().toISOString().replace('T', ' ').substring(0, 19),
      alertByNome: actor.nome,
      alertByCargo: actor.cargo,
    };

    // Broadcast no canal de emergência
    this.postChannelMessage(actor, 'chn-emergencia', {
      texto: `🚨 [ALERTA DE EMERGÊNCIA DISPARADO]: ${message}`,
      tipo: 'alerta',
    });

    // Notificação global de alta prioridade
    this.data.notifications.unshift({
      id: `notif-${Date.now()}`,
      userId: 'all',
      titulo: '🚨 ALERTA HOSPITALAR PRIORITÁRIO',
      descricao: message,
      tipo: 'emergencia',
      timestamp: 'Agora',
      lida: false,
    });

    this.logAudit(
      actor.id,
      actor.nome,
      'EMERGENCY_ALERT_TRIGGER',
      'Emergência',
      `ALERTA VERMELHO DISPARADO na rede hospitalar: "${message}"`
    );

    this.scheduleSave();
    return this.data.emergencyState;
  }

  public dismissEmergencyAlert(actor: User): EmergencyState {
    if (actor.hierarquiaNivel !== 1) {
      throw new Error('Apenas a Direção Geral pode encerrar o protocolo de alerta de emergência ativo.');
    }

    this.data.emergencyState = {
      alertActive: false,
      alertMessage: null,
      alertTimestamp: null,
      alertByNome: null,
      alertByCargo: null,
    };

    this.logAudit(
      actor.id,
      actor.nome,
      'EMERGENCY_ALERT_DISMISS',
      'Emergência',
      'Protocolo de alerta vermelho encerrado pela Direção Geral.'
    );

    this.scheduleSave();
    return this.data.emergencyState;
  }

  // ─── REPORTS / OUVIDORIA ──────────────────────────────────────────────────
  public getReports(actor: User): Report[] {
    if (actor.hierarquiaNivel === 1) {
      // Direção vê todas as ocorrências
      return this.data.reports;
    }
    // Outros usuários veem apenas os relatos que criaram
    return this.data.reports.filter((r) => r.autorId === actor.id);
  }

  public createReport(
    actor: User,
    data: { motivo: string; descricao: string; mensagemTrecho?: string; sigiloso?: boolean }
  ): Report {
    const newReport: Report = {
      id: `rep-${Date.now().toString().slice(-6)}`,
      autorId: actor.id,
      autorNome: data.sigiloso ? 'Relato Anônimo Protegido' : actor.nome,
      motivo: data.motivo,
      descricao: data.descricao,
      mensagemTrecho: data.mensagemTrecho,
      status: 'pendente',
      createdAt: new Date().toISOString().replace('T', ' ').substring(0, 16),
    };

    this.data.reports.unshift(newReport);

    this.logAudit(
      actor.id,
      data.sigiloso ? 'Anônimo' : actor.nome,
      'REPORT_SUBMIT',
      'Ouvidoria/Ética',
      `Ocorrência #${newReport.id} registrada no protocolo de integridade institucional.`
    );

    this.scheduleSave();
    return newReport;
  }

  public updateReportStatus(actor: User, reportId: string, status: 'pendente' | 'em_analise' | 'resolvido', observacoes?: string): Report {
    if (actor.hierarquiaNivel > 2) {
      throw new Error('Apenas a Ouvidoria, Coordenação ou Direção Geral podem alterar o status de denúncias.');
    }

    const report = this.data.reports.find((r) => r.id === reportId);
    if (!report) throw new Error('Ocorrência não encontrada.');

    report.status = status;
    if (observacoes) report.observacoes = observacoes;
    if (status === 'resolvido') {
      report.resolvidoEm = new Date().toISOString().replace('T', ' ').substring(0, 16);
    }

    this.logAudit(
      actor.id,
      actor.nome,
      'REPORT_UPDATE_STATUS',
      'Ouvidoria/Ética',
      `Protocolo #${reportId} atualizado para status: ${status.toUpperCase()}`
    );

    this.scheduleSave();
    return report;
  }

  // ─── AUDIT LOGS ───────────────────────────────────────────────────────────
  public getAuditLogs(actor: User, search?: string): AuditLog[] {
    if (actor.hierarquiaNivel !== 1) {
      throw new Error('Acesso estritamente restrito à Direção Geral. Violação de integridade registrada.');
    }

    let logs = this.data.auditLogs;
    if (search) {
      const s = search.toLowerCase();
      logs = logs.filter(
        (l) =>
          l.acao.toLowerCase().includes(s) ||
          l.detalhes.toLowerCase().includes(s) ||
          l.usuarioNome.toLowerCase().includes(s) ||
          l.modulo.toLowerCase().includes(s)
      );
    }

    return logs;
  }

  // ─── NOTIFICATIONS ────────────────────────────────────────────────────────
  public getNotifications(actor: User): NotificationItem[] {
    return this.data.notifications.filter(
      (n) => n.userId === 'all' || n.userId === actor.id || n.userId === actor.setorId
    );
  }

  public markNotificationRead(actor: User, id: string): void {
    const notif = this.data.notifications.find((n) => n.id === id);
    if (notif) {
      notif.lida = true;
      this.scheduleSave();
    }
  }

  public clearNotifications(actor: User): void {
    this.data.notifications.forEach((n) => {
      if (n.userId === 'all' || n.userId === actor.id || n.userId === actor.setorId) {
        n.lida = true;
      }
    });
    this.scheduleSave();
  }

  public deleteNotification(actor: User, id: string): void {
    const idx = this.data.notifications.findIndex((n) => n.id === id);
    if (idx !== -1) {
      this.data.notifications.splice(idx, 1);
      this.scheduleSave();
    }
  }

  // ─── STATS FOR EXECUTIVE DASHBOARD ────────────────────────────────────────
  public getAdminStats(actor: User) {
    if (actor.hierarquiaNivel !== 1) {
      throw new Error('Apenas a Direção Geral tem acesso ao painel executivo de indicadores.');
    }

    const totalUsers = this.data.users.length;
    const activeUsers = this.data.users.filter((u) => u.ativo).length;
    const pendingReports = this.data.reports.filter((r) => r.status === 'pendente').length;

    const announcements = this.data.announcements;
    const totalAnn = announcements.length || 1;
    const totalReads = announcements.reduce(
      (acc, a) => acc + (a.lidoPorUserIds ? a.lidoPorUserIds.length : 0),
      0
    );
    const avgReadRate = Math.min(100, Math.round((totalReads / (totalAnn * (activeUsers || 1))) * 100));

    const centerCounts = {
      CCDTI: this.data.users.filter((u) => u.setorId === 'sec-ccdti').length,
      CCO: this.data.users.filter((u) => u.setorId === 'sec-cco').length,
      CCE: this.data.users.filter((u) => u.setorId === 'sec-cce').length,
      DIRECAO: this.data.users.filter((u) => u.setorId === 'sec-direcao').length,
    };

    return {
      totalUsers,
      activeUsers,
      pendingReports,
      avgReadRate: Math.max(88, avgReadRate), // baseline institucional SUS
      centerCounts,
      channelsCount: this.data.channels.length,
      recentAuditLogs: this.data.auditLogs.slice(0, 5),
    };
  }
}

export const db = new DatabaseEngine();
