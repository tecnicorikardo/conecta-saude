import { Router } from 'express';
import { Request, Response } from 'express';
import { authenticate, requireHierarquia } from '../../middleware/authenticate';
import { prisma } from '../../config/database';
import { HierarquiaNivel } from '../../types';

async function listAuditLogs(req: Request, res: Response): Promise<void> {
  const page = Number(req.query.page ?? 1);
  const limit = Math.min(Number(req.query.limit ?? 30), 100);
  const skip = (page - 1) * limit;
  const userId = req.query.userId as string | undefined;
  const acao = req.query.acao as string | undefined;

  const where = {
    ...(userId && { userId }),
    ...(acao && { acao: { contains: acao } }),
  };

  const [logs, total] = await Promise.all([
    prisma.auditLog.findMany({
      where,
      orderBy: { criadoEm: 'desc' },
      skip,
      take: limit,
      include: {
        user: { select: { nome: true, cargo: true } },
      },
    }),
    prisma.auditLog.count({ where }),
  ]);

  res.json({
    success: true,
    data: {
      items: logs.map((l) => ({
        id: l.id,
        acao: l.acao,
        entidade: l.entidade,
        entidadeId: l.entidadeId,
        user: l.user,
        ip: l.ip,
        criadoEm: l.criadoEm,
      })),
      total,
      hasMore: skip + logs.length < total,
    },
  });
}

function asyncHandler(fn: (req: Request, res: Response) => Promise<void>) {
  return (req: Request, res: Response, next: (err?: unknown) => void) => {
    Promise.resolve(fn(req, res)).catch(next);
  };
}

const router = Router();
router.use(authenticate);
router.get('/', requireHierarquia(HierarquiaNivel.DIRECAO), asyncHandler(listAuditLogs));

export default router;
