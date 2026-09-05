import { Request, Response } from 'express';
import { prisma } from '../../config/database';
import { getFirebaseAuth } from '../../config/firebase';
import { HierarquiaNivel } from '../../types';
import { verifyTokenSchema, updateFcmTokenSchema } from './auth.schema';
import { AppError } from '../../middleware/errorHandler';

/**
 * POST /api/auth/verify
 * Valida o ID Token Firebase e retorna os dados completos do usuário.
 * Este é o endpoint chamado logo após o login no Flutter.
 */
export async function verifyToken(req: Request, res: Response): Promise<void> {
  const { idToken, fcmToken } = verifyTokenSchema.parse(req.body);

  // Verificar token
  let decodedToken: { uid: string; email?: string };
  try {
    decodedToken = await getFirebaseAuth().verifyIdToken(idToken, true);
  } catch {
    throw new AppError('Token inválido ou expirado.', 401);
  }

  // Buscar usuário no banco
  const user = await prisma.user.findUnique({
    where: { firebaseUid: decodedToken.uid },
    include: {
      setor: { select: { id: true, nome: true } },
    },
  });

  if (!user) {
    throw new AppError('Usuário não cadastrado no sistema.', 404);
  }

  if (!user.ativo) {
    throw new AppError(
      'Seu acesso foi desativado. Entre em contato com o RH.',
      403,
    );
  }

  // Atualizar FCM token se fornecido
  if (fcmToken && fcmToken !== user.fcmToken) {
    await prisma.user.update({
      where: { id: user.id },
      data: { fcmToken },
    });
  }

  res.json({
    success: true,
    data: {
      id: user.id,
      firebaseUid: user.firebaseUid,
      nome: user.nome,
      email: user.email,
      cargo: user.cargo,
      hierarquiaNivel: user.hierarquiaNivel,
      hierarquiaNome: getHierarquiaNome(user.hierarquiaNivel),
      setorId: user.setorId,
      setorNome: user.setor.nome,
      fotoUrl: user.fotoUrl,
      ativo: user.ativo,
      criadoEm: user.criadoEm,
    },
  });
}

/**
 * GET /api/me
 * Retorna os dados do usuário autenticado (requer middleware authenticate).
 */
export async function getMe(req: Request, res: Response): Promise<void> {
  const userId = req.user!.id;

  const user = await prisma.user.findUniqueOrThrow({
    where: { id: userId },
    include: {
      setor: { select: { id: true, nome: true } },
    },
  });

  res.json({
    success: true,
    data: {
      id: user.id,
      firebaseUid: user.firebaseUid,
      nome: user.nome,
      email: user.email,
      cargo: user.cargo,
      hierarquiaNivel: user.hierarquiaNivel,
      hierarquiaNome: getHierarquiaNome(user.hierarquiaNivel),
      setorId: user.setorId,
      setorNome: user.setor.nome,
      fotoUrl: user.fotoUrl,
      ativo: user.ativo,
      criadoEm: user.criadoEm,
      atualizadoEm: user.atualizadoEm,
    },
  });
}

/**
 * PATCH /api/auth/fcm-token
 * Atualiza o FCM token do usuário autenticado.
 */
export async function updateFcmToken(req: Request, res: Response): Promise<void> {
  const { fcmToken } = updateFcmTokenSchema.parse(req.body);
  const userId = req.user!.id;

  await prisma.user.update({
    where: { id: userId },
    data: { fcmToken },
  });

  res.json({ success: true, message: 'FCM token atualizado.' });
}

function getHierarquiaNome(nivel: number): string {
  switch (nivel) {
    case HierarquiaNivel.DIRECAO: return 'Direção';
    case HierarquiaNivel.COORDENACAO: return 'Coordenação';
    case HierarquiaNivel.SUPERVISAO: return 'Supervisão';
    case HierarquiaNivel.FUNCIONARIO: return 'Funcionário';
    default: return 'Desconhecido';
  }
}
