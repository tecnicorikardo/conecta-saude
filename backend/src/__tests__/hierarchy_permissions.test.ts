import { describe, it, expect } from 'vitest';
import { HierarquiaNivel } from '../types';
import { determineHierarquiaByCargo } from '../modules/auth/auth.controller';

describe('Matriz de Permissões e Hierarquia do SUS (Pente Fino)', () => {
  function canManageAnnouncements(nivel: HierarquiaNivel): boolean {
    // Liderança: Direção (1), Coordenação (2) e Supervisão (3)
    return nivel <= HierarquiaNivel.SUPERVISAO;
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

  it('Supervisão (Nível 3) DEVE poder publicar comunicados e canais, mas NÃO aprovar colaboradores', () => {
    expect(canManageAnnouncements(HierarquiaNivel.SUPERVISAO)).toBe(true);
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

  describe('Auto-atribuição de nível por cargo no cadastro (determineHierarquiaByCargo)', () => {
    it('Cargos de Direção / Coordenação / Chefia de Enfermagem devem receber Nível 2 (COORDENACAO)', () => {
      expect(determineHierarquiaByCargo('Diretor(a) Geral')).toBe(HierarquiaNivel.COORDENACAO);
      expect(determineHierarquiaByCargo('Diretoria Clínica')).toBe(HierarquiaNivel.COORDENACAO);
      expect(determineHierarquiaByCargo('Diretor Administrativo')).toBe(HierarquiaNivel.COORDENACAO);
      expect(determineHierarquiaByCargo('Coordenador(a) de Setor / Unidade')).toBe(HierarquiaNivel.COORDENACAO);
      expect(determineHierarquiaByCargo('Enfermeiro(a) Chefe / Coordenação')).toBe(HierarquiaNivel.COORDENACAO);
      expect(determineHierarquiaByCargo('Chefe de Supervisão e Enfermagem')).toBe(HierarquiaNivel.COORDENACAO);
    });

    it('Cargos de Enfermeiro(a) e Supervisão devem receber Nível 3 (SUPERVISAO)', () => {
      expect(determineHierarquiaByCargo('Enfermeiro(a) Geral')).toBe(HierarquiaNivel.SUPERVISAO);
      expect(determineHierarquiaByCargo('Enfermeiro(a) UTI')).toBe(HierarquiaNivel.SUPERVISAO);
      expect(determineHierarquiaByCargo('Enfermeiro(a) Emergencista')).toBe(HierarquiaNivel.SUPERVISAO);
      expect(determineHierarquiaByCargo('Supervisor(a) de Enfermagem')).toBe(HierarquiaNivel.SUPERVISAO);
      expect(determineHierarquiaByCargo('Supervisor(a) Administrativo')).toBe(HierarquiaNivel.SUPERVISAO);
      expect(determineHierarquiaByCargo('Enfermeira')).toBe(HierarquiaNivel.SUPERVISAO);
    });

    it('Cargos de apoio operacional (Maqueiro, Recepção, Portaria, Auxiliar Adm, etc.) devem receber Nível 4 (FUNCIONARIO)', () => {
      expect(determineHierarquiaByCargo('Maqueiro(a)')).toBe(HierarquiaNivel.FUNCIONARIO);
      expect(determineHierarquiaByCargo('Recepcionista / Atendente Hospitalar')).toBe(HierarquiaNivel.FUNCIONARIO);
      expect(determineHierarquiaByCargo('Agente de Portaria / Controle de Acesso')).toBe(HierarquiaNivel.FUNCIONARIO);
      expect(determineHierarquiaByCargo('Auxiliar Administrativo')).toBe(HierarquiaNivel.FUNCIONARIO);
      expect(determineHierarquiaByCargo('Auxiliar de Higiene e Limpeza')).toBe(HierarquiaNivel.FUNCIONARIO);
      expect(determineHierarquiaByCargo('Motorista de Ambulância / Condutor')).toBe(HierarquiaNivel.FUNCIONARIO);
      expect(determineHierarquiaByCargo('Outro')).toBe(HierarquiaNivel.FUNCIONARIO);
    });
  });
});
