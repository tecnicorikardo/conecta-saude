import { Request, Response } from 'express';
import { prisma } from '../../config/database';
import { HierarquiaNivel, ConversationTipo } from '../../types';
import { AppError } from '../../middleware/errorHandler';
import { listMessages, sendMessage } from '../messages/messages.controller';
import { z } from 'zod';

const createConversationSchema = z.object({
  tipo: z.nativeEnum(ConversationTipo),
  nome: z.string().max(80).optional(),
  descricao: z.string().max(500).optional().nullable(),
  fotoUrl: z.string().optional().nullable(),
  participantIds: z.array(z.string().uuid()).min(1).max(50),
});

const updateConversationSchema = z.object({
  nome: z.string().min(1).max(80).optional(),
  descricao: z.string().max(500).optional().nullable(),
  fotoUrl: z.string().optional().nullable(),
});

const addMembersSchema = z.object({
  userIds: z.array(z.string().uuid()).min(1).max(50),
});

const updateMemberRoleSchema = z.object({
  isAdmin: z.boolean(),
});

/**
 * GET /api/conversations
 * Lista conversas do usuário autenticado.
 */
export async function listConversations(req: Request, res: Response): Promise<void> {
  const actor = req.user!;

  const conversations = await prisma.conversation.findMany({
    where: {
      ativo: true,
      members: { some: { userId: actor.id } },
    },
    orderBy: [
      { atualizadoEm: 'desc' },
      { id: 'desc' },
    ],
    include: {
      members: {
        include: {
          user: {
            select: {
              id: true,
              nome: true,
              fotoUrl: true,
              cargo: true,
              hierarquiaNivel: true,
              setor: { select: { nome: true } },
            },
          },
        },
      },
      messages: {
        orderBy: { criadoEm: 'desc' },
        take: 1,
        select: {
          id: true,
          texto: true,
          excluido: true,
          criadoEm: true,
          remetente: { select: { id: true, nome: true, cargo: true } },
        },
      },
      _count: {
        select: {
          messages: {
            where: {
              excluido: false,
              remetenteId: { not: actor.id },
              reads: { none: { userId: actor.id } },
            },
          },
        },
      },
    },
  });

  res.json({
    success: true,
    data: conversations.map((c) => ({
      id: c.id,
      tipo: c.tipo,
      nome: c.nome,
      descricao: c.descricao,
      fotoUrl: c.fotoUrl,
      criadoPor: c.criadoPor,
      members: c.members.map((m) => ({
        id: m.user.id,
        nome: m.user.nome,
        fotoUrl: m.user.fotoUrl,
        cargo: m.user.cargo,
        hierarquiaNivel: m.user.hierarquiaNivel,
        setorNome: m.user.setor?.nome ?? '',
        isAdmin: m.isAdmin || m.user.id === c.criadoPor,
      })),
      lastMessage: c.messages[0] ?? null,
      unreadCount: c._count.messages,
      atualizadoEm: c.atualizadoEm,
    })),
  });
}

/**
 * GET /api/conversations/:id
 * Retorna os detalhes de uma conversa ou grupo com participantes e permissões.
 */
export async function getConversation(req: Request, res: Response): Promise<void> {
  const actor = req.user!;
  const { id } = req.params;

  const conversation = await prisma.conversation.findFirst({
    where: {
      id,
      ativo: true,
      ...(actor.hierarquiaNivel !== HierarquiaNivel.DIRECAO
        ? { members: { some: { userId: actor.id } } }
        : {}),
    },
    include: {
      members: {
        include: {
          user: {
            select: {
              id: true,
              nome: true,
              fotoUrl: true,
              cargo: true,
              hierarquiaNivel: true,
              setor: { select: { nome: true } },
            },
          },
        },
      },
    },
  });

  if (!conversation) {
    throw new AppError('Conversa ou grupo não encontrado ou acesso negado.', 404);
  }

  const currentMember = conversation.members.find((m) => m.userId === actor.id);
  const isActorAdmin =
    actor.hierarquiaNivel === HierarquiaNivel.DIRECAO ||
    conversation.criadoPor === actor.id ||
    currentMember?.isAdmin === true;

  res.json({
    success: true,
    data: {
      id: conversation.id,
      tipo: conversation.tipo,
      nome: conversation.nome,
      descricao: conversation.descricao,
      fotoUrl: conversation.fotoUrl,
      criadoPor: conversation.criadoPor,
      setorId: conversation.setorId,
      atualizadoEm: conversation.atualizadoEm,
      currentUserIsAdmin: isActorAdmin,
      members: conversation.members.map((m) => ({
        id: m.user.id,
        nome: m.user.nome,
        fotoUrl: m.user.fotoUrl,
        cargo: m.user.cargo,
        hierarquiaNivel: m.user.hierarquiaNivel,
        setorNome: m.user.setor?.nome ?? '',
        isAdmin: m.isAdmin || m.user.id === conversation.criadoPor,
        isCreator: m.user.id === conversation.criadoPor,
      })),
    },
  });
}

