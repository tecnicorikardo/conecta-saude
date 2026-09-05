import { z } from 'zod';

export const sendMessageSchema = z.object({
  texto: z
    .string()
    .min(1, 'A mensagem não pode estar vazia.')
    .max(4000, 'Mensagem muito longa (máximo 4000 caracteres).'),
});

export const editMessageSchema = z.object({
  texto: z
    .string()
    .min(1, 'A mensagem não pode estar vazia.')
    .max(4000, 'Mensagem muito longa.'),
});

export const listMessagesSchema = z.object({
  cursor: z.string().optional(),
  limit: z.coerce.number().int().min(1).max(100).default(50),
});
