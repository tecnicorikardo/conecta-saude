import { Router } from 'express';
import { authenticate } from '../../middleware/authenticate';
import { asyncHandler } from '../../utils/asyncHandler';
import { editMessage, deleteMessage } from './messages.controller';

const router = Router();

router.use(authenticate);

router.put('/:id', asyncHandler(editMessage));
router.delete('/:id', asyncHandler(deleteMessage));

export default router;
