import { Request, Response } from 'express';
import { prisma } from '../../config/database';
import { HierarquiaNivel, ConversationTipo } from '../../types';
import { AppError } from '../../middleware/errorHandler';
import { listMessages, sendMessage } from '../messages/messages.controller';
import { z } from 'zod';

const createConversationSchema = z.object({
  tipo: z.nativeEnum(ConversationTipo),
  nome: z.string().max(80).optional(),
  participantIds: z.array(z.string().uuid()).min(1).max(50),
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
      members: c.members.map((m) => ({
        id: m.user.id,
        nome: m.user.nome,
        fotoUrl: m.user.fotoUrl,
        cargo: m.user.cargo,
        hierarquiaNivel: m.user.hierarquiaNivel,
        setorNome: m.user.setor?.nome ?? '',
      })),
      lastMessage: c.messages[0] ?? null,
      unreadCount: c._count.messages,
      atualizadoEm: c.atualizadoEm,
    })),
  });
}

/**
 * POST /api/conversations
 * Cria uma conversa. Valida regras de hierarquia e setor no backend.
 */
export async function createConversation(req: Request, res: Response): Promise<void> {
  const actor = req.user!;
  const data = createConversationSchema.parse(req.body);

  // Filtrar o próprio criador dos participantes e remover duplicatas
  const uniqueParticipantIds = Array.from(
    new Set(data.participantIds.filter((id) => id !== actor.id))
  );

  if (uniqueParticipantIds.length === 0) {
    throw new AppError('Selecione ao menos um participante diferente de você.', 400);
  }

  // Buscar dados dos participantes para validação
  const participants = await prisma.user.findMany({
    where: { id: { in: uniqueParticipantIds }, ativo: true },
    select: { id: true, hierarquiaNivel: true, setorId: true, nome: true },
  });

  if (participants.length !== uniqueParticipantIds.length) {
    throw new AppError('Um ou mais participantes não foram encontrados ou estão inativos.', 400);
  }

  // Validar regras de comunicação para conversa individual ou grupo
  if (data.tipo === ConversationTipo.INDIVIDUAL) {
    if (participants.length !== 1) {
      throw new AppError('Conversa individual deve ter exatamente 1 participante.', 400);
    }

    const target = participants[0];
    if (target.id === actor.id) {
      throw new AppError('Não é possível criar uma conversa individual consigo mesmo.', 400);
    }

    _validateCommunicationRules(actor, target);

    // Verificar se já existe conversa individual entre esses dois
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
          members: existing.members.map((m) => ({
            id: m.user.id,
            nome: m.user.nome,
            fotoUrl: m.user.fotoUrl,
            cargo: m.user.cargo,
            hierarquiaNivel: m.user.hierarquiaNivel,
            setorNome: m.user.setor?.nome ?? '',
          })),
          lastMessage: null,
          unreadCount: 0,
          atualizadoEm: existing.atualizadoEm,
        },
      });
      return;
    }
  } else {
    // Validar regras de comunicação para todos os membros do grupo
    for (const participant of participants) {
      _validateCommunicationRules(actor, participant);
    }
  }

  // Criar conversa
  const conversation = await prisma.conversation.create({
    data: {
      tipo: data.tipo,
      nome: data.nome ?? null,
      criadoPor: actor.id,
      setorId: actor.setorId,
      ativo: true,
      members: {
        create: [
          { userId: actor.id },
          ...participants.map((p) => ({ userId: p.id })),
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
      members: conversation.members.map((m) => ({
        id: m.user.id,
        nome: m.user.nome,
        fotoUrl: m.user.fotoUrl,
        cargo: m.user.cargo,
        hierarquiaNivel: m.user.hierarquiaNivel,
        setorNome: m.user.setor?.nome ?? '',
      })),
      lastMessage: null,
      unreadCount: 0,
      atualizadoEm: conversation.atualizadoEm,
    },
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
