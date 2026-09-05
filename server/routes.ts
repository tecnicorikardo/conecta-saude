import { Router, Request, Response } from 'express';
import { db } from './db';
import { authenticate, requireHierarchy } from './middleware';

export const apiRouter = Router();

// ─── HEALTH CHECK ─────────────────────────────────────────────────────────
apiRouter.get('/health', (_req, res) => {
  res.json({
    status: 'ok',
    sistema: 'Conecta Saúde — Plataforma Institucional SUS',
    versao: '2.0.0-fullstack',
    timestamp: new Date().toISOString(),
  });
});

// ─── AUTH & CURRENT USER ──────────────────────────────────────────────────
// Retorna a lista de usuários para troca de perfil institucional
apiRouter.get('/auth/profiles', (_req, res) => {
  const allUsers = db.getAllUsersAdmin();
  res.json({ success: true, data: allUsers });
});

// Retorna dados do usuário atualmente autenticado
apiRouter.get('/auth/me', authenticate, (req: Request, res: Response) => {
  const user = req.user!;
  res.json({
    success: true,
    data: {
      ...user,
      permissoes: {
        isDirecao: user.hierarquiaNivel === 1,
        isCoordenacao: user.hierarquiaNivel === 2,
        isSupervisao: user.hierarquiaNivel === 3,
        isFuncionario: user.hierarquiaNivel === 4,
        canManageEmployees: user.hierarquiaNivel === 1,
        canPublishAnnouncements: user.hierarquiaNivel <= 2,
        canTriggerEmergency: user.hierarquiaNivel <= 2,
        canViewAudit: user.hierarquiaNivel === 1,
        canViewReports: user.hierarquiaNivel === 1,
      },
    },
  });
});

// ─── SETORES ──────────────────────────────────────────────────────────────
apiRouter.get('/sectors', authenticate, (_req: Request, res: Response) => {
  const sectors = db.getSectors();
  res.json({ success: true, data: sectors });
});

// ─── USUÁRIOS & GESTÃO FUNCIONAL ──────────────────────────────────────────
// Lista colaboradores respeitando estritamente o isolamento de centro e hierarquia
apiRouter.get('/users', authenticate, (req: Request, res: Response) => {
  const actor = req.user!;
  const { setorId, ativo, search } = req.query as {
    setorId?: string;
    ativo?: string;
    search?: string;
  };

  const users = db.getUsers(actor, {
    setorId,
    ativo: ativo !== undefined ? ativo === 'true' : undefined,
    search,
  });

  res.json({ success: true, data: users });
});

// Criação de novo colaborador (exclusivo Direção e Coordenação)
apiRouter.post('/users', authenticate, (req: Request, res: Response) => {
  try {
    const actor = req.user!;
    const { nome, email, cargo, hierarquiaNivel, setorId, matricula, telefone } = req.body;

    if (!nome || !email || !cargo || !hierarquiaNivel || !setorId) {
      res.status(400).json({ success: false, error: 'Campos obrigatórios incompletos.' });
      return;
    }

    const newUser = db.createUser(actor, {
      nome,
      email,
      cargo,
      hierarquiaNivel: Number(hierarquiaNivel) as any,
      setorId,
      ativo: true,
      matricula,
      telefone,
    });

    res.status(201).json({ success: true, data: newUser });
  } catch (err: any) {
    res.status(403).json({ success: false, error: err.message });
  }
});

// Ativação / Desativação de funcionário (exclusivo Direção Geral)
apiRouter.patch('/users/:id/toggle-status', authenticate, (req: Request, res: Response) => {
  try {
    const actor = req.user!;
    const targetUserId = req.params.id;
    const updated = db.toggleUserStatus(actor, targetUserId);
    res.json({ success: true, data: updated });
  } catch (err: any) {
    res.status(403).json({ success: false, error: err.message });
  }
});

// ─── CANAIS ───────────────────────────────────────────────────────────────
apiRouter.get('/channels', authenticate, (req: Request, res: Response) => {
  const actor = req.user!;
  const channels = db.getChannels(actor);
  res.json({ success: true, data: channels });
});

apiRouter.post('/channels', authenticate, (req: Request, res: Response) => {
  try {
    const actor = req.user!;
    const { nome, descricao, tipo, setorId } = req.body;

    if (!nome || !descricao || !tipo) {
      res.status(400).json({ success: false, error: 'Nome, descrição e tipo são obrigatórios.' });
      return;
    }

    const newChannel = db.createChannel(actor, { nome, descricao, tipo, setorId });
    res.status(201).json({ success: true, data: newChannel });
  } catch (err: any) {
    res.status(403).json({ success: false, error: err.message });
  }
});

