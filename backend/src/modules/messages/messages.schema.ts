import { z } from 'zod';

export const sendMessageSchema = z.object({
  texto: z
    .string()
    .min(1, 'A mensagem não pode estar vazia.')
    .max(10_000_000, 'Mensagem muito longa.'),
});

export const editMessageSchema = z.object({
  texto: z
    .string()
    .min(1, 'A mensagem não pode estar vazia.')
    .max(10_000_000, 'Mensagem muito longa.'),
});

export const listMessagesSchema = z.object({
  cursor: z.string().optional(),
  limit: z.coerce.number().int().min(1).max(100).default(50),
});
