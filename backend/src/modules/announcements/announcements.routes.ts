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
      },
    }),
    prisma.announcement.count({ where: { ativo: true } }),
  ]);

  res.json({
    success: true,
    data: {
      items: items.map((a) => ({
        id: a.id,
        titulo: a.titulo,
        mensagem: a.mensagem,
        prioridade: a.prioridade,
        publicadoEm: a.publicadoEm,
        criador: a.criador,
        lido: a.reads.length > 0,
      })),
      total,
      hasMore: skip + items.length < total,
    },
  });
}

async function createAnnouncement(req: Request, res: Response): Promise<void> {
  const actor = req.user!;
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
  });

  await auditLog({
    userId: actor.id,
    acao: 'criar_comunicado',
    entidade: 'announcement',
    entidadeId: announcement.id,
    req,
  });

  res.status(201).json({ success: true, data: announcement });
}

async function confirmRead(req: Request, res: Response): Promise<void> {
  const actor = req.user!;
  const { id } = req.params;

  const announcement = await prisma.announcement.findUnique({ where: { id } });
  if (!announcement) throw new AppError('Comunicado não encontrado.', 404);

  await prisma.announcementRead.upsert({
    where: { announcementId_userId: { announcementId: id, userId: actor.id } },
    create: { announcementId: id, userId: actor.id },
    update: {},
  });

  res.json({ success: true, message: 'Leitura confirmada.' });
}

async function getAnnouncementStats(req: Request, res: Response): Promise<void> {
  const { id } = req.params;

  const [announcement, totalUsers, reads] = await Promise.all([
    prisma.announcement.findUnique({ where: { id } }),
    prisma.user.count({ where: { ativo: true } }),
    prisma.announcementRead.count({ where: { announcementId: id } }),
  ]);

  if (!announcement) throw new AppError('Comunicado não encontrado.', 404);

  res.json({
    success: true,
    data: {
      totalUsers,
      totalReads: reads,
      percentual: totalUsers > 0 ? Math.round((reads / totalUsers) * 100) : 0,
    },
  });
}

const router = Router();
router.use(authenticate);

router.get('/', asyncHandler(listAnnouncements));
router.post('/', requireHierarquia(HierarquiaNivel.COORDENACAO), asyncHandler(createAnnouncement));
router.post('/:id/read', asyncHandler(confirmRead));
router.get('/:id/stats', requireHierarquia(HierarquiaNivel.COORDENACAO), asyncHandler(getAnnouncementStats));

function asyncHandler(fn: (req: Request, res: Response) => Promise<void>) {
  return (req: Request, res: Response, next: (err?: unknown) => void) => {
    Promise.resolve(fn(req, res)).catch(next);
  };
}

export default router;
