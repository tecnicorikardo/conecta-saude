import { Request } from 'express';
import { prisma } from '../config/database';

interface AuditLogParams {
  userId: string;
  acao: string;
  entidade: string;
  entidadeId?: string;
  detalhes?: Record<string, unknown>;
  req?: Request;
}

/**
 * Registra uma ação administrativa no audit_log.
 * Nunca registra senhas, tokens ou dados sensíveis.
 */
export async function auditLog({
  userId,
  acao,
  entidade,
  entidadeId,
  detalhes,
  req,
}: AuditLogParams): Promise<void> {
  try {
    await prisma.auditLog.create({
      data: {
        userId,
        acao,
        entidade,
        entidadeId,
        detalhes: detalhes ? JSON.stringify(detalhes) : null,
        ip: req ? getClientIp(req) : null,
        userAgent: req?.headers['user-agent'] ?? null,
      },
    });
  } catch (error) {
    // Falha na auditoria nunca deve derrubar a operação principal
    console.error('[AuditLog] Falha ao registrar:', error);
  }
}

function getClientIp(req: Request): string {
  const forwarded = req.headers['x-forwarded-for'];
  if (typeof forwarded === 'string') {
    return forwarded.split(',')[0].trim();
  }
  return req.socket.remoteAddress ?? 'unknown';
}
