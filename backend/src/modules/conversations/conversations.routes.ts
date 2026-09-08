import { Router } from 'express';
import { authenticate } from '../../middleware/authenticate';
import { asyncHandler } from '../../utils/asyncHandler';
import {
  listConversations,
  getConversation,
  createConversation,
  updateConversation,
  addMembers,
  removeMember,
  updateMemberRole,
  deleteConversation,
  listMessages,
  sendMessage,
} from './conversations.controller';

const router = Router();
router.use(authenticate);

router.get('/', asyncHandler(listConversations));
router.post('/', asyncHandler(createConversation));
router.get('/:id', asyncHandler(getConversation));
router.patch('/:id', asyncHandler(updateConversation));
router.delete('/:id', asyncHandler(deleteConversation));

router.post('/:id/members', asyncHandler(addMembers));
router.delete('/:id/members/:userId', asyncHandler(removeMember));
router.patch('/:id/members/:userId/role', asyncHandler(updateMemberRole));

router.get('/:id/messages', asyncHandler(listMessages));
router.post('/:id/messages', asyncHandler(sendMessage));

export default router;
