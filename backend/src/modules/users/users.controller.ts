import { Request, Response } from 'express';
import { prisma } from '../../config/database';
import { getFirebaseAuth } from '../../config/firebase';
import { HierarquiaNivel } from '../../types';
import { AppError } from '../../middleware/errorHandler';
import { auditLog } from '../../utils/auditLogger';
import {
  createUserSchema,
  updateUserSchema,
  updateUserStatusSchema,
  updateScheduleSchema,
  listUsersSchema,
} from './users.schema';

/**
 * GET /api/users
 * Lista usuários com filtros e paginação.
 * Direção: vê todos. Demais: veem apenas seu setor.
 */
export async function listUsers(req: Request, res: Response): Promise<void> {
  const actor = req.user!;
  const query = listUsersSchema.parse(req.query);

  const where: Record<string, unknown> = {};

  // Restrição de setor para não-Direção
  if (actor.hierarquiaNivel !== HierarquiaNivel.DIRECAO) {
    where.setorId = actor.setorId;
  } else if (query.setorId) {
    where.setorId = query.setorId;
  }

  if (query.unitId) where.unitId = query.unitId;
  if (query.hierarquiaNivel) where.hierarquiaNivel = query.hierarquiaNivel;
  if (query.ativo !== undefined) where.ativo = query.ativo === 'true';
  if (query.excludeSelf === 'true') where.id = { not: actor.id };

  if (query.search) {
    where.OR = [
      { nome: { contains: query.search, mode: 'insensitive' } },
      { email: { contains: query.search, mode: 'insensitive' } },
      { cargo: { contains: query.search, mode: 'insensitive' } },
    ];
  }

  const skip = (query.page - 1) * query.limit;

  const [users, total] = await Promise.all([
    prisma.user.findMany({
      where,
      skip,
      take: query.limit,
      orderBy: [{ hierarquiaNivel: 'asc' }, { nome: 'asc' }],
      select: {
        id: true,
        nome: true,
        email: true,
        cargo: true,
        hierarquiaNivel: true,
        fotoUrl: true,
        ativo: true,
        unitId: true,
        jornadaInicio: true,
        jornadaFim: true,
        jornadaDias: true,
        emPlantaoExtra: true,
        silenciarForaJornada: true,
        criadoEm: true,
        setor: { select: { id: true, nome: true } },
        unit: { select: { id: true, nome: true, sigla: true } },
      },
    }),
    prisma.user.count({ where }),
  ]);

  res.json({
    success: true,
    data: {
      items: users.map(u => ({
        ...u,
        unitNome: u.unit?.nome ?? null,
        unitSigla: u.unit?.sigla ?? null,
      })),
      total,
      page: query.page,
      limit: query.limit,
      hasMore: skip + users.length < total,
    },
  });
}

/**
 * GET /api/users/:id
 * Retorna um usuário específico.
 */
export async function getUser(req: Request, res: Response): Promise<void> {
  const actor = req.user!;
  const { id } = req.params;

  const user = await prisma.user.findUnique({
    where: { id },
    include: {
      setor: { select: { id: true, nome: true } },
      unit: { select: { id: true, nome: true, sigla: true } },
    },
  });

  if (!user) throw new AppError('Usuário não encontrado.', 404);

  res.json({
    success: true,
    data: {
      id: user.id,
      nome: user.nome,
      email: user.email,
      cargo: user.cargo,
      hierarquiaNivel: user.hierarquiaNivel,
      setorId: user.setorId,
      setorNome: user.setor.nome,
      unitId: user.unitId,
      unitNome: user.unit?.nome ?? null,
      unitSigla: user.unit?.sigla ?? null,
      jornadaInicio: user.jornadaInicio,
      jornadaFim: user.jornadaFim,
      jornadaDias: user.jornadaDias,
      emPlantaoExtra: user.emPlantaoExtra,
      silenciarForaJornada: user.silenciarForaJornada,
      fotoUrl: user.fotoUrl,
      matricula: user.matricula,
      ativo: user.ativo,
      criadoEm: user.criadoEm,
    },
  });
}

