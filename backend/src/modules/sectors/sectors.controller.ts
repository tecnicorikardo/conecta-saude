import { Request, Response } from 'express';
import { prisma } from '../../config/database';
import { HierarquiaNivel } from '../../types';
import { AppError } from '../../middleware/errorHandler';
import { auditLog } from '../../utils/auditLogger';
import { z } from 'zod';

const createSectorSchema = z.object({
  nome: z.string().min(2).max(80),
  descricao: z.string().max(300).optional(),
});

const updateSectorSchema = createSectorSchema.partial().extend({
  ativo: z.boolean().optional(),
});

export async function listSectors(_req: Request, res: Response): Promise<void> {
  const sectors = await prisma.sector.findMany({
    where: { ativo: true },
    orderBy: { nome: 'asc' },
    select: { id: true, nome: true, descricao: true, ativo: true, criadoEm: true },
  });
  res.json({ success: true, data: sectors });
}

export async function createSector(req: Request, res: Response): Promise<void> {
  const actor = req.user!;
  if (actor.hierarquiaNivel !== HierarquiaNivel.DIRECAO) {
    throw new AppError('Apenas a Direção pode criar setores.', 403);
  }

  const data = createSectorSchema.parse(req.body);
  const existing = await prisma.sector.findFirst({ where: { nome: data.nome } });
  if (existing) throw new AppError('Já existe um setor com este nome.', 409);

  const sector = await prisma.sector.create({ data: { ...data, ativo: true } });

  await auditLog({ userId: actor.id, acao: 'criar_setor', entidade: 'sector', entidadeId: sector.id, req });

  res.status(201).json({ success: true, data: sector });
}

export async function updateSector(req: Request, res: Response): Promise<void> {
  const actor = req.user!;
  if (actor.hierarquiaNivel !== HierarquiaNivel.DIRECAO) {
    throw new AppError('Apenas a Direção pode editar setores.', 403);
  }

  const { id } = req.params;
  const data = updateSectorSchema.parse(req.body);

  const sector = await prisma.sector.findUnique({ where: { id } });
  if (!sector) throw new AppError('Setor não encontrado.', 404);

  const updated = await prisma.sector.update({ where: { id }, data });

  await auditLog({ userId: actor.id, acao: 'editar_setor', entidade: 'sector', entidadeId: id, req });

  res.json({ success: true, data: updated });
}