/**
 * POST /api/conversations
 * Cria uma conversa ou grupo. Valida regras de hierarquia e setor no backend.
 */
export async function createConversation(req: Request, res: Response): Promise<void> {
  const actor = req.user!;
  const data = createConversationSchema.parse(req.body);

  const uniqueParticipantIds = Array.from(
    new Set(data.participantIds.filter((id) => id !== actor.id))
  );

  if (uniqueParticipantIds.length === 0) {
    throw new AppError('Selecione ao menos um participante diferente de você.', 400);
  }

  const participants = await prisma.user.findMany({
    where: { id: { in: uniqueParticipantIds }, ativo: true },
    select: { id: true, hierarquiaNivel: true, setorId: true, nome: true },
  });

  if (participants.length !== uniqueParticipantIds.length) {
    throw new AppError('Um ou mais participantes não foram encontrados ou estão inativos.', 400);
  }

  if (data.tipo === ConversationTipo.INDIVIDUAL) {
    if (participants.length !== 1) {
      throw new AppError('Conversa individual deve ter exatamente 1 participante.', 400);
    }

    const target = participants[0];
    if (target.id === actor.id) {
      throw new AppError('Não é possível criar uma conversa individual consigo mesmo.', 400);
    }

    _validateCommunicationRules(actor, target);

    const existing = await prisma.conversation.findFirst({
      where: {
        tipo: ConversationTipo.INDIVIDUAL,
        ativo: true,
        AND: [
          { members: { some: { userId: actor.id } } },
          { members: { some: { userId: target.id } } },
        ],
      },
      include: {
        members: {
          include: {
            user: {
              select: {
                id: true,
                nome: true,
                fotoUrl: true,
                cargo: true,
                hierarquiaNivel: true,
                setor: { select: { nome: true } },
              },
            },
          },
        },
      },
    });

    if (existing) {
      res.json({
        success: true,
        data: {
          id: existing.id,
          tipo: existing.tipo,
          nome: existing.nome,
          descricao: existing.descricao,
          fotoUrl: existing.fotoUrl,
          criadoPor: existing.criadoPor,
          members: existing.members.map((m) => ({
            id: m.user.id,
            nome: m.user.nome,
            fotoUrl: m.user.fotoUrl,
            cargo: m.user.cargo,
            hierarquiaNivel: m.user.hierarquiaNivel,
            setorNome: m.user.setor?.nome ?? '',
            isAdmin: m.isAdmin || m.user.id === existing.criadoPor,
          })),
          lastMessage: null,
          unreadCount: 0,
          atualizadoEm: existing.atualizadoEm,
        },
      });
      return;
    }
  } else {
    for (const participant of participants) {
      _validateCommunicationRules(actor, participant);
    }
  }

  // Criar conversa com o criador sendo Admin por padrão
  const conversation = await prisma.conversation.create({
    data: {
      tipo: data.tipo,
      nome: data.nome ?? null,
      descricao: data.descricao ?? null,
      fotoUrl: data.fotoUrl ?? null,
      criadoPor: actor.id,
      setorId: actor.setorId,
      ativo: true,
      members: {
        create: [
          { userId: actor.id, isAdmin: true },
          ...participants.map((p) => ({ userId: p.id, isAdmin: false })),
        ],
      },
    },
    include: {
      members: {
        include: {
          user: {
            select: {
              id: true,
              nome: true,
              fotoUrl: true,
              cargo: true,
              hierarquiaNivel: true,
              setor: { select: { nome: true } },
            },
          },
        },
      },
    },
  });

  res.status(201).json({
    success: true,
    data: {
      id: conversation.id,
      tipo: conversation.tipo,
      nome: conversation.nome,
      descricao: conversation.descricao,
      fotoUrl: conversation.fotoUrl,
      criadoPor: conversation.criadoPor,
      members: conversation.members.map((m) => ({
        id: m.user.id,
        nome: m.user.nome,
        fotoUrl: m.user.fotoUrl,
        cargo: m.user.cargo,
        hierarquiaNivel: m.user.hierarquiaNivel,
        setorNome: m.user.setor?.nome ?? '',
        isAdmin: m.isAdmin || m.user.id === conversation.criadoPor,
      })),
      lastMessage: null,
      unreadCount: 0,
      atualizadoEm: conversation.atualizadoEm,
    },
  });
}

/**
 * PATCH /api/conversations/:id
 * Atualiza nome, descrição ou foto de um grupo. Apenas Admins do grupo ou Direção Geral.
 */
