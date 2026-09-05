import { z } from 'zod';

export const verifyTokenSchema = z.object({
  idToken: z.string().min(1, 'ID Token é obrigatório.'),
  fcmToken: z.string().optional(),
});

export const updateFcmTokenSchema = z.object({
  fcmToken: z.string().min(1, 'FCM token é obrigatório.'),
});
