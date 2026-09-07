import { Request, Response } from 'express';
import { z } from 'zod';
import { prisma } from '../../config/database';
import { HierarquiaNivel } from '../../types';
import { AppError } from '../../middleware/errorHandler';
import { auditLog } from '../../utils/auditLogger';
import { getFirebaseMessaging } from '../../config/firebase';

const createChannelSchema = z.object({
  nome: z.string().min(2).max(80),
  descricao: z.string().max(300).optional(),
  tipo: z.enum(['institucional', 'setor', 'emergencia', 'geral']).default('geral'),
  setorId: z.string().uuid().optional(),
});

const addMemberSchema = z.object({
  userId: z.string().uuid(),
});

const postMessageSchema = z.object({
  texto: z.string().min(1, 'Mensagem não pode ser vazia').max(5000, 'Mensagem muito longa'),
});

// ─── Listar canais que o usuário tem acesso ───────────────────────────────────
export async function listChannels(req: Request, res: Response): Promise<void> {
  const actor = req.user!;

  const channels = await prisma.channel.findMany({
    where: {
      ativo: true,
      members: { some: { userId: actor.id } },
    },
    orderBy: [{ tipo: 'asc' }, { nome: 'asc' }],
    include: {
      setor: { select: { id: true, nome: true } },
      criador: { select: { id: true, nome: true } },
      _count: { select: { members: true } },
      messages: {
        take: 1,
        orderBy: { criadoEm: 'desc' },
        select: {
          id: true,
          texto: true,
          criadoEm: true,
          reads: {
            where: { userId: actor.id },
            select: { id: true },
          },
        },
      },
    },
  });

  const data = channels.map((c) => {
    const lastMsg = c.messages[0];
    return {
      id: c.id,
      nome: c.nome,
      descricao: c.descricao,
      tipo: c.tipo,
      setorId: c.setorId,
      setor: c.setor,
      criador: c.criador,
      _count: c._count,
      ultimaMensagem: lastMsg?.texto ?? null,
      ultimaMensagemHora: lastMsg?.criadoEm ?? null,
      naoLidas: lastMsg && lastMsg.reads.length === 0 ? 1 : 0,
    };
  });

  res.json({ success: true, data });
}

// ─── Listar todos os canais públicos (para Direção/Coord) ────────────────────
export async function listAllChannels(req: Request, res: Response): Promise<void> {
  const actor = req.user!;

  const where =
    actor.hierarquiaNivel === HierarquiaNivel.DIRECAO
      ? { ativo: true }
      : { ativo: true, OR: [{ setorId: actor.setorId }, { setorId: null }] };

  const channels = await prisma.channel.findMany({
    where,
    orderBy: [{ tipo: 'asc' }, { nome: 'asc' }],
    include: {
      setor: { select: { id: true, nome: true } },
      _count: { select: { members: true } },
      messages: {
        take: 1,
        orderBy: { criadoEm: 'desc' },
        select: {
          id: true,
          texto: true,
          criadoEm: true,
          reads: {
            where: { userId: actor.id },
            select: { id: true },
          },
        },
      },
    },
  });

  const data = channels.map((c) => {
    const lastMsg = c.messages[0];
    return {
      id: c.id,
      nome: c.nome,
      descricao: c.descricao,
      tipo: c.tipo,
      setorId: c.setorId,
      setor: c.setor,
      _count: c._count,
      ultimaMensagem: lastMsg?.texto ?? null,
      ultimaMensagemHora: lastMsg?.criadoEm ?? null,
      naoLidas: lastMsg && lastMsg.reads.length === 0 ? 1 : 0,
    };
  });

  res.json({ success: true, data });
}