export async function updateConversation(req: Request, res: Response): Promise<void> {
  const actor = req.user!;
  const { id } = req.params;
  const data = updateConversationSchema.parse(req.body);

  const conversation = await prisma.conversation.findUnique({
    where: { id },
    include: { members: true },
  });

  if (!conversation || !conversation.ativo) {
    throw new AppError('Grupo não encontrado.', 404);
  }

  if (conversation.tipo === ConversationTipo.INDIVIDUAL) {
    throw new AppError('Não é permitido alterar dados de conversas individuais.', 400);
  }

  const member = conversation.members.find((m) => m.userId === actor.id);
  const isAuthorized =
    actor.hierarquiaNivel === HierarquiaNivel.DIRECAO ||
    conversation.criadoPor === actor.id ||
    member?.isAdmin === true;

  if (!isAuthorized) {
    throw new AppError('Apenas administradores do grupo ou a Direção podem alterar os dados.', 403);
  }

  const updated = await prisma.conversation.update({
    where: { id },
    data: {
      ...(data.nome !== undefined ? { nome: data.nome } : {}),
      ...(data.descricao !== undefined ? { descricao: data.descricao } : {}),
      ...(data.fotoUrl !== undefined ? { fotoUrl: data.fotoUrl } : {}),
    },
  });

  res.json({
    success: true,
    data: {
      id: updated.id,
      nome: updated.nome,
      descricao: updated.descricao,
      fotoUrl: updated.fotoUrl,
    },
  });
}

/**
 * POST /api/conversations/:id/members
 * Adiciona novos participantes ao grupo. Apenas Admins do grupo ou Direção Geral.
 */
export async function addMembers(req: Request, res: Response): Promise<void> {
  const actor = req.user!;
  const { id } = req.params;
  const { userIds } = addMembersSchema.parse(req.body);

  const conversation = await prisma.conversation.findUnique({
    where: { id },
    include: { members: true },
  });

  if (!conversation || !conversation.ativo) {
    throw new AppError('Grupo não encontrado.', 404);
  }

  if (conversation.tipo === ConversationTipo.INDIVIDUAL) {
    throw new AppError('Não é possível adicionar participantes a uma conversa individual.', 400);
  }

  const member = conversation.members.find((m) => m.userId === actor.id);
  const isAuthorized =
    actor.hierarquiaNivel === HierarquiaNivel.DIRECAO ||
    conversation.criadoPor === actor.id ||
    member?.isAdmin === true;

  if (!isAuthorized) {
    throw new AppError('Apenas administradores do grupo podem adicionar participantes.', 403);
  }

  const existingMemberIds = new Set(conversation.members.map((m) => m.userId));
  const newMemberIds = Array.from(new Set(userIds)).filter((uid) => !existingMemberIds.has(uid));

  if (newMemberIds.length === 0) {
    throw new AppError('Todos os usuários selecionados já fazem parte deste grupo.', 400);
  }

  const users = await prisma.user.findMany({
    where: { id: { in: newMemberIds }, ativo: true },
    select: { id: true, hierarquiaNivel: true, setorId: true },
  });

  if (users.length !== newMemberIds.length) {
    throw new AppError('Um ou mais usuários não foram encontrados ou estão inativos.', 400);
  }

  for (const u of users) {
    _validateCommunicationRules(actor, u);
  }

  await prisma.conversationMember.createMany({
    data: newMemberIds.map((uid) => ({
      conversationId: id,
      userId: uid,
      isAdmin: false,
    })),
  });

  res.status(201).json({
    success: true,
    message: `${newMemberIds.length} participante(s) adicionado(s) com sucesso.`,
  });
}

/**
 * DELETE /api/conversations/:id/members/:userId
 * Remove um membro do grupo ou permite que o usuário saia voluntariamente.
 */
export async function removeMember(req: Request, res: Response): Promise<void> {
  const actor = req.user!;
  const { id, userId } = req.params;

  const conversation = await prisma.conversation.findUnique({
    where: { id },
    include: { members: true },
  });

  if (!conversation || !conversation.ativo) {
    throw new AppError('Grupo não encontrado.', 404);
  }

  const targetMember = conversation.members.find((m) => m.userId === userId);
  if (!targetMember) {
    throw new AppError('Usuário não é membro deste grupo.', 404);
  }

  const isSelfLeaving = actor.id === userId;
  const actorMember = conversation.members.find((m) => m.userId === actor.id);
  const isActorAdmin =
    actor.hierarquiaNivel === HierarquiaNivel.DIRECAO ||
    conversation.criadoPor === actor.id ||
    actorMember?.isAdmin === true;

  if (!isSelfLeaving && !isActorAdmin) {
    throw new AppError('Apenas administradores do grupo podem remover outros membros.', 403);
  }

  // Não permite remover o criador do grupo se não for o próprio saindo
  if (!isSelfLeaving && userId === conversation.criadoPor) {
    throw new AppError('Não é permitido remover o criador do grupo.', 400);
  }

  await prisma.conversationMember.delete({
    where: {
      conversationId_userId: {
        conversationId: id,
        userId: userId,
      },
    },
  });

  // Se quem saiu era o único admin e restaram membros, promove o membro mais antigo
  if (targetMember.isAdmin) {
    const remainingMembers = await prisma.conversationMember.findMany({
      where: { conversationId: id },
      orderBy: { criadoEm: 'asc' },
    });
    const hasAdmin = remainingMembers.some((m) => m.isAdmin);
    if (!hasAdmin && remainingMembers.length > 0) {
      await prisma.conversationMember.update({
        where: { id: remainingMembers[0].id },
        data: { isAdmin: true },
      });
    }
  }

  res.json({
    success: true,
    message: isSelfLeaving ? 'Você saiu do grupo.' : 'Membro removido com sucesso.',
  });
}

