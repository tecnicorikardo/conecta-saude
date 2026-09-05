import { Router } from 'express';
import { Request, Response } from 'express';
import { authenticate, requireHierarquia } from '../../middleware/authenticate';
import { prisma } from '../../config/database';
import { AppError } from '../../middleware/errorHandler';
import { HierarquiaNivel } from '../../types';
import { z } from 'zod';

const createReportSchema = z.object({
  reportedUserId: z.string().uuid().optional(),
  messageId: z.string().uuid().optional(),
  motivo: z.enum(['assedio', 'ofensa', 'conteudo_inadequado', 'comunicacao_impropria', 'outro']),
  descricao: z.string().max(1000).optional(),
});

const updateReportSchema = z.object({
  status: z.enum(['em_analise', 'resolvido', 'arquivado']),
});

async function createReport(req: Request, res: Response): Promise<void> {
  const actor = req.user!;
  const data = createReportSchema.parse(req.body);

  if (!data.reportedUserId && !data.messageId) {
    throw new AppError('Informe o usuário ou a mensagem denunciada.', 400);
  }

  const report = await prisma.report.create({
    data: {
      reporterId: actor.id,
      reportedUserId: data.reportedUserId ?? null,
      messageId: data.messageId ?? null,
      motivo: data.motivo,
      descricao: data.descricao ?? null,
      status: 'pendente',
    },
  });

  res.status(201).json({ success: true, message: 'Denúncia registrada. Será analisada pela administração.', data: { id: report.id } });
}

async function listReports(req: Request, res: Response): Promise<void> {
  const status = req.query.status as string | undefined;

  const reports = await prisma.report.findMany({
    where: status ? { status } : undefined,
    orderBy: { criadoEm: 'desc' },
    include: {
      reporter: { select: { nome: true } },
      reportedUser: { select: { nome: true } },
    },
  });

  res.json({ success: true, data: reports });
}

async function updateReportStatus(req: Request, res: Response): Promise<void> {
  const { id } = req.params;
  const { status } = updateReportSchema.parse(req.body);

  const report = await prisma.report.findUnique({ where: { id } });
  if (!report) throw new AppError('Denúncia não encontrada.', 404);

  await prisma.report.update({ where: { id }, data: { status, atualizadoEm: new Date() } });

  res.json({ success: true, message: 'Status da denúncia atualizado.' });
}

function asyncHandler(fn: (req: Request, res: Response) => Promise<void>) {
  return (req: Request, res: Response, next: (err?: unknown) => void) => {
    Promise.resolve(fn(req, res)).catch(next);
  };
}

const router = Router();
router.use(authenticate);

router.post('/', asyncHandler(createReport));
router.get('/', requireHierarquia(HierarquiaNivel.COORDENACAO), asyncHandler(listReports));
router.patch('/:id/status', requireHierarquia(HierarquiaNivel.COORDENACAO), asyncHandler(updateReportStatus));

export default router;
