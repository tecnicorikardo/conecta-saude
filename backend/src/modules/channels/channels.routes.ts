import { Router } from 'express';
import { authenticate, requireHierarquia } from '../../middleware/authenticate';
import { HierarquiaNivel } from '../../types';
import { asyncHandler } from '../../utils/asyncHandler';
import {
  listChannels,
  listAllChannels,
  createChannel,
  deleteChannel,
  addMember,
  removeMember,
  getChannel,
  listChannelMessages,
  postChannelMessage,
  getMessageReaders,
} from './channels.controller';

const router = Router();
// Todas as rotas abaixo exigem identidade válida. authenticate consulta o perfil
// atual no banco; permissões mostradas no aplicativo não substituem essa etapa.
router.use(authenticate);

router.get('/', asyncHandler(listChannels));           // meus canais
router.get('/all', asyncHandler(listAllChannels));     // todos (admin)
// A ordem importa: primeiro autorizar níveis 1, 2 e 3; depois validar e gravar.
// asyncHandler encaminha falhas assíncronas ao tratamento central de erros.
router.post('/', requireHierarquia(HierarquiaNivel.SUPERVISAO), asyncHandler(createChannel));
router.get('/:id', asyncHandler(getChannel));
// Não restringir por nível: um autor de qualquer nível pode excluir seu canal.
router.delete('/:id', asyncHandler(deleteChannel));
router.post('/:id/members', asyncHandler(addMember));
router.delete('/:id/members/:userId', asyncHandler(removeMember));

// Mensagens de canais
router.get('/:id/messages', asyncHandler(listChannelMessages));
router.post(
  '/:id/messages',
  requireHierarquia(HierarquiaNivel.SUPERVISAO),
  asyncHandler(postChannelMessage)
);
router.get(
  '/:id/messages/:messageId/reads',
  requireHierarquia(HierarquiaNivel.SUPERVISAO),
  asyncHandler(getMessageReaders)
);

export default router;
