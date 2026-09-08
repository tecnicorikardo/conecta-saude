import { describe, it, expect } from 'vitest';
import { HierarquiaNivel } from '../types';

describe('Matriz de Permissões e Hierarquia do SUS (Pente Fino)', () => {
  function canManageAnnouncements(nivel: HierarquiaNivel): boolean {
    // Apenas Direção (1) e Coordenação (2)
    return nivel <= HierarquiaNivel.COORDENACAO;
  }

  function canManageEmployees(nivel: HierarquiaNivel): boolean {
    // Apenas Direção (1) e Coordenação (2)
    return nivel <= HierarquiaNivel.COORDENACAO;
  }

  function canBroadcastEmergency(nivel: HierarquiaNivel): boolean {
    // Qualquer servidor ativo pode acionar emergência
    return nivel <= HierarquiaNivel.FUNCIONARIO;
  }

  function canViewColleagueProfile(isAuthenticated: boolean): boolean {
    // Qualquer servidor autenticado no SUS pode visualizar dados do colega
    return isAuthenticated;
  }

  it('Direção Geral (Nível 1) deve ter acesso total a comunicados e colaboradores', () => {
    expect(canManageAnnouncements(HierarquiaNivel.DIRECAO)).toBe(true);
    expect(canManageEmployees(HierarquiaNivel.DIRECAO)).toBe(true);
  });

  it('Coordenação do CCO (Nível 2) deve poder publicar comunicados oficiais', () => {
    expect(canManageAnnouncements(HierarquiaNivel.COORDENACAO)).toBe(true);
    expect(canManageEmployees(HierarquiaNivel.COORDENACAO)).toBe(true);
  });

  it('Supervisão (Nível 3) NÃO deve poder publicar comunicados institucionais', () => {
    expect(canManageAnnouncements(HierarquiaNivel.SUPERVISAO)).toBe(false);
    expect(canManageEmployees(HierarquiaNivel.SUPERVISAO)).toBe(false);
  });

  it('Funcionário operacional (Nível 4 - Maqueiros/Técnicos) NÃO deve poder publicar comunicados nem gerenciar funcionários', () => {
    expect(canManageAnnouncements(HierarquiaNivel.FUNCIONARIO)).toBe(false);
    expect(canManageEmployees(HierarquiaNivel.FUNCIONARIO)).toBe(false);
  });

  it('Funcionário operacional (Nível 4) DEVE poder acionar emergências e visualizar perfis de colegas', () => {
    expect(canBroadcastEmergency(HierarquiaNivel.FUNCIONARIO)).toBe(true);
    expect(canViewColleagueProfile(true)).toBe(true);
  });
});
