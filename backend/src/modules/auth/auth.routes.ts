import { Router } from 'express';
import { authenticate } from '../../middleware/authenticate';
import { asyncHandler } from '../../utils/asyncHandler';
import { verifyToken, getMe, updateFcmToken, registerUser, testPush, testPushTyped, logoutUser } from './auth.controller';

const router = Router();
// Router reúne endereços relativos: app.ts adiciona o prefixo /api/auth.
// POST recebe dados; GET consulta; PATCH atualiza parte de um cadastro.

// Pública — valida o token Firebase e retorna dados do usuário
router.post('/verify', asyncHandler(verifyToken));
// Pública — auto-cadastro de novos servidores SUS
router.post('/register', asyncHandler(registerUser));

// Protegidas: authenticate identifica a pessoa antes de chamar cada função.
// /me é útil no diagnóstico: mostra o perfil reconhecido pelo servidor agora.
router.get('/me', authenticate, asyncHandler(getMe));
router.post('/logout', authenticate, asyncHandler(logoutUser));
router.patch('/fcm-token', authenticate, asyncHandler(updateFcmToken));
router.post('/test-push', authenticate, asyncHandler(testPush));
router.post('/test-push-typed', authenticate, asyncHandler(testPushTyped));

export default router;
