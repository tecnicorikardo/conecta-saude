import { Request, Response } from 'express';
import { z } from 'zod';
import { prisma } from '../../config/database';
import { HierarquiaNivel } from '../../types';
import { AppError } from '../../middleware/errorHandler';
import { auditLog } from '../../utils/auditLogger';

const createChannelSchema = z.object({
  nome: z.string().min(2).max(80),
  descricao: z.string().max(300).optional(),
  tipo: z.enum(['institucional', 'setor', 'emergencia', 'geral']).default('geral'),
  setorId: z.string().uuid().optional(),
});

const addMemberSchema = z.object({
  userId: z.string().uuid(),
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
    },
  });

  res.json({ success: true, data: channels });
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
    },
  });

  res.json({ success: true, data: channels });
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