/**
 * POST /api/users
 * Cria novo funcionário. Apenas Direção.
 * Cria no Firebase Auth e no PostgreSQL.
 */
export async function createUser(req: Request, res: Response): Promise<void> {
  const actor = req.user!;

  // Somente Direção pode criar usuários
  if (actor.hierarquiaNivel !== HierarquiaNivel.DIRECAO) {
    throw new AppError('Apenas a Direção pode cadastrar funcionários.', 403);
  }

  const data = createUserSchema.parse(req.body);

  // Verificar se setor existe
  const setor = await prisma.sector.findUnique({ where: { id: data.setorId } });
  if (!setor) throw new AppError('Setor não encontrado.', 404);

  // Verificar e-mail duplicado
  const emailExistente = await prisma.user.findUnique({
    where: { email: data.email },
  });
  if (emailExistente) throw new AppError('E-mail já cadastrado no sistema.', 409);

  // Criar no Firebase Auth
  let firebaseUser: { uid: string };
  try {
    firebaseUser = await getFirebaseAuth().createUser({
      email: data.email,
      password: data.password,
      displayName: data.nome,
    });
  } catch (err: unknown) {
    const error = err as { code?: string };
    if (error.code === 'auth/email-already-exists') {
      throw new AppError('E-mail já existe no sistema de autenticação.', 409);
    }
    throw new AppError('Falha ao criar usuário no sistema de autenticação.', 500);
  }

  // Criar no PostgreSQL
  const user = await prisma.user.create({
    data: {
      firebaseUid: firebaseUser.uid,
      nome: data.nome,
      email: data.email,
      cargo: data.cargo,
      hierarquiaNivel: data.hierarquiaNivel,
      setorId: data.setorId,
      unitId: data.unitId ?? null,
      jornadaInicio: data.jornadaInicio ?? '07:00',
      jornadaFim: data.jornadaFim ?? '16:00',
      jornadaDias: data.jornadaDias ?? 'seg,ter,qua,qui,sex',
      silenciarForaJornada: data.silenciarForaJornada ?? true,
      fotoUrl: data.fotoUrl ?? null,
      ativo: true,
    },
    include: {
      setor: { select: { id: true, nome: true } },
      unit: { select: { id: true, nome: true, sigla: true } },
    },
  });

  await auditLog({
    userId: actor.id,
    acao: 'criar_usuario',
    entidade: 'user',
    entidadeId: user.id,
    detalhes: { nome: user.nome, email: user.email, cargo: user.cargo, unitId: user.unitId },
    req,
  });

  res.status(201).json({
    success: true,
    message: 'Funcionário cadastrado com sucesso.',
    data: {
      id: user.id,
      nome: user.nome,
      email: user.email,
      cargo: user.cargo,
      hierarquiaNivel: user.hierarquiaNivel,
      setorNome: user.setor.nome,
      unitId: user.unitId,
      unitNome: user.unit?.nome ?? null,
      unitSigla: user.unit?.sigla ?? null,
      jornadaInicio: user.jornadaInicio,
      jornadaFim: user.jornadaFim,
      jornadaDias: user.jornadaDias,
      emPlantaoExtra: user.emPlantaoExtra,
      silenciarForaJornada: user.silenciarForaJornada,
      ativo: user.ativo,
    },
  });
}

/**
 * PUT /api/users/:id
 * Edita dados de um funcionário. Apenas Direção.
 * Nunca permite auto-escalação de privilégios.
 */
