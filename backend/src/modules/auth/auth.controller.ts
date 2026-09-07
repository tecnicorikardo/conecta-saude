import { Request, Response } from 'express';
import { prisma } from '../../config/database';
import { getFirebaseAuth, getFirebaseMessaging } from '../../config/firebase';
import { HierarquiaNivel } from '../../types';
import { verifyTokenSchema, updateFcmTokenSchema, registerUserSchema } from './auth.schema';
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
  let user = await prisma.user.findUnique({
    where: { firebaseUid: decodedToken.uid },
    include: {
      setor: { select: { id: true, nome: true } },
    },
  });

  if (!user && decodedToken.email) {
    user = await prisma.user.findUnique({
      where: { email: decodedToken.email },
      include: {
        setor: { select: { id: true, nome: true } },
      },
    });

    if (user) {
      user = await prisma.user.update({
        where: { id: user.id },
        data: { firebaseUid: decodedToken.uid },
        include: {
          setor: { select: { id: true, nome: true } },
        },
      });
    } else if (decodedToken.email.toLowerCase() === 'tecnicorikardo@gmail.com') {
      let defaultSetor = await prisma.sector.findFirst({
        where: { nome: { contains: 'Direção', mode: 'insensitive' } },
      });
      if (!defaultSetor) {
        defaultSetor = await prisma.sector.findFirst();
      }
      if (defaultSetor) {
        user = await prisma.user.create({
          data: {
            firebaseUid: decodedToken.uid,
            nome: 'Ricardo (Admin / Direção Geral)',
            email: decodedToken.email,
            cargo: 'Diretor Geral / Administrador de TI',
            hierarquiaNivel: HierarquiaNivel.DIRECAO,
            setorId: defaultSetor.id,
            ativo: true,
          },
          include: {
            setor: { select: { id: true, nome: true } },
          },
        });
      }
    }
  }

  if (!user) {
    throw new AppError('Usuário não cadastrado no sistema.', 404);
  }

  if (!user.ativo) {
    if (!user.aprovadoEm) {
      throw new AppError(
        'Cadastro em análise. Seu acesso está aguardando aprovação pelo RH ou Coordenação da unidade.',
        403,
      );
    }
    throw new AppError(
      'Seu acesso foi desativado. Entre em contato com o RH da unidade.',
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

/**
 * POST /api/auth/test-push
 * Envia push de diagnóstico diretamente para o FCM token registrado do usuário
 */
export async function testPush(req: Request, res: Response): Promise<void> {
  const userId = req.user!.id;
  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: { id: true, nome: true, fcmToken: true },
  });

  if (!user || !user.fcmToken) {
    throw new AppError('Nenhum token FCM registrado para este usuário. Ative as notificações no perfil primeiro.', 400);
  }

  const messaging = getFirebaseMessaging();
  try {
    const messageId = await messaging.send({
      token: user.fcmToken,
      notification: {
        title: '🚨 Teste Conecta Saúde (SUS)',
        body: 'Notificação push funcionando em tempo real!',
      },
      data: {
        type: 'test_push',
        timestamp: new Date().toISOString(),
      },
      webpush: {
        fcmOptions: {
          link: 'https://conecta-hospital.web.app/profile',
        },
        notification: {
          title: '🚨 Teste Conecta Saúde (SUS)',
          body: 'Notificação push funcionando em tempo real!',
          icon: 'https://conecta-hospital.web.app/icons/Icon-192.png',
          badge: 'https://conecta-hospital.web.app/icons/Icon-192.png',
          tag: 'conecta_test_' + Date.now(),
          renotify: true,
          requireInteraction: true,
        },
      },
    });

    console.log(`[FCM Test Push] Sucesso para ${user.nome} (${user.id}): ${messageId}`);
    res.json({
      success: true,
      message: 'Push enviado com sucesso pelo Firebase Admin!',
      messageId,
      tokenPreview: user.fcmToken.substring(0, 25) + '...',
    });
  } catch (error: any) {
    console.error('[FCM Test Push Error]:', error);
    res.status(500).json({
      success: false,
      errorCode: error.code || error.errorInfo?.code || 'UNKNOWN_ERROR',
      errorMessage: error.message || 'Erro ao enviar push via Firebase Admin SDK',
    });
  }
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

/**
 * POST /api/auth/register
 * Auto-cadastro de novos servidores públicos.
 * Cria a conta no Firebase Auth e no PostgreSQL com status ativo = false (pendente de aprovação).
 */
export async function registerUser(req: Request, res: Response): Promise<void> {
  const data = registerUserSchema.parse(req.body);

  // 1. Validar setor
  const setor = await prisma.sector.findUnique({ where: { id: data.setorId } });
  if (!setor) throw new AppError('Unidade/Setor selecionado não encontrado.', 404);

  // 2. Validar e-mail duplicado
  const existingUser = await prisma.user.findUnique({ where: { email: data.email } });
  if (existingUser) {
    throw new AppError('Este e-mail já está cadastrado no sistema.', 409);
  }

  // 3. Criar no Firebase Auth
  let firebaseUser: { uid: string };
  try {
    firebaseUser = await getFirebaseAuth().createUser({
      email: data.email,
      password: data.password,
      displayName: data.nome,
    });
  } catch (err: unknown) {
    const error = err as { code?: string; message?: string };
    if (error.code === 'auth/email-already-exists') {
      throw new AppError('Este e-mail já está cadastrado.', 409);
    }
    throw new AppError('Falha ao registrar credenciais no Firebase.', 500);
  }

  // 4. Criar no banco de dados como PENDENTE (ativo: false)
  const user = await prisma.user.create({
    data: {
      firebaseUid: firebaseUser.uid,
      nome: data.nome,
      email: data.email,
      cargo: data.cargo,
      matricula: data.matricula ?? null,
      hierarquiaNivel: HierarquiaNivel.FUNCIONARIO,
      setorId: data.setorId,
      ativo: false,
    },
    include: {
      setor: { select: { nome: true } },
    },
  });

  // 5. Auditoria de novo auto-cadastro
  await prisma.auditLog.create({
    data: {
      userId: user.id,
      acao: 'auto_cadastro_solicitado',
      entidade: 'user',
      entidadeId: user.id,
      detalhes: JSON.stringify({
        nome: user.nome,
        email: user.email,
        cargo: user.cargo,
        setor: user.setor.nome,
        matricula: user.matricula,
      }),
      ip: req.ip,
      userAgent: req.get('user-agent'),
    },
  });

  res.status(201).json({
    success: true,
    message: 'Cadastro realizado com sucesso! Seu acesso está aguardando liberação pelo RH ou Coordenação da unidade.',
    data: {
      id: user.id,
      nome: user.nome,
      email: user.email,
      cargo: user.cargo,
      setorNome: user.setor.nome,
      status: 'pendente_aprovacao',
    },
  });
}

