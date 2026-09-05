import { Router } from 'express';
import { authenticate } from '../../middleware/authenticate';
import { asyncHandler } from '../../utils/asyncHandler';
import {
  listConversations,
  createConversation,
  listMessages,
  sendMessage,
} from './conversations.controller';

const router = Router();
router.use(authenticate);

router.get('/', asyncHandler(listConversations));
router.post('/', asyncHandler(createConversation));
router.get('/:id/messages', asyncHandler(listMessages));
router.post('/:id/messages', asyncHandler(sendMessage));

export default router;
