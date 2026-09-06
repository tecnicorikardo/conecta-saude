import { Request, Response, NextFunction } from 'express';
import { getFirebaseAuth } from '../config/firebase';
import { prisma } from '../config/database';
import { AuthenticatedUser, HierarquiaNivel } from '../types';

/**
 * Middleware de autenticação obrigatória.
 *
 * Fluxo:
 * 1. Extrai o Bearer token do header Authorization
 * 2. Verifica o ID Token via Firebase Admin SDK
 * 3. Busca o usuário no PostgreSQL pelo firebase_uid
 * 4. Verifica se o usuário está ativo
 * 5. Anexa os dados do usuário a req.user
 *
 * NUNCA confia em informações enviadas pelo cliente (cargo, hierarquia, setor).
 * Todas as informações vêm do banco de dados.
 */
export async function authenticate(
  req: Request,
  res: Response,
  next: NextFunction,
): Promise<void> {
  try {
    // 1. Extrair token
    const authHeader = req.headers.authorization;
    if (!authHeader?.startsWith('Bearer ')) {
      res.status(401).json({
        success: false,
        error: 'Token de autenticação não fornecido.',
      });
      return;
    }

    const idToken = authHeader.split('Bearer ')[1];
    if (!idToken) {
      res.status(401).json({
        success: false,
        error: 'Token inválido.',
      });
      return;
    }

    // 2. Verificar token no Firebase
    let decodedToken: { uid: string };
    try {
      decodedToken = await getFirebaseAuth().verifyIdToken(idToken, true);
    } catch {
      res.status(401).json({
        success: false,
        error: 'Token expirado ou inválido. Faça login novamente.',
      });
      return;
    }

    // 3. Buscar usuário no banco — dados reais, não do token
    let user = await prisma.user.findUnique({
      where: { firebaseUid: decodedToken.uid },
      select: {
        id: true,
        firebaseUid: true,
        nome: true,
        email: true,
        cargo: true,
        hierarquiaNivel: true,
        setorId: true,
        ativo: true,
      },
    });

    if (!user && (decodedToken as any).email) {
      const existing = await prisma.user.findUnique({
        where: { email: (decodedToken as any).email },
      });
      if (existing) {
        user = await prisma.user.update({
          where: { id: existing.id },
          data: { firebaseUid: decodedToken.uid },
          select: {
            id: true,
            firebaseUid: true,
            nome: true,
            email: true,
            cargo: true,
            hierarquiaNivel: true,
            setorId: true,
            ativo: true,
          },
        });
      }
    }

    if (!user) {
      res.status(401).json({
        success: false,
        error: 'Usuário não encontrado no sistema.',
      });
      return;
    }

    // 4. Verificar se está ativo
    if (!user.ativo) {
      res.status(403).json({
        success: false,
        error: 'Seu acesso foi desativado. Entre em contato com o RH.',
      });
      return;
    }

    // 5. Anexar ao request
    req.user = {
      id: user.id,
      firebaseUid: user.firebaseUid,
      nome: user.nome,
      email: user.email,
      cargo: user.cargo,
      hierarquiaNivel: user.hierarquiaNivel as HierarquiaNivel,
      setorId: user.setorId,
      ativo: user.ativo,
    } satisfies AuthenticatedUser;

    next();
  } catch (error) {
    console.error('[Auth] Erro inesperado:', error);
    res.status(500).json({
      success: false,
      error: 'Erro interno de autenticação.',
    });
  }
}

/**
 * Middleware de autorização por nível hierárquico mínimo.
 * Uso: requireHierarquia(HierarquiaNivel.DIRECAO)
 */
export function requireHierarquia(nivelMinimo: HierarquiaNivel) {
  return (req: Request, res: Response, next: NextFunction): void => {
    const user = req.user;
    if (!user) {
      res.status(401).json({ success: false, error: 'Não autenticado.' });
      return;
    }

    // Nível 1 é o mais alto (Direção), nível 4 é o mais baixo (Funcionário)
    if (user.hierarquiaNivel > nivelMinimo) {
      res.status(403).json({
        success: false,
        error: 'Você não possui permissão para realizar esta ação.',
      });
      return;
    }

    next();
  };
}

/**
 * Middleware para restringir ação ao próprio setor.
 * Direção (nível 1) é sempre permitida independente do setor.
 */
export function requireSameSetorOrDirecao(getSetorId: (req: Request) => string) {
  return (req: Request, res: Response, next: NextFunction): void => {
    const user = req.user;
    if (!user) {
      res.status(401).json({ success: false, error: 'Não autenticado.' });
      return;
    }

    if (user.hierarquiaNivel === HierarquiaNivel.DIRECAO) {
      next();
      return;
    }

    const targetSetorId = getSetorId(req);
    if (user.setorId !== targetSetorId) {
      res.status(403).json({
        success: false,
        error: 'Acesso restrito ao seu setor.',
      });
      return;
    }

    next();
  };
}