export async function updateUser(req: Request, res: Response): Promise<void> {
  const actor = req.user!;
  const { id } = req.params;

  // Direção pode editar qualquer usuário; outros usuários podem editar seu próprio perfil
  if (actor.hierarquiaNivel !== HierarquiaNivel.DIRECAO && actor.id !== id) {
    throw new AppError('Apenas a Direção ou o próprio usuário pode editar seu perfil.', 403);
  }

  const data = updateUserSchema.parse(req.body);

  const user = await prisma.user.findUnique({ where: { id } });
  if (!user) throw new AppError('Usuário não encontrado.', 404);

  // Somente a Direção pode alterar nível hierárquico ou setor de terceiros
  const isDirecao = actor.hierarquiaNivel === HierarquiaNivel.DIRECAO;

  if (data.setorId && isDirecao) {
    const setor = await prisma.sector.findUnique({ where: { id: data.setorId } });
    if (!setor) throw new AppError('Setor não encontrado.', 404);
  }

  if (data.unitId && isDirecao) {
    const unit = await prisma.hospitalUnit.findUnique({ where: { id: data.unitId } });
    if (!unit) throw new AppError('Unidade hospitalar não encontrada.', 404);
  }

  const updated = await prisma.user.update({
    where: { id },
    data: {
      ...(data.nome && { nome: data.nome }),
      ...(data.cargo && { cargo: data.cargo }),
      ...(data.matricula !== undefined && { matricula: data.matricula }),
      ...(isDirecao && data.hierarquiaNivel && { hierarquiaNivel: data.hierarquiaNivel }),
      ...(isDirecao && data.setorId && { setorId: data.setorId }),
      ...(isDirecao && data.unitId !== undefined && { unitId: data.unitId }),
      ...(data.jornadaInicio && { jornadaInicio: data.jornadaInicio }),
      ...(data.jornadaFim && { jornadaFim: data.jornadaFim }),
      ...(data.jornadaDias && { jornadaDias: data.jornadaDias }),
      ...(data.emPlantaoExtra !== undefined && { emPlantaoExtra: data.emPlantaoExtra }),
      ...(data.silenciarForaJornada !== undefined && { silenciarForaJornada: data.silenciarForaJornada }),
      ...(data.fotoUrl !== undefined && { fotoUrl: data.fotoUrl }),
    },
    include: {
      setor: { select: { id: true, nome: true } },
      unit: { select: { id: true, nome: true, sigla: true } },
    },
  });

  await auditLog({
    userId: actor.id,
    acao: 'editar_usuario',
    entidade: 'user',
    entidadeId: id,
    detalhes: { alteracoes: data },
    req,
  });

  res.json({
    success: true,
    message: 'Funcionário atualizado com sucesso.',
    data: {
      ...updated,
      unitNome: updated.unit?.nome ?? null,
      unitSigla: updated.unit?.sigla ?? null,
    },
  });
}

/**
 * PATCH /api/users/:id/status
 * Ativa ou desativa um funcionário. Apenas Direção.
 * Usa soft delete — nunca remove do banco.
 */
export async function updateUserStatus(req: Request, res: Response): Promise<void> {
  const actor = req.user!;

  if (actor.hierarquiaNivel !== HierarquiaNivel.DIRECAO) {
    throw new AppError('Apenas a Direção pode alterar o status de funcionários.', 403);
  }

  const { id } = req.params;
  const { ativo } = updateUserStatusSchema.parse(req.body);

  const user = await prisma.user.findUnique({ where: { id } });
  if (!user) throw new AppError('Usuário não encontrado.', 404);

  // Impedir auto-desativação
  if (id === actor.id && !ativo) {
    throw new AppError('Você não pode desativar sua própria conta.', 400);
  }

  await prisma.user.update({ where: { id }, data: { ativo } });

  // Revogar sessões Firebase se desativado
  if (!ativo) {
    try {
      await getFirebaseAuth().revokeRefreshTokens(user.firebaseUid);
    } catch {
      console.warn(`[Users] Falha ao revogar tokens Firebase para ${user.firebaseUid}`);
    }
  }

  await auditLog({
    userId: actor.id,
    acao: ativo ? 'ativar_usuario' : 'desativar_usuario',
    entidade: 'user',
    entidadeId: id,
    req,
  });

  res.json({
    success: true,
    message: ativo
      ? 'Funcionário ativado com sucesso.'
      : 'Funcionário desativado com sucesso.',
  });
}

