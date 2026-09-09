import { Request, Response } from 'express';
import { prisma } from '../../config/database';
import { HierarquiaNivel } from '../../types';
import { AppError } from '../../middleware/errorHandler';
import { auditLog } from '../../utils/auditLogger';
import { AppConstants } from '../../utils/constants';
import { getFirebaseMessaging } from '../../config/firebase';
import { notifyConversation } from '../../realtime';
import {
  sendMessageSchema,
  editMessageSchema,
  listMessagesSchema,
} from './messages.schema';

/**
 * GET /api/conversations/:id/messages
 * Lista mensagens de uma conversa com cursor-based pagination.
 */
export async function listMessages(req: Request, res: Response): Promise<void> {
  const actor = req.user!;
  const { id: conversationId } = req.params;
  const query = listMessagesSchema.parse(req.query);

  // Verificar participação
  const membership = await prisma.conversationMember.findUnique({
    where: {
      conversationId_userId: { conversationId, userId: actor.id },
    },
  });
  if (!membership) throw new AppError('Você não participa desta conversa.', 403);

  const messages = await prisma.message.findMany({
    where: {
      conversationId,
      ...(query.cursor && { id: { lt: query.cursor } }),
    },
    orderBy: { criadoEm: 'desc' },
    take: query.limit,
    include: {
      remetente: {
        select: { id: true, nome: true, fotoUrl: true, cargo: true },
      },
      reads: {
        select: { userId: true, lidoEm: true },
      },
    },
  });

  // Marcar como lido as não lidas pelo usuário atual
  const unreadIds = messages
    .filter((m) => !m.reads.some((r) => r.userId === actor.id) && m.remetenteId !== actor.id)
    .map((m) => m.id);

  if (unreadIds.length > 0) {
    await prisma.messageRead.createMany({
      data: unreadIds.map((messageId) => ({
        messageId,
        userId: actor.id,
      })),
      skipDuplicates: true,
    });
    notifyConversation(conversationId);
  }

  res.json({
    success: true,
    data: {
      items: messages.reverse().map((m) => ({
        id: m.id,
        texto: m.excluido ? null : m.texto,
        excluido: m.excluido,
        editado: m.editado,
        criadoEm: m.criadoEm,
        editadoEm: m.editadoEm,
        remetente: m.remetente,
        lido: m.reads.some((r) => r.userId !== m.remetenteId),
      })),
      hasMore: messages.length === query.limit,
      nextCursor: messages.length > 0 ? messages[0].id : null,
    },
  });
}

/**
 * POST /api/conversations/:id/messages
 * Envia uma mensagem.
 */
export async function sendMessage(req: Request, res: Response): Promise<void> {
  const actor = req.user!;
  const { id: conversationId } = req.params;
  const { texto, clientMessageId } = sendMessageSchema.parse(req.body);

  // Verificar participação
  const membership = await prisma.conversationMember.findUnique({
    where: {
      conversationId_userId: { conversationId, userId: actor.id },
    },
  });
  if (!membership) throw new AppError('Você não participa desta conversa.', 403);

  const messageData = {
    data: {
      conversationId,
      remetenteId: actor.id,
      texto,
    },
    include: {
      remetente: {
        select: { id: true, nome: true, fotoUrl: true, cargo: true },
      },
    },
  };
  const message = clientMessageId
    ? await prisma.message.upsert({
        where: { id: clientMessageId },
        create: { ...messageData.data, id: clientMessageId },
        update: {},
        include: messageData.include,
      })
    : await prisma.message.create(messageData);
  if (message.remetenteId !== actor.id || message.conversationId !== conversationId || message.texto !== texto) {
    throw new AppError('Identificador de mensagem já utilizado.', 409);
  }


  // Atualizar timestamp da conversa
  await prisma.conversation.update({
    where: { id: conversationId },
    data: { atualizadoEm: new Date() },
  });

  // Retornar resposta HTTP 201 imediatamente (envio instantâneo)
  notifyConversation(conversationId);
  res.status(201).json({
    success: true,
    data: {
      id: message.id,
      texto: message.texto,
      criadoEm: message.criadoEm,
      remetente: message.remetente,
    },
  });

  // Disparar Web Push Notification via Firebase Cloud Messaging em background assíncrono
  setImmediate(async () => {
    try {
      const recipientMembers = await prisma.conversationMember.findMany({
        where: {
          conversationId,
          userId: { not: actor.id },
        },
        include: {
          user: {
            select: {
              id: true,
              nome: true,
              fcmToken: true,
            },
          },
        },
      });

      const targetTokens = recipientMembers
        .map((m) => m.user.fcmToken)
        .filter((token): token is string => Boolean(token && token.trim().length > 0));

      if (targetTokens.length > 0) {
        const messaging = getFirebaseMessaging();
        const senderName = actor.nome || 'Novo recado';
        const isAudio = texto.startsWith('[audio');
        const previewText = isAudio
          ? '🎙️ Mensagem de áudio'
          : (texto.length > 100 ? `${texto.substring(0, 97)}...` : texto);

        const pushResult = await messaging.sendEachForMulticast({
          tokens: targetTokens,
          notification: {
            title: senderName,
            body: previewText,
          },
          data: {
            type: 'chat_message',
            conversationId,
            senderId: actor.id,
            senderName,
            messageId: message.id,
          },
          webpush: {
            fcmOptions: {
              link: `https://conecta-hospital.web.app/chat/${conversationId}`,
            },
            notification: {
              title: senderName,
              body: previewText,
              icon: 'https://conecta-hospital.web.app/icons/Icon-192.png',
              badge: 'https://conecta-hospital.web.app/icons/Icon-192.png',
              tag: `chat_${conversationId}`,
              renotify: true,
            },
          },
        });
        console.log(`[FCM Push] Mensagem enviada para ${targetTokens.length} dispositivo(s). Sucesso: ${pushResult.successCount}, Falhas: ${pushResult.failureCount}`);
        if (pushResult.failureCount > 0) {
          pushResult.responses.forEach((resp, idx) => {
            if (!resp.success) {
              console.error(`[FCM Push Erro] Destinatário token ${idx}:`, resp.error);
            }
          });
        }
      }
    } catch (pushErr) {
      console.error('[FCM Push] Erro fatal ao disparar notificação push:', pushErr);
    }
  });
}

