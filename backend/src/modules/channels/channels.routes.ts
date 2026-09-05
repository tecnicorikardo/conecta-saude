import { Router } from 'express';
import { authenticate } from '../../middleware/authenticate';
import { asyncHandler } from '../../utils/asyncHandler';
import {
  listChannels,
  listAllChannels,
  createChannel,
  addMember,
  removeMember,
  getChannel,
} from './channels.controller';

const router = Router();
router.use(authenticate);

router.get('/', asyncHandler(listChannels));           // meus canais
router.get('/all', asyncHandler(listAllChannels));     // todos (admin)
router.post('/', asyncHandler(createChannel));
router.get('/:id', asyncHandler(getChannel));
router.post('/:id/members', asyncHandler(addMember));
router.delete('/:id/members/:userId', asyncHandler(removeMember));

export default router;