/**
 * GET /api/users/pending
 * Lista colaboradores com cadastro pendente de aprovação.
 * Permitido para Direção (todos os setores) e Coordenação (apenas seu setor).
 */
export async function getPendingUsers(req: Request, res: Response): Promise<void> {
  const actor = req.user!;

  if (actor.hierarquiaNivel > HierarquiaNivel.COORDENACAO) {
    throw new AppError('Apenas a Direção ou Coordenação podem visualizar aprovações pendentes.', 403);
  }

  const where: Record<string, unknown> = {
    ativo: false,
    aprovadoEm: null,
  };

  // Coordenação só vê pendentes da sua unidade / setor
  if (actor.hierarquiaNivel === HierarquiaNivel.COORDENACAO) {
    where.setorId = actor.setorId;
    if (actor.unitId) {
      where.unitId = actor.unitId;
    }
  }

  const pendingUsers = await prisma.user.findMany({
    where,
    orderBy: { criadoEm: 'desc' },
    select: {
      id: true,
      nome: true,
      email: true,
      cargo: true,
      matricula: true,
      hierarquiaNivel: true,
      fotoUrl: true,
      ativo: true,
      unitId: true,
      jornadaInicio: true,
      jornadaFim: true,
      jornadaDias: true,
      criadoEm: true,
      setor: { select: { id: true, nome: true } },
      unit: { select: { id: true, nome: true, sigla: true } },
    },
  });

  res.json({
    success: true,
    data: {
      items: pendingUsers.map(u => ({
        ...u,
        unitNome: u.unit?.nome ?? null,
        unitSigla: u.unit?.sigla ?? null,
      })),
      total: pendingUsers.length,
    },
  });
}

/**
 * PATCH /api/users/:id/approve
 * Aprova o cadastro de um colaborador com 1 clique.
 * Permitido para Direção (qualquer setor) e Coordenação (seu próprio setor).
 */
export async function approveUser(req: Request, res: Response): Promise<void> {
  const actor = req.user!;
  const { id } = req.params;

  if (actor.hierarquiaNivel > HierarquiaNivel.COORDENACAO) {
    throw new AppError('Apenas a Direção ou Coordenação podem aprovar novos colaboradores.', 403);
  }

  const user = await prisma.user.findUnique({
    where: { id },
    include: { setor: true, unit: true },
  });

  if (!user) throw new AppError('Colaborador não encontrado.', 404);

  if (actor.hierarquiaNivel === HierarquiaNivel.COORDENACAO && user.setorId !== actor.setorId) {
    throw new AppError('Coordenadores só podem aprovar colaboradores da sua própria unidade.', 403);
  }

  if (user.ativo) {
    throw new AppError('Este colaborador já se encontra ativo e aprovado.', 400);
  }

  const updatedUser = await prisma.user.update({
    where: { id },
    data: {
      ativo: true,
      aprovadoPor: actor.id,
      aprovadoEm: new Date(),
    },
    include: {
      setor: { select: { id: true, nome: true } },
      unit: { select: { id: true, nome: true, sigla: true } },
      aprovador: { select: { id: true, nome: true, cargo: true } },
    },
  });

  await auditLog({
    userId: actor.id,
    acao: 'aprovar_usuario',
    entidade: 'user',
    entidadeId: id,
    detalhes: {
      nome: user.nome,
      email: user.email,
      cargo: user.cargo,
      setor: user.setor.nome,
      unitNome: user.unit?.nome ?? null,
      matricula: user.matricula,
      aprovadoPor: actor.nome,
    },
    req,
  });

  res.json({
    success: true,
    message: `Cadastro de ${user.nome} aprovado com sucesso! O acesso ao sistema já está liberado.`,
    data: {
      id: updatedUser.id,
      nome: updatedUser.nome,
      email: updatedUser.email,
      cargo: updatedUser.cargo,
      setorNome: updatedUser.setor.nome,
      unitNome: updatedUser.unit?.nome ?? null,
      unitSigla: updatedUser.unit?.sigla ?? null,
      ativo: updatedUser.ativo,
      aprovadoEm: updatedUser.aprovadoEm,
      aprovadoPorNome: updatedUser.aprovador?.nome,
    },
  });
}

