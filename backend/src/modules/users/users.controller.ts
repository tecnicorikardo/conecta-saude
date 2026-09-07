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
        criadoEm: true,
        setor: { select: { id: true, nome: true } },
      },
    }),
    prisma.user.count({ where }),
  ]);

  res.json({
    success: true,
    data: {
      items: users,
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
    include: { setor: { select: { id: true, nome: true } } },
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
      fotoUrl: data.fotoUrl ?? null,
      ativo: true,
    },
    include: { setor: { select: { id: true, nome: true } } },
  });

  await auditLog({
    userId: actor.id,
    acao: 'criar_usuario',
    entidade: 'user',
    entidadeId: user.id,
    detalhes: { nome: user.nome, email: user.email, cargo: user.cargo },
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

  const updated = await prisma.user.update({
    where: { id },
    data: {
      ...(data.nome && { nome: data.nome }),
      ...(data.cargo && { cargo: data.cargo }),
      ...(data.matricula !== undefined && { matricula: data.matricula }),
      ...(isDirecao && data.hierarquiaNivel && { hierarquiaNivel: data.hierarquiaNivel }),
      ...(isDirecao && data.setorId && { setorId: data.setorId }),
      ...(data.fotoUrl !== undefined && { fotoUrl: data.fotoUrl }),
    },
    include: { setor: { select: { id: true, nome: true } } },
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
    data: updated,
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

  // Coordenação só vê pendentes da sua unidade
  if (actor.hierarquiaNivel === HierarquiaNivel.COORDENACAO) {
    where.setorId = actor.setorId;
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
      criadoEm: true,
      setor: { select: { id: true, nome: true } },
    },
  });

  res.json({
    success: true,
    data: {
      items: pendingUsers,
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
    include: { setor: true },
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