/**
 * PUT /api/messages/:id
 * Edita uma mensagem dentro da janela de edição configurada.
 */
export async function editMessage(req: Request, res: Response): Promise<void> {
  const actor = req.user!;
  const { id } = req.params;
  const { texto } = editMessageSchema.parse(req.body);

  const message = await prisma.message.findUnique({ where: { id } });
  if (!message) throw new AppError('Mensagem não encontrada.', 404);
  if (message.excluido) throw new AppError('Não é possível editar uma mensagem excluída.', 400);

  // Somente o remetente pode editar
  if (message.remetenteId !== actor.id) {
    throw new AppError('Você só pode editar suas próprias mensagens.', 403);
  }

  // Verificar janela de edição
  const diffMinutes =
    (Date.now() - message.criadoEm.getTime()) / 1000 / 60;
  if (diffMinutes > AppConstants.MESSAGE_EDIT_WINDOW_MINUTES) {
    throw new AppError(
      `Mensagens só podem ser editadas nos primeiros ${AppConstants.MESSAGE_EDIT_WINDOW_MINUTES} minutos.`,
      400,
    );
  }

  const updated = await prisma.message.update({
    where: { id },
    data: { texto, editado: true, editadoEm: new Date() },
  });
  notifyConversation(message.conversationId);

  res.json({
    success: true,
    data: {
      id: updated.id,
      texto: updated.texto,
      editado: updated.editado,
      editadoEm: updated.editadoEm,
    },
  });
}

/**
 * DELETE /api/messages/:id
 * Exclusão lógica (soft delete).
 * Usuário comum: somente suas mensagens.
 * Direção: qualquer mensagem (moderação).
 */
export async function deleteMessage(req: Request, res: Response): Promise<void> {
  const actor = req.user!;
  const { id } = req.params;

  const message = await prisma.message.findUnique({ where: { id } });
  if (!message) throw new AppError('Mensagem não encontrada.', 404);
  if (message.excluido) throw new AppError('Mensagem já foi excluída.', 400);

  const isDirecao = actor.hierarquiaNivel === HierarquiaNivel.DIRECAO;
  const isOwner = message.remetenteId === actor.id;

  if (!isOwner && !isDirecao) {
    throw new AppError('Você só pode excluir suas próprias mensagens.', 403);
  }

  await prisma.message.update({
    where: { id },
    data: { excluido: true, excluidoEm: new Date() },
  });
  notifyConversation(message.conversationId);

  // Registrar auditoria se for moderação administrativa
  if (isDirecao && !isOwner) {
    await auditLog({
      userId: actor.id,
      acao: 'excluir_mensagem_moderacao',
      entidade: 'message',
      entidadeId: id,
      req,
    });
  }

  res.json({ success: true, message: 'Mensagem excluída.' });
}
