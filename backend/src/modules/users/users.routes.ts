import { Router } from 'express';
import { authenticate } from '../../middleware/authenticate';
import { asyncHandler } from '../../utils/asyncHandler';
import {
  listUsers,
  getUser,
  createUser,
  updateUser,
  updateUserStatus,
  getPendingUsers,
  approveUser,
  rejectUser,
  updateMySchedule,
} from './users.controller';

const router = Router();

router.use(authenticate);

// Perfil / Escala do próprio usuário
router.patch('/me/schedule', asyncHandler(updateMySchedule));

// Aprovações de Auto-Cadastro
router.get('/pending', asyncHandler(getPendingUsers));
router.patch('/:id/approve', asyncHandler(approveUser));
router.delete('/:id/reject', asyncHandler(rejectUser));

// CRUD Usuários
router.get('/', asyncHandler(listUsers));
router.get('/:id', asyncHandler(getUser));
router.post('/', asyncHandler(createUser));
router.put('/:id', asyncHandler(updateUser));
router.patch('/:id/status', asyncHandler(updateUserStatus));

export default router;
