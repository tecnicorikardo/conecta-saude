import { Router } from 'express';
import { Request, Response } from 'express';
import { authenticate, requireHierarquia } from '../../middleware/authenticate';
import { prisma } from '../../config/database';
import { AppError } from '../../middleware/errorHandler';
import { HierarquiaNivel } from '../../types';
import { z } from 'zod';

const createReportSchema = z.object({
  reportedUserId: z.string().uuid().optional().nullable(),
  messageId: z.string().uuid().optional().nullable(),
  motivo: z.enum([
    'assedio',
    'desvio_conduta',
    'infraestrutura_risco',
    'fraude_recursos',
    'ofensa',
    'conteudo_inadequado',
    'comunicacao_impropria',
    'outro',
  ]),
  titulo: z.string().max(150).optional().nullable(),
  descricao: z.string().min(5, 'A descrição deve ter no mínimo 5 caracteres.').max(2000),
  anonimo: z.boolean().default(false),
});

const updateReportSchema = z.object({
  status: z.enum(['pendente', 'em_analise', 'resolvido', 'arquivado']),
  resposta: z.string().max(2000).optional().nullable(),
});

async function createReport(req: Request, res: Response): Promise<void> {
  const actor = req.user!;
  const data = createReportSchema.parse(req.body);

  const report = await prisma.report.create({
    data: {
      reporterId: actor.id,
      reportedUserId: data.reportedUserId ?? null,
      messageId: data.messageId ?? null,
      anonimo: data.anonimo,
      titulo: data.titulo ?? null,
      motivo: data.motivo,
      descricao: data.descricao,
      status: 'pendente',
    },
  });

  // Log de auditoria (se anônimo, oculta detalhes pessoais no log de evento)
  await prisma.auditLog.create({
    data: {
      userId: actor.id,
      acao: 'REPORT_CREATED',
      entidade: 'Report',
      entidadeId: report.id,
      detalhes: JSON.stringify({
        motivo: data.motivo,
        anonimo: data.anonimo,
      }),
      ip: req.ip,
      userAgent: req.get('user-agent'),
    },
  });

  res.status(201).json({
    success: true,
    message: data.anonimo
      ? 'Denúncia anônima registrada com sucesso. Seu sigilo está totalmente preservado.'
      : 'Denúncia registrada com sucesso. A Direção Geral analisará o caso.',
    data: { id: report.id },
  });
}

async function listReports(req: Request, res: Response): Promise<void> {
  const status = req.query.status as string | undefined;

  const reports = await prisma.report.findMany({
    where: status ? { status } : undefined,
    orderBy: { criadoEm: 'desc' },
    include: {
      reporter: {
        select: {
          id: true,
          nome: true,
          cargo: true,
          setor: { select: { nome: true } },
        },
      },
      reportedUser: {
        select: {
          id: true,
          nome: true,
          cargo: true,
          setor: { select: { nome: true } },
        },
      },
      resolvido: {
        select: {
          id: true,
          nome: true,
          cargo: true,
        },
      },
    },
  });

  // Sanitização de denúncias anônimas: remove qualquer rastro do denunciante
  const sanitized = reports.map((r) => {
    if (r.anonimo) {
      return {
        ...r,
        reporterId: null,
        reporter: {
          id: null,
          nome: 'Denunciante Anônimo',
          cargo: 'Sigiloso',
          setor: { nome: 'Identidade Ocultada' },
        },
      };
    }
    return r;
  });

  res.json({ success: true, data: sanitized });
}

async function getMyReports(req: Request, res: Response): Promise<void> {
  const actor = req.user!;

  const reports = await prisma.report.findMany({
    where: { reporterId: actor.id },
    orderBy: { criadoEm: 'desc' },
    include: {
      reportedUser: {
        select: {
          id: true,
          nome: true,
          cargo: true,
        },
      },
    },
  });

  res.json({ success: true, data: reports });
}

async function updateReportStatus(req: Request, res: Response): Promise<void> {
  const actor = req.user!;
  const { id } = req.params;
  const { status, resposta } = updateReportSchema.parse(req.body);

  const report = await prisma.report.findUnique({ where: { id } });
  if (!report) throw new AppError('Denúncia não encontrada.', 404);

  const isClosing = status === 'resolvido' || status === 'arquivado';

  const updated = await prisma.report.update({
    where: { id },
    data: {
      status,
      resposta: resposta ?? report.resposta,
      resolvidoPor: actor.id,
      resolvidoEm: isClosing ? new Date() : null,
      atualizadoEm: new Date(),
    },
  });

  // Auditoria
  await prisma.auditLog.create({
    data: {
      userId: actor.id,
      acao: 'REPORT_STATUS_UPDATED',
      entidade: 'Report',
      entidadeId: id,
      detalhes: JSON.stringify({
        statusAnterior: report.status,
        novoStatus: status,
      }),
      ip: req.ip,
      userAgent: req.get('user-agent'),
    },
  });

  res.json({
    success: true,
    message: 'Status da denúncia atualizado com sucesso.',
    data: updated,
  });
}

function asyncHandler(fn: (req: Request, res: Response) => Promise<void>) {
  return (req: Request, res: Response, next: (err?: unknown) => void) => {
    Promise.resolve(fn(req, res)).catch(next);
  };
}

const router = Router();
router.use(authenticate);

// Criar denúncia / relato (qualquer funcionário autenticado)
router.post('/', asyncHandler(createReport));

// Listar minhas próprias denúncias submetidas (acompanhar andamento)
router.get('/my', asyncHandler(getMyReports));

// Painel de Moderação & Investigação exclusivo da DIREÇÃO GERAL (Nível 1)
router.get('/', requireHierarquia(HierarquiaNivel.DIRECAO), asyncHandler(listReports));
router.patch('/:id/status', requireHierarquia(HierarquiaNivel.DIRECAO), asyncHandler(updateReportStatus));

export default router;