/**
 * DELETE /api/users/:id/reject
 * Rejeita e remove a solicitação de cadastro pendente.
 * Permitido para Direção e Coordenação (da unidade).
 */
export async function rejectUser(req: Request, res: Response): Promise<void> {
  const actor = req.user!;
  const { id } = req.params;

  if (actor.hierarquiaNivel > HierarquiaNivel.COORDENACAO) {
    throw new AppError('Apenas a Direção ou Coordenação podem rejeitar solicitações.', 403);
  }

  const user = await prisma.user.findUnique({
    where: { id },
    include: { setor: true },
  });

  if (!user) throw new AppError('Solicitação não encontrada.', 404);

  if (actor.hierarquiaNivel === HierarquiaNivel.COORDENACAO && user.setorId !== actor.setorId) {
    throw new AppError('Coordenadores só podem rejeitar cadastros da sua própria unidade.', 403);
  }

  if (user.ativo) {
    throw new AppError('Não é possível rejeitar um colaborador que já está ativo.', 400);
  }

  // Deletar do Firebase Auth se existir
  try {
    await getFirebaseAuth().deleteUser(user.firebaseUid);
  } catch {
    console.warn(`[Users] Usuário ${user.firebaseUid} não encontrado no Firebase Auth durante rejeição.`);
  }

  // Deletar do PostgreSQL
  await prisma.user.delete({ where: { id } });

  await auditLog({
    userId: actor.id,
    acao: 'rejeitar_cadastro',
    entidade: 'user',
    entidadeId: id,
    detalhes: {
      nome: user.nome,
      email: user.email,
      setor: user.setor.nome,
      rejeitadoPor: actor.nome,
    },
    req,
  });

  res.json({
    success: true,
    message: `Solicitação de ${user.nome} rejeitada e removida com sucesso.`,
  });
}

/**
 * PATCH /api/users/me/schedule
 * Atualiza o horário de trabalho, dias de escala e status de plantão do próprio usuário autenticado.
 */
export async function updateMySchedule(req: Request, res: Response): Promise<void> {
  const actor = req.user!;
  const data = updateScheduleSchema.parse(req.body);

  const updatedUser = await prisma.user.update({
    where: { id: actor.id },
    data: {
      ...(data.jornadaInicio !== undefined && { jornadaInicio: data.jornadaInicio }),
      ...(data.jornadaFim !== undefined && { jornadaFim: data.jornadaFim }),
      ...(data.jornadaDias !== undefined && { jornadaDias: data.jornadaDias }),
      ...(data.emPlantaoExtra !== undefined && { emPlantaoExtra: data.emPlantaoExtra }),
      ...(data.silenciarForaJornada !== undefined && { silenciarForaJornada: data.silenciarForaJornada }),
    },
    select: {
      id: true,
      nome: true,
      jornadaInicio: true,
      jornadaFim: true,
      jornadaDias: true,
      emPlantaoExtra: true,
      silenciarForaJornada: true,
    },
  });

  await auditLog({
    userId: actor.id,
    acao: 'atualizar_escala',
    entidade: 'user',
    entidadeId: actor.id,
    detalhes: data,
    req,
  });

  res.json({
    success: true,
    message: 'Configurações de jornada e escala atualizadas com sucesso.',
    data: updatedUser,
  });
}
