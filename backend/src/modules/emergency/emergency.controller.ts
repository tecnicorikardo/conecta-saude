import { Request, Response } from 'express';
import { prisma } from '../../config/database';
import { HierarquiaNivel } from '../../types';
import { AppError } from '../../middleware/errorHandler';
import { auditLog } from '../../utils/auditLogger';
import { getFirebaseMessaging } from '../../config/firebase';
import { createEmergencySchema, resolveEmergencySchema } from './emergency.schema';

/**
 * GET /api/emergency/active
 * Retorna o chamado de emergência ativo no momento (se houver).
 */
export async function getActiveEmergency(_req: Request, res: Response): Promise<void> {
  const alert = await prisma.emergencyAlert.findFirst({
    where: { status: 'ativo' },
    orderBy: { criadoEm: 'desc' },
    include: {
      criador: {
        select: {
          id: true,
          nome: true,
          cargo: true,
          fotoUrl: true,
          hierarquiaNivel: true,
          setor: { select: { nome: true } },
        },
      },
      setor: { select: { id: true, nome: true } },
    },
  });

  res.json({
    success: true,
    data: alert
      ? {
          id: alert.id,
          tipo: alert.tipo,
          titulo: alert.titulo,
          descricao: alert.descricao,
          localizacao: alert.localizacao,
          status: alert.status,
          criadoEm: alert.criadoEm,
          criador: {
            id: alert.criador.id,
            nome: alert.criador.nome,
            cargo: alert.criador.cargo,
            fotoUrl: alert.criador.fotoUrl,
            setorNome: alert.criador.setor?.nome ?? '',
          },
        }
      : null,
  });
}

/**
 * POST /api/emergency
 * Dispara um novo chamado de emergência / Protocolo Vermelho.
 * Qualquer servidor de plantão pode acionar para resposta rápida.
 */
export async function createEmergencyAlert(req: Request, res: Response): Promise<void> {
  const actor = req.user!;
  const data = createEmergencySchema.parse(req.body);

  const alert = await prisma.emergencyAlert.create({
    data: {
      tipo: data.tipo,
      titulo: data.titulo,
      descricao: data.descricao ?? null,
      localizacao: data.localizacao,
      setorId: actor.setorId,
      criadoPor: actor.id,
      status: 'ativo',
    },
    include: {
      criador: {
        select: {
          id: true,
          nome: true,
          cargo: true,
          fotoUrl: true,
          hierarquiaNivel: true,
          setor: { select: { nome: true } },
        },
      },
    },
  });

  await auditLog({
    userId: actor.id,
    acao: 'disparar_alerta_emergencia',
    entidade: 'emergency_alert',
    entidadeId: alert.id,
    detalhes: { tipo: data.tipo, localizacao: data.localizacao },
    req,
  });

  // Retornar resposta HTTP 201 imediatamente
  res.status(201).json({
    success: true,
    message: 'Alerta de emergência emitido com sucesso.',
    data: {
      id: alert.id,
      tipo: alert.tipo,
      titulo: alert.titulo,
      descricao: alert.descricao,
      localizacao: alert.localizacao,
      status: alert.status,
      criadoEm: alert.criadoEm,
      criador: {
        id: alert.criador.id,
        nome: alert.criador.nome,
        cargo: alert.criador.cargo,
        fotoUrl: alert.criador.fotoUrl,
        setorNome: alert.criador.setor?.nome ?? '',
      },
    },
  });

  // Disparar Notificação Push de Emergência para TODOS os servidores com token em background
  setImmediate(async () => {
    try {
      const allUsers = await prisma.user.findMany({
        where: {
          ativo: true,
          id: { not: actor.id },
          fcmToken: { not: null },
        },
        select: { fcmToken: true },
      });

      const targetTokens = allUsers
        .map((u) => u.fcmToken)
        .filter((t): t is string => Boolean(t && t.trim().length > 0));

      if (targetTokens.length > 0) {
        const messaging = getFirebaseMessaging();
        const pushTitle = `🚨 ALERTA: ${alert.titulo}`;
        const pushBody = `${alert.tipo.toUpperCase()} em ${alert.localizacao} (por ${actor.nome})`;

        await messaging.sendEachForMulticast({
          tokens: targetTokens,
          notification: {
            title: pushTitle,
            body: pushBody,
          },
          data: {
            type: 'emergency_alert',
            alertId: alert.id,
            localizacao: alert.localizacao,
          },
          webpush: {
            fcmOptions: {
              link: `https://conecta-hospital.web.app/emergency`,
            },
            notification: {
              title: pushTitle,
              body: pushBody,
              icon: 'https://conecta-hospital.web.app/icons/Icon-192.png',
              badge: 'https://conecta-hospital.web.app/icons/Icon-192.png',
              requireInteraction: true,
              tag: 'emergency_alert',
            },
          },
        });
        console.log(`[FCM Push] Alerta de emergência enviado para ${targetTokens.length} dispositivo(s).`);
      }
    } catch (pushErr) {
      console.warn('[FCM Push] Falha ao enviar push de emergência:', pushErr);
    }
  });
}