// ─── Criar canal ─────────────────────────────────────────────────────────────
export async function createChannel(req: Request, res: Response): Promise<void> {
  const actor = req.user!;

  // Coordenação pode criar somente canais do seu setor
  // Direção pode criar qualquer tipo
  if (actor.hierarquiaNivel > HierarquiaNivel.COORDENACAO) {
    throw new AppError('Apenas Coordenação e Direção podem criar canais.', 403);
  }

  const data = createChannelSchema.parse(req.body);

  // Coordenação só pode criar canal institucional se for do seu setor
  if (
    actor.hierarquiaNivel === HierarquiaNivel.COORDENACAO &&
    data.tipo === 'institucional'
  ) {
    throw new AppError('Coordenação não pode criar canais institucionais gerais.', 403);
  }

  // Validar setor se informado
  if (data.setorId) {
    const setor = await prisma.sector.findUnique({ where: { id: data.setorId } });
    if (!setor) throw new AppError('Setor não encontrado.', 404);
    // Coordenação só pode criar canal do próprio setor
    if (
      actor.hierarquiaNivel === HierarquiaNivel.COORDENACAO &&
      data.setorId !== actor.setorId
    ) {
      throw new AppError('Coordenação só pode criar canais do próprio setor.', 403);
    }
  }

  const channel = await prisma.channel.create({
    data: {
      nome: data.nome,
      descricao: data.descricao,
      tipo: data.tipo,
      setorId: data.setorId ?? null,
      criadoPor: actor.id,
      ativo: true,
      members: {
        create: [{ userId: actor.id }], // criador é membro automaticamente
      },
    },
    include: {
      setor: { select: { id: true, nome: true } },
      _count: { select: { members: true } },
    },
  });

  await auditLog({
    userId: actor.id,
    acao: 'criar_canal',
    entidade: 'channel',
    entidadeId: channel.id,
    req,
  });

  res.status(201).json({ success: true, data: channel });
}

// ─── Adicionar membro ao canal ────────────────────────────────────────────────
export async function addMember(req: Request, res: Response): Promise<void> {
  const actor = req.user!;
  const { id: channelId } = req.params;
  const { userId } = addMemberSchema.parse(req.body);

  const channel = await prisma.channel.findUnique({
    where: { id: channelId },
    include: { members: { where: { userId: actor.id } } },
  });

  if (!channel) throw new AppError('Canal não encontrado.', 404);

  // Somente admin ou criador pode adicionar membros
  const isCreator = channel.criadoPor === actor.id;
  const isAdmin = actor.hierarquiaNivel <= HierarquiaNivel.COORDENACAO;

  if (!isCreator && !isAdmin) {
    throw new AppError('Sem permissão para adicionar membros.', 403);
  }

  // Verificar se usuário existe e está ativo
  const targetUser = await prisma.user.findUnique({ where: { id: userId } });
  if (!targetUser || !targetUser.ativo) {
    throw new AppError('Usuário não encontrado ou inativo.', 404);
  }

  // Coordenação só pode adicionar usuários do mesmo setor
  if (
    actor.hierarquiaNivel === HierarquiaNivel.COORDENACAO &&
    targetUser.setorId !== actor.setorId
  ) {
    throw new AppError('Coordenação só pode adicionar membros do próprio setor.', 403);
  }

  await prisma.channelMember.upsert({
    where: { channelId_userId: { channelId, userId } },
    create: { channelId, userId },
    update: {},
  });

  res.json({ success: true, message: 'Membro adicionado.' });
}

// ─── Remover membro do canal ──────────────────────────────────────────────────
export async function removeMember(req: Request, res: Response): Promise<void> {
  const actor = req.user!;
  const { id: channelId, userId } = req.params;

  const channel = await prisma.channel.findUnique({ where: { id: channelId } });
  if (!channel) throw new AppError('Canal não encontrado.', 404);

  const isCreator = channel.criadoPor === actor.id;
  const isAdmin = actor.hierarquiaNivel <= HierarquiaNivel.COORDENACAO;
  const isSelf = userId === actor.id;

  if (!isCreator && !isAdmin && !isSelf) {
    throw new AppError('Sem permissão para remover este membro.', 403);
  }

  await prisma.channelMember.deleteMany({
    where: { channelId, userId },
  });

  res.json({ success: true, message: 'Membro removido.' });
}

// ─── Detalhes do canal ────────────────────────────────────────────────────────
export async function getChannel(req: Request, res: Response): Promise<void> {
  const actor = req.user!;
  const { id } = req.params;

  const channel = await prisma.channel.findUnique({
    where: { id },
    include: {
      setor: { select: { id: true, nome: true } },
      criador: { select: { nome: true } },
      members: {
        include: {
          user: { select: { id: true, nome: true, cargo: true, fotoUrl: true } },
        },
      },
    },
  });

  if (!channel) throw new AppError('Canal não encontrado.', 404);

  // Verificar se o usuário é membro
  const isMember = channel.members.some((m) => m.userId === actor.id);
  const isAdmin = actor.hierarquiaNivel <= HierarquiaNivel.COORDENACAO;

  if (!isMember && !isAdmin) {
    throw new AppError('Você não tem acesso a este canal.', 403);
  }

  res.json({ success: true, data: channel });
}