apiRouter.get('/channels/:id/messages', authenticate, (req: Request, res: Response) => {
  try {
    const actor = req.user!;
    const messages = db.getChannelMessages(actor, req.params.id);
    res.json({ success: true, data: messages });
  } catch (err: any) {
    res.status(403).json({ success: false, error: err.message });
  }
});

apiRouter.post('/channels/:id/messages', authenticate, (req: Request, res: Response) => {
  try {
    const actor = req.user!;
    const { texto, tipo, audioDuracaoSegundos } = req.body;

    if (!texto) {
      res.status(400).json({ success: false, error: 'O conteúdo da mensagem não pode ser vazio.' });
      return;
    }

    const message = db.postChannelMessage(actor, req.params.id, {
      texto,
      tipo,
      audioDuracaoSegundos,
    });
    res.status(201).json({ success: true, data: message });
  } catch (err: any) {
    res.status(403).json({ success: false, error: err.message });
  }
});

// ─── CONVERSAS (CHAT DIRETO) ──────────────────────────────────────────────
apiRouter.get('/conversations', authenticate, (req: Request, res: Response) => {
  const actor = req.user!;
  const convs = db.getConversations(actor);
  res.json({ success: true, data: convs });
});

apiRouter.post('/conversations', authenticate, (req: Request, res: Response) => {
  try {
    const actor = req.user!;
    const { targetUserId } = req.body;

    if (!targetUserId) {
      res.status(400).json({ success: false, error: 'ID do destinatário é obrigatório.' });
      return;
    }

    const conv = db.createConversation(actor, targetUserId);
    res.status(201).json({ success: true, data: conv });
  } catch (err: any) {
    res.status(403).json({ success: false, error: err.message });
  }
});

apiRouter.get('/conversations/:id/messages', authenticate, (req: Request, res: Response) => {
  try {
    const actor = req.user!;
    const messages = db.getConversationMessages(actor, req.params.id);
    res.json({ success: true, data: messages });
  } catch (err: any) {
    res.status(403).json({ success: false, error: err.message });
  }
});

apiRouter.post('/conversations/:id/messages', authenticate, (req: Request, res: Response) => {
  try {
    const actor = req.user!;
    const { texto, tipo, audioDuracaoSegundos } = req.body;

    if (!texto) {
      res.status(400).json({ success: false, error: 'O conteúdo da mensagem não pode ser vazio.' });
      return;
    }

    const message = db.postConversationMessage(actor, req.params.id, {
      texto,
      tipo,
      audioDuracaoSegundos,
    });
    res.status(201).json({ success: true, data: message });
  } catch (err: any) {
    res.status(403).json({ success: false, error: err.message });
  }
});

// Exclusão / Soft-delete de mensagem
apiRouter.delete('/messages/:id', authenticate, (req: Request, res: Response) => {
  try {
    const actor = req.user!;
    db.deleteMessage(actor, req.params.id);
    res.json({ success: true, message: 'Mensagem apagada com sucesso.' });
  } catch (err: any) {
    res.status(403).json({ success: false, error: err.message });
  }
});

// Marcar conversa e notificações como lidas
apiRouter.post('/conversations/:id/read', authenticate, (req: Request, res: Response) => {
  try {
    const actor = req.user!;
    db.markConversationRead(actor, req.params.id);
    res.json({ success: true, message: 'Conversa e notificações marcadas como lidas.' });
  } catch (err: any) {
    res.status(403).json({ success: false, error: err.message });
  }
});

// ─── COMUNICADOS INSTITUCIONAIS ───────────────────────────────────────────
apiRouter.get('/announcements', authenticate, (req: Request, res: Response) => {
  const actor = req.user!;
  const list = db.getAnnouncements(actor);
  res.json({ success: true, data: list });
});

apiRouter.post('/announcements', authenticate, (req: Request, res: Response) => {
  try {
    const actor = req.user!;
    const { titulo, mensagem, prioridade, setorId } = req.body;

    if (!titulo || !mensagem) {
      res.status(400).json({ success: false, error: 'Título e mensagem são obrigatórios.' });
      return;
    }

    const ann = db.createAnnouncement(actor, {
      titulo,
      mensagem,
      prioridade: prioridade || 'normal',
      setorId,
    });

    res.status(201).json({ success: true, data: ann });
  } catch (err: any) {
    res.status(403).json({ success: false, error: err.message });
  }
});

