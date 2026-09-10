import { Request, Response } from 'express';
import { prisma } from '../../config/database';
import { HierarquiaNivel } from '../../types';
import { AppError } from '../../middleware/errorHandler';
import { auditLog } from '../../utils/auditLogger';
import { z } from 'zod';

const createUnitSchema = z.object({
  nome: z.string().min(2).max(120),
  sigla: z.string().max(20).optional(),
  endereco: z.string().max(200).optional(),
  cidade: z.string().max(80).optional(),
});

const updateUnitSchema = createUnitSchema.partial().extend({
  ativo: z.boolean().optional(),
});

/**
 * GET /api/units
 * Lista todas as unidades hospitalares ativas
 */
export async function listUnits(_req: Request, res: Response): Promise<void> {
  const units = await prisma.hospitalUnit.findMany({
    where: { ativo: true },
    orderBy: { nome: 'asc' },
    select: {
      id: true,
      nome: true,
      sigla: true,
      endereco: true,
      cidade: true,
      ativo: true,
      criadoEm: true,
      _count: {
        select: {
          sectors: true,
          users: true,
        },
      },
    },
  });
  res.json({ success: true, data: units });
}

/**
 * GET /api/units/:id
 * Retorna os detalhes de uma unidade com seus setores
 */
export async function getUnit(req: Request, res: Response): Promise<void> {
  const { id } = req.params;
  const unit = await prisma.hospitalUnit.findUnique({
    where: { id },
    include: {
      sectors: {
        where: { ativo: true },
        select: { id: true, nome: true, descricao: true },
      },
    },
  });
  if (!unit) throw new AppError('Unidade hospitalar não encontrada.', 404);
  res.json({ success: true, data: unit });
}

/**
 * POST /api/units
 * Cria uma nova unidade (Apenas Direção)
 */
export async function createUnit(req: Request, res: Response): Promise<void> {
  const actor = req.user!;
  if (actor.hierarquiaNivel !== HierarquiaNivel.DIRECAO) {
    throw new AppError('Apenas a Direção pode cadastrar novas unidades hospitalares.', 403);
  }

  const data = createUnitSchema.parse(req.body);
  const existing = await prisma.hospitalUnit.findFirst({ where: { nome: data.nome } });
  if (existing) throw new AppError('Já existe uma unidade com este nome.', 409);

  const unit = await prisma.hospitalUnit.create({ data: { ...data, ativo: true } });

  await auditLog({ userId: actor.id, acao: 'criar_unidade', entidade: 'hospital_unit', entidadeId: unit.id, req });

  res.status(201).json({ success: true, data: unit });
}

/**
 * PUT /api/units/:id
 * Edita uma unidade (Apenas Direção)
 */
export async function updateUnit(req: Request, res: Response): Promise<void> {
  const actor = req.user!;
  if (actor.hierarquiaNivel !== HierarquiaNivel.DIRECAO) {
    throw new AppError('Apenas a Direção pode editar unidades hospitalares.', 403);
  }

  const { id } = req.params;
  const data = updateUnitSchema.parse(req.body);

  const unit = await prisma.hospitalUnit.findUnique({ where: { id } });
  if (!unit) throw new AppError('Unidade hospitalar não encontrada.', 404);

  const updated = await prisma.hospitalUnit.update({ where: { id }, data });

  await auditLog({ userId: actor.id, acao: 'editar_unidade', entidade: 'hospital_unit', entidadeId: id, req });

  res.json({ success: true, data: updated });
}
