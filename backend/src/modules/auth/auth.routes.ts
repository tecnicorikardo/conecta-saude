import { Router } from 'express';
import { authenticate } from '../../middleware/authenticate';
import { asyncHandler } from '../../utils/asyncHandler';
import { verifyToken, getMe, updateFcmToken, registerUser, testPush } from './auth.controller';

const router = Router();

// Pública — valida o token Firebase e retorna dados do usuário
router.post('/verify', asyncHandler(verifyToken));
// Pública — auto-cadastro de novos servidores SUS
router.post('/register', asyncHandler(registerUser));

// Protegidas
router.get('/me', authenticate, asyncHandler(getMe));
router.patch('/fcm-token', authenticate, asyncHandler(updateFcmToken));
router.post('/test-push', authenticate, asyncHandler(testPush));

export default router;
