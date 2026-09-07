import { z } from 'zod';

export const createUserSchema = z.object({
  nome: z.string().min(2, 'Nome deve ter ao menos 2 caracteres.').max(120),
  email: z.string().email('E-mail inválido.'),
  password: z.string().min(8, 'Senha deve ter ao menos 8 caracteres.'),
  cargo: z.string().min(2).max(80),
  hierarquiaNivel: z.number().int().min(1).max(4),
  setorId: z.string().uuid('Setor inválido.'),
  fotoUrl: z.string().url().optional(),
});

export const updateUserSchema = z.object({
  nome: z.string().min(2).max(120).optional(),
  cargo: z.string().min(2).max(80).optional(),
  matricula: z.string().nullable().optional(),
  hierarquiaNivel: z.number().int().min(1).max(4).optional(),
  setorId: z.string().uuid().optional(),
  fotoUrl: z.string().nullable().optional(),
});

export const updateUserStatusSchema = z.object({
  ativo: z.boolean(),
});

export const listUsersSchema = z.object({
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(100).default(30),
  search: z.string().optional(),
  setorId: z.string().uuid().optional(),
  hierarquiaNivel: z.coerce.number().int().min(1).max(4).optional(),
  ativo: z.enum(['true', 'false']).optional(),
  excludeSelf: z.enum(['true', 'false']).optional(),
});
