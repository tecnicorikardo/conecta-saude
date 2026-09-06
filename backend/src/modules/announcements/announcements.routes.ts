import { Router } from 'express';
import { authenticate, requireHierarquia } from '../../middleware/authenticate';
import { HierarquiaNivel } from '../../types';
import { Request, Response } from 'express';
import { prisma } from '../../config/database';
import { AppError } from '../../middleware/errorHandler';
import { auditLog } from '../../utils/auditLogger';
import { z } from 'zod';

const createAnnouncementSchema = z.object({
  titulo: z.string().min(3).max(120),
  mensagem: z.string().min(10).max(5000),
  prioridade: z.enum(['normal', 'alta', 'urgente']).default('normal'),
});

async function listAnnouncements(req: Request, res: Response): Promise<void> {
  const actor = req.user!;
  const page = Number(req.query.page ?? 1);
  const limit = Number(req.query.limit ?? 20);
  const skip = (page - 1) * limit;

  const [items, total] = await Promise.all([
    prisma.announcement.findMany({
      where: { ativo: true },
      orderBy: { publicadoEm: 'desc' },
      skip,
      take: limit,
      include: {
        criador: { select: { nome: true, cargo: true } },
        reads: { where: { userId: actor.id }, select: { lidoEm: true } },
        _count: { select: { reads: true } },
      },
    }),
    prisma.announcement.count({ where: { ativo: true } }),
  ]);

  const totalUsers = await prisma.user.count({ where: { ativo: true } });

  res.json({
    success: true,
    data: {
      items: items.map((a) => {
        const readsCount = a._count.reads;
        const percentual = totalUsers > 0 ? Math.round((readsCount / totalUsers) * 100) : 0;
        return {
          id: a.id,
          titulo: a.titulo,
          mensagem: a.mensagem,
          prioridade: a.prioridade,
          publicadoEm: a.publicadoEm,
          criador: a.criador,
          lido: a.reads.length > 0,
          lidoEm: a.reads[0]?.lidoEm ?? null,
          totalLeituras: readsCount,
          totalUsuarios: totalUsers,
          percentualLeitura: percentual,
        };
      }),
      total,
      hasMore: skip + items.length < total,
    },
  });
}

async function createAnnouncement(req: Request, res: Response): Promise<void> {
  const actor = req.user!;

  if (actor.hierarquiaNivel > HierarquiaNivel.COORDENACAO) {
    throw new AppError(
      'Apenas Coordenação e Direção podem publicar comunicados oficiais.',
      403
    );
  }

  const data = createAnnouncementSchema.parse(req.body);

  const announcement = await prisma.announcement.create({
    data: {
      titulo: data.titulo,
      mensagem: data.mensagem,
      prioridade: data.prioridade,
      criadoPor: actor.id,
      publicadoEm: new Date(),
      ativo: true,
    },
    include: {
      criador: { select: { nome: true, cargo: true } },
    },
  });

  // Marca automaticamente como lido pelo criador
  await prisma.announcementRead.upsert({
    where: {
      announcementId_userId: {
        announcementId: announcement.id,
        userId: actor.id,
      },
    },
    create: {
      announcementId: announcement.id,
      userId: actor.id,
    },
    update: {},
  });

  await auditLog({
    userId: actor.id,
    acao: 'criar_comunicado',
    entidade: 'announcement',
    entidadeId: announcement.id,
    req,
  });

  const totalUsers = await prisma.user.count({ where: { ativo: true } });

  res.status(201).json({
    success: true,
    data: {
      id: announcement.id,
      titulo: announcement.titulo,
      mensagem: announcement.mensagem,
      prioridade: announcement.prioridade,
      publicadoEm: announcement.publicadoEm,
      criador: announcement.criador,
      lido: true,
      lidoEm: new Date(),
      totalLeituras: 1,
      totalUsuarios: totalUsers,
      percentualLeitura: totalUsers > 0 ? Math.round((1 / totalUsers) * 100) : 100,
    },
  });
}

async function confirmRead(req: Request, res: Response): Promise<void> {
  const actor = req.user!;
  const { id } = req.params;

  const announcement = await prisma.announcement.findUnique({ where: { id } });
  if (!announcement) throw new AppError('Comunicado não encontrado.', 404);

  const readRecord = await prisma.announcementRead.upsert({
    where: { announcementId_userId: { announcementId: id, userId: actor.id } },
    create: { announcementId: id, userId: actor.id },
    update: { lidoEm: new Date() },
  });

  await auditLog({
    userId: actor.id,
    acao: 'confirmar_leitura_comunicado',
    entidade: 'announcement',
    entidadeId: id,
    req,
  });

  res.json({
    success: true,
    message: 'Leitura institucional confirmada com sucesso.',
    data: {
      lidoEm: readRecord.lidoEm,
    },
  });
}

async function getAnnouncementStats(req: Request, res: Response): Promise<void> {
  const actor = req.user!;
  const { id } = req.params;

  // Apenas Gestores (Coordenação e Direção)
  if (actor.hierarquiaNivel > HierarquiaNivel.COORDENACAO) {
    throw new AppError(
      'Apenas Coordenação e Direção têm permissão para ver estatísticas de leitura.',
      403
    );
  }

  const announcement = await prisma.announcement.findUnique({ where: { id } });
  if (!announcement) throw new AppError('Comunicado não encontrado.', 404);

  // Buscar todos os usuários ativos
  const allUsers = await prisma.user.findMany({
    where: { ativo: true },
    select: {
      id: true,
      nome: true,
      cargo: true,
      fotoUrl: true,
      hierarquiaNivel: true,
      setor: { select: { nome: true } },
    },
    orderBy: { nome: 'asc' },
  });

  // Buscar todas as leituras
  const reads = await prisma.announcementRead.findMany({
    where: { announcementId: id },
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

  const readUserIds = new Set(reads.map((r) => r.userId));

  const readers = reads.map((r) => ({
    userId: r.user.id,
    nome: r.user.nome,
    cargo: r.user.cargo,
    setorNome: r.user.setor.nome,
    fotoUrl: r.user.fotoUrl,
    hierarquiaNivel: r.user.hierarquiaNivel,
    lidoEm: r.lidoEm,
  }));

  const pending = allUsers
    .filter((u) => !readUserIds.has(u.id))
    .map((u) => ({
      userId: u.id,
      nome: u.nome,
      cargo: u.cargo,
      setorNome: u.setor.nome,
      fotoUrl: u.fotoUrl,
      hierarquiaNivel: u.hierarquiaNivel,
    }));

  const totalUsers = allUsers.length;
  const totalReads = readers.length;
  const percentual = totalUsers > 0 ? Math.round((totalReads / totalUsers) * 100) : 0;

  res.json({
    success: true,
    data: {
      announcementId: id,
      totalUsers,
      totalReads,
      percentual,
      readers,
      pending,
    },
  });
}

const router = Router();
router.use(authenticate);

router.get('/', asyncHandler(listAnnouncements));
router.post(
  '/',
  requireHierarquia(HierarquiaNivel.COORDENACAO),
  asyncHandler(createAnnouncement)
);
router.post('/:id/read', asyncHandler(confirmRead));
router.get(
  '/:id/stats',
  requireHierarquia(HierarquiaNivel.COORDENACAO),
  asyncHandler(getAnnouncementStats)
);

function asyncHandler(fn: (req: Request, res: Response) => Promise<void>) {
  return (req: Request, res: Response, next: (err?: unknown) => void) => {
    Promise.resolve(fn(req, res)).catch(next);
  };
}

export default router;
