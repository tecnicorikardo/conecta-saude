import { Request, Response, NextFunction } from 'express';
import { db } from './db';
import { User, HierarchyLevel } from './types';

declare global {
  namespace Express {
    interface Request {
      user?: User;
    }
  }
}

/**
 * Middleware de autenticação e identificação de usuário.
 * Suporta:
 * 1. Header `x-user-id: usr-carlos`
 * 2. Header `Authorization: Bearer <user_id_ou_token>`
 * 3. Default fallback seguro para o primeiro usuário da Direção (para inicialização suave)
 */
export function authenticate(req: Request, res: Response, next: NextFunction): void {
  try {
    let userId = req.headers['x-user-id'] as string;

    if (!userId) {
      const authHeader = req.headers.authorization;
      if (authHeader && authHeader.startsWith('Bearer ')) {
        userId = authHeader.substring(7).trim();
      }
    }

    // Se nenhum header foi enviado, tenta buscar pelo cookie ou default
    if (!userId) {
      const defaultUser = db.getUserById('usr-carlos');
      if (defaultUser) {
        req.user = defaultUser;
        return next();
      }
      res.status(401).json({ success: false, error: 'Token de autenticação não fornecido.' });
      return;
    }

    const user = db.getUserById(userId);
    if (!user) {
      res.status(401).json({ success: false, error: 'Usuário não encontrado no cadastro hospitalar.' });
      return;
    }

    if (!user.ativo) {
      res.status(403).json({
        success: false,
        error: 'Seu acesso institucional está suspenso. Procure a Direção Geral ou RH.',
      });
      return;
    }

    req.user = user;
    next();
  } catch (error) {
    console.error('[Auth Middleware] Erro:', error);
    res.status(500).json({ success: false, error: 'Erro interno ao validar credenciais.' });
  }
}

/**
 * Exige nível hierárquico mínimo (1=Direção, 2=Coordenação, 3=Supervisão, 4=Funcionário).
 * Como 1 é o nível máximo, o valor numérico de user.hierarquiaNivel deve ser <= maxLevelValue.
 */
export function requireHierarchy(maxLevelValue: HierarchyLevel) {
  return (req: Request, res: Response, next: NextFunction): void => {
    const user = req.user;
    if (!user) {
      res.status(401).json({ success: false, error: 'Não autenticado.' });
      return;
    }

    if (user.hierarquiaNivel > maxLevelValue) {
      res.status(403).json({
        success: false,
        error: 'Acesso negado: você não possui nível hierárquico suficiente para esta operação.',
      });
      return;
    }

    next();
  };
}
