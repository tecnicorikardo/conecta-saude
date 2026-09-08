import { describe, it, expect } from 'vitest';
import { sendMessageSchema, editMessageSchema } from '../modules/messages/messages.schema';

describe('Validação de Mensagens e Áudio (Pente Fino)', () => {
  it('deve aceitar mensagem de texto padrão institucional', () => {
    const input = { texto: 'Paciente transferido para a enfermaria 3.' };
    const parsed = sendMessageSchema.safeParse(input);
    expect(parsed.success).toBe(true);
    if (parsed.success) {
      expect(parsed.data.texto).toBe(input.texto);
    }
  });

  it('deve aceitar gravação de áudio de voz em Base64 (> 20.000 caracteres)', () => {
    // Simula áudio de voz gravado em Base64 (~35KB)
    const base64Audio = '[audio:12]data:audio/webm;base64,' + 'A'.repeat(35000);
    const parsed = sendMessageSchema.safeParse({ texto: base64Audio });
    expect(parsed.success).toBe(true);
    if (parsed.success) {
      expect(parsed.data.texto.length).toBeGreaterThan(20000);
    }
  });

  it('deve aceitar áudios longos de até 5MB sem estourar o limite de caracteres', () => {
    const hugeAudio = '[audio:120]data:audio/webm;base64,' + 'X'.repeat(5_000_000);
    const parsed = sendMessageSchema.safeParse({ texto: hugeAudio });
    expect(parsed.success).toBe(true);
  });

  it('deve rejeitar mensagens vazias', () => {
    const emptyInput = { texto: '' };
    const parsed = sendMessageSchema.safeParse(emptyInput);
    expect(parsed.success).toBe(false);
  });

  it('deve validar edição de mensagens com suporte a alterações válidas', () => {
    const editInput = { texto: 'Texto corrigido pelo supervisor.' };
    const parsed = editMessageSchema.safeParse(editInput);
    expect(parsed.success).toBe(true);
  });

  it('deve rejeitar edição de mensagem com texto vazio', () => {
    const emptyEdit = { texto: '' };
    const parsed = editMessageSchema.safeParse(emptyEdit);
    expect(parsed.success).toBe(false);
  });
});