/**
 * PATCH /api/emergency/:id/resolve
 * Encerra o chamado e finaliza o protocolo de emergência.
 * Permitido para quem criou o chamado, Coordenação e Direção Geral.
 */
export async function resolveEmergencyAlert(req: Request, res: Response): Promise<void> {
  const actor = req.user!;
  const { id } = req.params;
  const data = resolveEmergencySchema.parse(req.body ?? {});

  const existing = await prisma.emergencyAlert.findUnique({ where: { id } });
  if (!existing) {
    throw new AppError('Chamado de emergência não encontrado.', 404);
  }

  // Coordenação, Direção ou o criador do chamado podem encerrar o protocolo
  if (
    actor.hierarquiaNivel > HierarquiaNivel.COORDENACAO &&
    existing.criadoPor !== actor.id
  ) {
    throw new AppError(
      'Apenas quem criou o alerta, a Coordenação ou a Direção têm permissão para encerrar o chamado.',
      403,
    );
  }

  const updated = await prisma.emergencyAlert.update({
    where: { id },
    data: {
      status: 'resolvido',
      descricao: data.observacao ? `${existing.descricao ?? ''}\n[Resolução: ${data.observacao}]`.trim() : existing.descricao,
      resolvidoEm: new Date(),
      resolvidoPor: actor.id,
    },
    include: {
      criador: {
        select: {
          id: true,
          nome: true,
          cargo: true,
          setor: { select: { nome: true } },
        },
      },
      resolvido: {
        select: {
          id: true,
          nome: true,
          cargo: true,
        },
      },
    },
  });

  await auditLog({
    userId: actor.id,
    acao: 'encerrar_alerta_emergencia',
    entidade: 'emergency_alert',
    entidadeId: id,
    req,
  });

  res.json({
    success: true,
    message: 'Protocolo de emergência encerrado com sucesso.',
    data: {
      id: updated.id,
      tipo: updated.tipo,
      titulo: updated.titulo,
      localizacao: updated.localizacao,
      status: updated.status,
      criadoEm: updated.criadoEm,
      resolvidoEm: updated.resolvidoEm,
      resolvidoPorNome: updated.resolvido?.nome ?? null,
    },
  });
}

/**
 * GET /api/emergency/history
 * Lista histórico de ocorrências de emergência.
 */
export async function listEmergencyHistory(req: Request, res: Response): Promise<void> {
  const page = Number(req.query.page ?? 1);
  const limit = Number(req.query.limit ?? 20);
  const skip = (page - 1) * limit;

  const [items, total] = await Promise.all([
    prisma.emergencyAlert.findMany({
      orderBy: { criadoEm: 'desc' },
      skip,
      take: limit,
      include: {
        criador: {
          select: {
            id: true,
            nome: true,
            cargo: true,
            fotoUrl: true,
            setor: { select: { nome: true } },
          },
        },
        resolvido: {
          select: {
            id: true,
            nome: true,
            cargo: true,
          },
        },
      },
    }),
    prisma.emergencyAlert.count(),
  ]);

  res.json({
    success: true,
    data: {
      items: items.map((a) => ({
        id: a.id,
        tipo: a.tipo,
        titulo: a.titulo,
        descricao: a.descricao,
        localizacao: a.localizacao,
        status: a.status,
        criadoEm: a.criadoEm,
        resolvidoEm: a.resolvidoEm,
        criadorNome: a.criador.nome,
        criadorCargo: a.criador.cargo,
        criadorSetor: a.criador.setor?.nome ?? '',
        resolvidoPorNome: a.resolvido?.nome ?? null,
      })),
      total,
      hasMore: skip + items.length < total,
    },
  });
}