/**
 * PATCH /api/conversations/:id/members/:userId/role
 * Promove ou rebaixa um membro a administrador do grupo.
 */
export async function updateMemberRole(req: Request, res: Response): Promise<void> {
  const actor = req.user!;
  const { id, userId } = req.params;
  const { isAdmin } = updateMemberRoleSchema.parse(req.body);

  const conversation = await prisma.conversation.findUnique({
    where: { id },
    include: { members: true },
  });

  if (!conversation || !conversation.ativo) {
    throw new AppError('Grupo não encontrado.', 404);
  }

  const actorMember = conversation.members.find((m) => m.userId === actor.id);
  const isActorAdmin =
    actor.hierarquiaNivel === HierarquiaNivel.DIRECAO ||
    conversation.criadoPor === actor.id ||
    actorMember?.isAdmin === true;

  if (!isActorAdmin) {
    throw new AppError('Apenas administradores podem alterar permissões no grupo.', 403);
  }

  const targetMember = conversation.members.find((m) => m.userId === userId);
  if (!targetMember) {
    throw new AppError('Usuário não é membro deste grupo.', 404);
  }

  // Criador do grupo é permanentemente admin
  if (userId === conversation.criadoPor && !isAdmin) {
    throw new AppError('O criador do grupo não pode perder o status de administrador.', 400);
  }

  await prisma.conversationMember.update({
    where: {
      conversationId_userId: {
        conversationId: id,
        userId: userId,
      },
    },
    data: { isAdmin },
  });

  res.json({
    success: true,
    message: isAdmin
      ? 'Membro promovido a administrador do grupo.'
      : 'Permissão de administrador revogada.',
  });
}

/**
 * DELETE /api/conversations/:id
 * Exclui / desativa um grupo. Apenas o Criador ou a Direção Geral (Nível 1).
 */
export async function deleteConversation(req: Request, res: Response): Promise<void> {
  const actor = req.user!;
  const { id } = req.params;

  const conversation = await prisma.conversation.findUnique({
    where: { id },
  });

  if (!conversation || !conversation.ativo) {
    throw new AppError('Grupo não encontrado.', 404);
  }

  const isCreatorOrDirecao =
    actor.hierarquiaNivel === HierarquiaNivel.DIRECAO || conversation.criadoPor === actor.id;

  if (!isCreatorOrDirecao) {
    throw new AppError('Apenas o criador do grupo ou a Direção Geral podem excluir o grupo.', 403);
  }

  await prisma.conversation.update({
    where: { id },
    data: { ativo: false },
  });

  res.json({
    success: true,
    message: 'Grupo excluído com sucesso.',
  });
}

/**
 * Valida as regras de comunicação entre centros (CCDTI, CCO, CCE e Direção Geral).
 * Esta lógica fica EXCLUSIVAMENTE no backend.
 */
function _validateCommunicationRules(
  actor: { hierarquiaNivel: HierarquiaNivel; setorId: string },
  target: { hierarquiaNivel: number; setorId: string },
): void {
  const actorNivel = actor.hierarquiaNivel;
  const targetNivel = target.hierarquiaNivel as HierarquiaNivel;

  // 1. Admin Geral / Direção pode conversar com qualquer usuário de qualquer centro
  if (actorNivel === HierarquiaNivel.DIRECAO) return;

  // 2. Qualquer servidor pode se comunicar com a Direção Geral
  if (targetNivel === HierarquiaNivel.DIRECAO) return;

  // 3. Regra estrita de isolamento entre centros:
  // Servidores do CCO, CCE ou CCDTI só podem interagir dentro do seu próprio centro
  if (actor.setorId !== target.setorId) {
    throw new AppError(
      'Comunicação não permitida entre centros distintos. Servidores só podem interagir dentro do seu próprio centro (CCDTI, CCO ou CCE) ou com a Direção Geral.',
      403,
    );
  }
}

// Re-exportar handlers de mensagens para o router de conversations
export { listMessages, sendMessage };
