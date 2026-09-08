import { describe, it, expect } from 'vitest';
import { createEmergencySchema, resolveEmergencySchema } from '../modules/emergency/emergency.schema';

describe('Validação de Alertas de Emergência (Pente Fino)', () => {
  it('deve validar um alerta de PCR com localização obrigatória', () => {
    const valid = {
      tipo: 'pcr',
      titulo: 'Parada cardiorrespiratória',
      localizacao: 'Box 02 - Triagem do CCO',
      descricao: 'Paciente masculino, 64 anos, necessita de suporte imediato.',
    };
    const parsed = createEmergencySchema.safeParse(valid);
    expect(parsed.success).toBe(true);
  });

  it('deve rejeitar alerta sem localização exata da ocorrência', () => {
    const invalid = {
      tipo: 'pcr',
      titulo: 'Emergência crítica',
      localizacao: '', // Vazio
    };
    const parsed = createEmergencySchema.safeParse(invalid);
    expect(parsed.success).toBe(false);
  });

  it('deve rejeitar tipo de emergência inválido', () => {
    const invalidType = {
      tipo: 'tipo_inexistente',
      titulo: 'Alerta sem tipo padrão',
      localizacao: 'Setor 1',
    };
    const parsed = createEmergencySchema.safeParse(invalidType);
    expect(parsed.success).toBe(false);
  });

  it('deve aceitar resolução de emergência com observação', () => {
    const resolve = {
      observacao: 'Equipe de plantão atendeu o paciente. Situação normalizada.',
    };
    const parsed = resolveEmergencySchema.safeParse(resolve);
    expect(parsed.success).toBe(true);
  });
});
