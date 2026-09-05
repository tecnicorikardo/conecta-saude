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

  // Não-Direção só pode ver usuários do próprio setor
  if (
    actor.hierarquiaNivel !== HierarquiaNivel.DIRECAO &&
    user.setorId !== actor.setorId
  ) {
    throw new AppError('Acesso negado.', 403);
  }

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

  if (actor.hierarquiaNivel !== HierarquiaNivel.DIRECAO) {
    throw new AppError('Apenas a Direção pode editar funcionários.', 403);
  }

  const { id } = req.params;
  const data = updateUserSchema.parse(req.body);

  const user = await prisma.user.findUnique({ where: { id } });
  if (!user) throw new AppError('Usuário não encontrado.', 404);

  // Verificar setor se informado
  if (data.setorId) {
    const setor = await prisma.sector.findUnique({ where: { id: data.setorId } });
    if (!setor) throw new AppError('Setor não encontrado.', 404);
  }

  const updated = await prisma.user.update({
    where: { id },
    data: {
      ...(data.nome && { nome: data.nome }),
      ...(data.cargo && { cargo: data.cargo }),
      ...(data.hierarquiaNivel && { hierarquiaNivel: data.hierarquiaNivel }),
      ...(data.setorId && { setorId: data.setorId }),
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