// Confirmação de leitura formal
apiRouter.post('/announcements/:id/confirm-read', authenticate, (req: Request, res: Response) => {
  try {
    const actor = req.user!;
    db.confirmAnnouncementRead(actor, req.params.id);
    res.json({ success: true, message: 'Leitura formal registrada no prontuário institucional.' });
  } catch (err: any) {
    res.status(404).json({ success: false, error: err.message });
  }
});

// ─── EMERGÊNCIA & RAMAIS ──────────────────────────────────────────────────
apiRouter.get('/emergency/status', authenticate, (_req: Request, res: Response) => {
  const status = db.getEmergencyStatus();
  res.json({ success: true, data: status });
});

apiRouter.post('/emergency/alert', authenticate, (req: Request, res: Response) => {
  try {
    const actor = req.user!;
    const { message } = req.body;

    if (!message) {
      res.status(400).json({ success: false, error: 'A mensagem do alerta de emergência é obrigatória.' });
      return;
    }

    const updated = db.triggerEmergencyAlert(actor, message);
    res.status(201).json({ success: true, data: updated });
  } catch (err: any) {
    res.status(403).json({ success: false, error: err.message });
  }
});

apiRouter.post('/emergency/dismiss', authenticate, (req: Request, res: Response) => {
  try {
    const actor = req.user!;
    const updated = db.dismissEmergencyAlert(actor);
    res.json({ success: true, data: updated });
  } catch (err: any) {
    res.status(403).json({ success: false, error: err.message });
  }
});

// ─── OUVIDORIA & DENÚNCIAS ────────────────────────────────────────────────
apiRouter.get('/reports', authenticate, (req: Request, res: Response) => {
  const actor = req.user!;
  const reports = db.getReports(actor);
  res.json({ success: true, data: reports });
});

apiRouter.post('/reports', authenticate, (req: Request, res: Response) => {
  try {
    const actor = req.user!;
    const { motivo, descricao, mensagemTrecho, sigiloso } = req.body;

    if (!motivo || !descricao) {
      res.status(400).json({ success: false, error: 'Motivo e descrição detalhada são obrigatórios.' });
      return;
    }

    const rep = db.createReport(actor, {
      motivo,
      descricao,
      mensagemTrecho,
      sigiloso,
    });

    res.status(201).json({ success: true, data: rep });
  } catch (err: any) {
    res.status(400).json({ success: false, error: err.message });
  }
});

apiRouter.patch('/reports/:id/status', authenticate, (req: Request, res: Response) => {
  try {
    const actor = req.user!;
    const { status, observacoes } = req.body;

    if (!status || !['pendente', 'em_analise', 'resolvido'].includes(status)) {
      res.status(400).json({ success: false, error: 'Status inválido fornecido.' });
      return;
    }

    const updated = db.updateReportStatus(actor, req.params.id, status, observacoes);
    res.json({ success: true, data: updated });
  } catch (err: any) {
    res.status(403).json({ success: false, error: err.message });
  }
});

// ─── AUDITORIA & COMPLIANCE (ESTRITO NÍVEL 1) ──────────────────────────────
apiRouter.get('/admin/audit-logs', authenticate, (req: Request, res: Response) => {
  try {
    const actor = req.user!;
    const { search } = req.query as { search?: string };
    const logs = db.getAuditLogs(actor, search);
    res.json({ success: true, data: logs });
  } catch (err: any) {
    res.status(403).json({ success: false, error: err.message });
  }
});

apiRouter.get('/admin/stats', authenticate, (req: Request, res: Response) => {
  try {
    const actor = req.user!;
    const stats = db.getAdminStats(actor);
    res.json({ success: true, data: stats });
  } catch (err: any) {
    res.status(403).json({ success: false, error: err.message });
  }
});

// ─── NOTIFICAÇÕES ─────────────────────────────────────────────────────────
apiRouter.get('/notifications', authenticate, (req: Request, res: Response) => {
  const actor = req.user!;
  const notifs = db.getNotifications(actor);
  res.json({ success: true, data: notifs });
});

apiRouter.patch('/notifications/:id/read', authenticate, (req: Request, res: Response) => {
  const actor = req.user!;
  db.markNotificationRead(actor, req.params.id);
  res.json({ success: true });
});

apiRouter.post('/notifications/clear', authenticate, (req: Request, res: Response) => {
  const actor = req.user!;
  db.clearNotifications(actor);
  res.json({ success: true });
});

apiRouter.delete('/notifications/:id', authenticate, (req: Request, res: Response) => {
  const actor = req.user!;
  db.deleteNotification(actor, req.params.id);
  res.json({ success: true, message: 'Notificação excluída com sucesso.' });
});
