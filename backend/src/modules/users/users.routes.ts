import { Router } from 'express';
import { authenticate } from '../../middleware/authenticate';
import { asyncHandler } from '../../utils/asyncHandler';
import {
  listUsers,
  getUser,
  createUser,
  updateUser,
  updateUserStatus,
} from './users.controller';

const router = Router();

router.use(authenticate);

router.get('/', asyncHandler(listUsers));
router.get('/:id', asyncHandler(getUser));
router.post('/', asyncHandler(createUser));
router.put('/:id', asyncHandler(updateUser));
router.patch('/:id/status', asyncHandler(updateUserStatus));

export default router;
