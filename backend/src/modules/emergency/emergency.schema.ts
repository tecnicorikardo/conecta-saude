import { z } from 'zod';

export const createEmergencySchema = z.object({
  tipo: z.enum(['pcr', 'o2_energia', 'trauma', 'seguranca', 'geral']).default('geral'),
  titulo: z.string().min(3, 'Título deve ter ao menos 3 caracteres.').max(120),
  descricao: z.string().max(1000).optional(),
  localizacao: z.string().min(2, 'Informe o local exato da ocorrência.').max(120),
});

export const resolveEmergencySchema = z.object({
  observacao: z.string().max(500).optional(),
});
