import { Router } from 'express';
import { authenticate, requireHierarquia } from '../../middleware/authenticate';
import { HierarquiaNivel } from '../../types';
import { asyncHandler } from '../../utils/asyncHandler';
import {
  listChannels,
  listAllChannels,
  createChannel,
  addMember,
  removeMember,
  getChannel,
  listChannelMessages,
  postChannelMessage,
  getMessageReaders,
} from './channels.controller';

const router = Router();
router.use(authenticate);

router.get('/', asyncHandler(listChannels));           // meus canais
router.get('/all', asyncHandler(listAllChannels));     // todos (admin)
router.post('/', requireHierarquia(HierarquiaNivel.COORDENACAO), asyncHandler(createChannel));
router.get('/:id', asyncHandler(getChannel));
router.post('/:id/members', asyncHandler(addMember));
router.delete('/:id/members/:userId', asyncHandler(removeMember));

// Mensagens de canais
router.get('/:id/messages', asyncHandler(listChannelMessages));
router.post(
  '/:id/messages',
  requireHierarquia(HierarquiaNivel.COORDENACAO),
  asyncHandler(postChannelMessage)
);
router.get(
  '/:id/messages/:messageId/reads',
  requireHierarquia(HierarquiaNivel.COORDENACAO),
  asyncHandler(getMessageReaders)
);

export default router;
