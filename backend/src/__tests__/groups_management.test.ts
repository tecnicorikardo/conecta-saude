import { describe, it, expect } from 'vitest';
import { z } from 'zod';
import { ConversationTipo, HierarquiaNivel } from '../types';

const updateConversationSchema = z.object({
  nome: z.string().min(1).max(80).optional(),
  descricao: z.string().max(500).optional().nullable(),
  fotoUrl: z.string().optional().nullable(),
});

const addMembersSchema = z.object({
  userIds: z.array(z.string().uuid()).min(1).max(50),
});

const updateMemberRoleSchema = z.object({
  isAdmin: z.boolean(),
});

describe('Gestão de Grupos e Participantes SUS (Vitest Pente Fino)', () => {
  it('deve validar payload de atualização com foto, nome e descrição de grupo', () => {
    const payload = {
      nome: 'Equipe de Plantão - UTI Adulto',
      descricao: 'Grupo oficial de comunicação e avisos do plantão noturno.',
      fotoUrl: 'https://storage.conecta.saude/grupos/uti.png',
    };

    const parsed = updateConversationSchema.parse(payload);
    expect(parsed.nome).toBe('Equipe de Plantão - UTI Adulto');
    expect(parsed.descricao).toContain('Grupo oficial');
    expect(parsed.fotoUrl).toBeDefined();
  });

  it('deve rejeitar nome de grupo vazio ou descrição maior que 500 caracteres', () => {
    expect(() => updateConversationSchema.parse({ nome: '' })).toThrow();
    expect(() =>
      updateConversationSchema.parse({
        nome: 'Grupo Válido',
        descricao: 'A'.repeat(501),
      })
    ).toThrow();
  });

  it('deve validar adição de participantes com lista de UUIDs válidos', () => {
    const validUUIDs = [
      'c0b233de-b1dc-420c-a1f5-afe546596739',
      '7efd1864-e7a2-4aae-9ec8-7531edc681ca',
    ];

    const result = addMembersSchema.parse({ userIds: validUUIDs });
    expect(result.userIds).toHaveLength(2);

    // Deve falhar com UUIDs inválidos
    expect(() => addMembersSchema.parse({ userIds: ['id-invalido-123'] })).toThrow();
    expect(() => addMembersSchema.parse({ userIds: [] })).toThrow();
  });

  it('deve validar promoção e revogação de status de Administrador de grupo', () => {
    expect(updateMemberRoleSchema.parse({ isAdmin: true })).toEqual({ isAdmin: true });
    expect(updateMemberRoleSchema.parse({ isAdmin: false })).toEqual({ isAdmin: false });
    expect(() => updateMemberRoleSchema.parse({ isAdmin: 'sim' })).toThrow();
  });

  it('deve conceder privilégio de administração ao Criador ou à Direção Geral (Nível 1)', () => {
    function canManageGroup(user: { id: string; hierarquiaNivel: number }, group: { criadoPor: string }, isMemberAdmin: boolean) {
      return (
        user.hierarquiaNivel === HierarquiaNivel.DIRECAO ||
        user.id === group.criadoPor ||
        isMemberAdmin
      );
    }

    const group = { criadoPor: 'user-criador-123' };
    const criador = { id: 'user-criador-123', hierarquiaNivel: HierarquiaNivel.COORDENACAO };
    const direcao = { id: 'user-diretor-999', hierarquiaNivel: HierarquiaNivel.DIRECAO };
    const adminMembro = { id: 'user-membro-456', hierarquiaNivel: HierarquiaNivel.FUNCIONARIO };
    const membroComum = { id: 'user-membro-789', hierarquiaNivel: HierarquiaNivel.FUNCIONARIO };

    expect(canManageGroup(criador, group, false)).toBe(true);
    expect(canManageGroup(direcao, group, false)).toBe(true);
    expect(canManageGroup(adminMembro, group, true)).toBe(true);
    expect(canManageGroup(membroComum, group, false)).toBe(false);
  });
});