// ─── Listar mensagens do canal (com confirmação automática de leitura) ─────────
export async function listChannelMessages(req: Request, res: Response): Promise<void> {
  const actor = req.user!;
  const { id: channelId } = req.params;

  // Verificar canal
  const channel = await prisma.channel.findUnique({
    where: { id: channelId },
    include: {
      members: { where: { userId: actor.id } },
    },
  });

  if (!channel || !channel.ativo) {
    throw new AppError('Canal não encontrado.', 404);
  }

  // Se o usuário não estiver em channel_members, mas for do setor ou canal for geral/emergência, adiciona automaticamente
  const isMember = channel.members.length > 0;
  if (!isMember) {
    const isGlobal = channel.tipo === 'institucional' || channel.tipo === 'emergencia' || channel.tipo === 'geral';
    const isSameSector = channel.setorId === actor.setorId;
    const isDirecao = actor.hierarquiaNivel === HierarquiaNivel.DIRECAO;

    if (isGlobal || isSameSector || isDirecao) {
      await prisma.channelMember.upsert({
        where: { channelId_userId: { channelId, userId: actor.id } },
        create: { channelId, userId: actor.id },
        update: {},
      });
    } else {
      throw new AppError('Você não tem acesso a este canal.', 403);
    }
  }

  // Buscar mensagens ordenadas cronologicamente
  const messages = await prisma.channelMessage.findMany({
    where: { channelId },
    orderBy: { criadoEm: 'asc' },
    include: {
      remetente: {
        select: {
          id: true,
          nome: true,
          cargo: true,
          fotoUrl: true,
          hierarquiaNivel: true,
        },
      },
      _count: { select: { reads: true } },
      reads: {
        where: { userId: actor.id },
        select: { id: true, lidoEm: true },
      },
    },
  });

  // Marcar como lidas todas as mensagens não lidas pelo usuário atual
  const unreadMessageIds = messages
    .filter((m) => m.reads.length === 0)
    .map((m) => m.id);

  if (unreadMessageIds.length > 0) {
    await prisma.channelMessageRead.createMany({
      data: unreadMessageIds.map((messageId) => ({
        channelMessageId: messageId,
        userId: actor.id,
      })),
      skipDuplicates: true,
    });
  }

  const mapped = messages.map((m) => ({
    id: m.id,
    channelId: m.channelId,
    remetenteId: m.remetenteId,
    remetenteNome: m.remetente.nome,
    remetenteCargo: m.remetente.cargo,
    remetenteFotoUrl: m.remetente.fotoUrl,
    remetenteHierarquia: m.remetente.hierarquiaNivel,
    texto: m.texto,
    criadoEm: m.criadoEm,
    readsCount: m._count.reads + (unreadMessageIds.includes(m.id) ? 1 : 0),
    lidoPorMim: true,
  }));

  res.json({ success: true, data: mapped });
}

