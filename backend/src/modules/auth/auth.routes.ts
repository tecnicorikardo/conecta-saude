import { Router } from 'express';
import { authenticate } from '../../middleware/authenticate';
import { asyncHandler } from '../../utils/asyncHandler';
import { verifyToken, getMe, updateFcmToken, registerUser } from './auth.controller';

const router = Router();

// Pública — valida o token Firebase e retorna dados do usuário
router.post('/verify', asyncHandler(verifyToken));
// Pública — auto-cadastro de novos servidores SUS
router.post('/register', asyncHandler(registerUser));

// Protegidas
router.get('/me', authenticate, asyncHandler(getMe));
router.patch('/fcm-token', authenticate, asyncHandler(updateFcmToken));

export default router;
