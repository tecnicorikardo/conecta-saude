import { z } from 'zod';

export const verifyTokenSchema = z.object({
  idToken: z.string().min(1, 'ID Token é obrigatório.'),
  fcmToken: z.string().optional(),
});

export const updateFcmTokenSchema = z.object({
  fcmToken: z.string().min(1, 'FCM token é obrigatório.'),
});

export const registerUserSchema = z.object({
  nome: z.string().min(2, 'Nome deve ter pelo menos 2 caracteres.').max(100),
  email: z.string().email('E-mail inválido.').toLowerCase(),
  password: z.string().min(6, 'Senha deve ter pelo menos 6 caracteres.'),
  setorId: z.string().uuid('Selecione um setor válido.'),
  cargo: z.string().min(2, 'Informe seu cargo.').max(80),
  matricula: z.string().max(50).optional().nullable(),
});