// ─── Publicar mensagem no canal (Apenas Direção e Coordenação) ────────────────
export async function postChannelMessage(req: Request, res: Response): Promise<void> {
  const actor = req.user!;
  const { id: channelId } = req.params;

  // Validação estrita de hierarquia: apenas Direção (1) e Coordenação (2)
  if (actor.hierarquiaNivel > HierarquiaNivel.COORDENACAO) {
    throw new AppError(
      'Apenas Coordenação e Direção podem publicar em canais oficiais.',
      403
    );
  }

  const channel = await prisma.channel.findUnique({
    where: { id: channelId },
  });

  if (!channel || !channel.ativo) {
    throw new AppError('Canal não encontrado.', 404);
  }

  // Se for Coordenação, valida se o canal é do setor dele ou geral
  if (
    actor.hierarquiaNivel === HierarquiaNivel.COORDENACAO &&
    channel.setorId &&
    channel.setorId !== actor.setorId
  ) {
    throw new AppError(
      'Coordenação só pode publicar em canais do próprio setor.',
      403
    );
  }

  const data = postMessageSchema.parse(req.body);

  const message = await prisma.channelMessage.create({
    data: {
      channelId,
      remetenteId: actor.id,
      texto: data.texto,
    },
    include: {
      remetente: {
        select: {
          id: true,
          nome: true,
          cargo: true,
          fotoUrl: true,
          hierarquiaNivel: true,
        },
      },
      _count: { select: { reads: true } },
    },
  });

  // Marca como lida pelo próprio autor
  await prisma.channelMessageRead.upsert({
    where: {
      channelMessageId_userId: {
        channelMessageId: message.id,
        userId: actor.id,
      },
    },
    create: {
      channelMessageId: message.id,
      userId: actor.id,
    },
    update: {},
  });

  await auditLog({
    userId: actor.id,
    acao: 'publicar_canal',
    entidade: 'channel_message',
    entidadeId: message.id,
    req,
  });

  // Disparar Web Push Notification para membros do canal
  try {
    const channelMembers = await prisma.channelMember.findMany({
      where: {
        channelId,
        userId: { not: actor.id },
      },
      include: {
        user: {
          select: { id: true, fcmToken: true },
        },
      },
    });

    const targetTokens = channelMembers
      .map((m) => m.user.fcmToken)
      .filter((t): t is string => Boolean(t && t.trim().length > 0));

    if (targetTokens.length > 0) {
      const messaging = getFirebaseMessaging();
      const channelTitle = `${channel.nome} • ${actor.nome}`;
      const previewText = data.texto.length > 100 ? `${data.texto.substring(0, 97)}...` : data.texto;

      await messaging.sendEachForMulticast({
        tokens: targetTokens,
        notification: {
          title: channelTitle,
          body: previewText,
        },
        data: {
          type: 'channel_message',
          channelId,
          senderId: actor.id,
          senderName: actor.nome,
        },
        webpush: {
          fcmOptions: {
            link: `https://conecta-hospital.web.app/#/channels/${channelId}`,
          },
          notification: {
            title: channelTitle,
            body: previewText,
            icon: 'https://conecta-hospital.web.app/icons/Icon-192.png',
            badge: 'https://conecta-hospital.web.app/icons/Icon-192.png',
            tag: `channel_${channelId}`,
            renotify: true,
          },
        },
      });
      console.log(`[FCM Push] Canal push enviado para ${targetTokens.length} dispositivo(s).`);
    }
  } catch (pushErr) {
    console.warn('[FCM Push] Falha ao enviar notificação push de canal:', pushErr);
  }

  res.status(201).json({
    success: true,
    data: {
      id: message.id,
      channelId: message.channelId,
      remetenteId: message.remetenteId,
      remetenteNome: message.remetente.nome,
      remetenteCargo: message.remetente.cargo,
      remetenteFotoUrl: message.remetente.fotoUrl,
      remetenteHierarquia: message.remetente.hierarquiaNivel,
      texto: message.texto,
      criadoEm: message.criadoEm,
      readsCount: 1,
      lidoPorMim: true,
    },
  });
}

// ─── Rastreamento de visualizações (Quem visualizou) ───────────────────────────
export async function getMessageReaders(req: Request, res: Response): Promise<void> {
  const actor = req.user!;
  const { id: channelId, messageId } = req.params;

  // Apenas Coordenação e Direção podem auditar leituras
  if (actor.hierarquiaNivel > HierarquiaNivel.COORDENACAO) {
    throw new AppError(
      'Apenas Coordenação e Direção têm permissão para ver quem visualizou.',
      403
    );
  }

  const message = await prisma.channelMessage.findFirst({
    where: { id: messageId, channelId },
  });

  if (!message) {
    throw new AppError('Mensagem do canal não encontrada.', 404);
  }

  // Total de membros do canal
  const totalMembers = await prisma.channelMember.count({
    where: { channelId },
  });

  // Lista de quem leu
  const reads = await prisma.channelMessageRead.findMany({
    where: { channelMessageId: messageId },
    orderBy: { lidoEm: 'desc' },
    include: {
      user: {
        select: {
          id: true,
          nome: true,
          cargo: true,
          fotoUrl: true,
          hierarquiaNivel: true,
          setor: { select: { nome: true } },
        },
      },
    },
  });

  const readers = reads.map((r) => ({
    userId: r.user.id,
    nome: r.user.nome,
    cargo: r.user.cargo,
    setorNome: r.user.setor.nome,
    fotoUrl: r.user.fotoUrl,
    hierarquiaNivel: r.user.hierarquiaNivel,
    lidoEm: r.lidoEm,
  }));

  const totalReads = readers.length;
  const percentual = totalMembers > 0 ? Math.round((totalReads / totalMembers) * 100) : 100;

  res.json({
    success: true,
    data: {
      messageId,
      totalMembers,
      totalReads,
      percentual,
      readers,
    },
  });
}
