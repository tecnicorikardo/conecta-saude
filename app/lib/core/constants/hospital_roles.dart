library hospital_roles;

/// Lista padronizada de cargos e funções hospitalares alinhadas com o SUS / CBO.
/// Permite busca com autocomplete no cadastro e seleção estruturada.

const String kOtherRoleOption = 'Outro (especificar cargo)';

const Map<String, List<String>> kHospitalRolesByCategory = {
  'Enfermagem': [
    'Enfermeiro(a) Geral',
    'Enfermeiro(a) Chefe / Coordenação',
    'Enfermeiro(a) UTI',
    'Enfermeiro(a) Emergencista',
    'Técnico(a) em Enfermagem',
    'Auxiliar de Enfermagem',
    'Instrumentador(a) Cirúrgico(a)',
  ],
  'Corpo Clínico & Médico': [
    'Médico(a) Plantonista',
    'Médico(a) Emergencista / Pronto-Socorro',
    'Médico(a) Intensivista (UTI)',
    'Médico(a) Cirurgião Geral',
    'Médico(a) Clínico Geral',
    'Médico(a) Pediatra',
    'Médico(a) Anestesiologista',
    'Médico(a) Cardiologista',
    'Médico(a) Ortopedista',
    'Médico(a) Residente',
  ],
  'Apoio Assistencial & Multiprofissional': [
    'Fisioterapeuta Respiratório / Hospitalar',
    'Nutricionista Clínico(a)',
    'Psicólogo(a) Hospitalar',
    'Assistente Social',
    'Farmacêutico(a) Hospitalar',
    'Técnico(a) em Farmácia',
    'Fonoaudiólogo(a)',
    'Terapeuta Ocupacional',
  ],
  'Diagnóstico & Bioimagem': [
    'Biomédico(a)',
    'Bioquímico(a) / Analista Clínico',
    'Técnico(a) em Radiologia / Raio-X',
    'Técnico(a) em Tomografia / Ressonância',
    'Técnico(a) em Laboratório',
  ],
  'Operacional, Atendimento & Apoio': [
    'Recepcionista / Atendente Hospitalar',
    'Maqueiro(a)',
    'Agente de Portaria / CCO',
    'Operador(a) de Monitoramento CCO',
    'Auxiliar de Higiene e Limpeza',
    'Auxiliar de Manutenção Predial',
    'Auxiliar de Almoxarifado / Suprimentos',
    'Motorista de Ambulância / Condutor',
  ],
  'Gestão, Coordenação & Direção': [
    'Diretor(a) Geral',
    'Diretor(a) Clínico',
    'Diretor(a) Administrativo',
    'Coordenador(a) de Setor / CCO',
    'Supervisor(a) de Enfermagem',
    'Supervisor(a) Administrativo',
  ],
};

/// Lista plana de todos os cargos padrão ordenados alfabeticamente
List<String> get kAllHospitalRoles {
  final all = <String>[];
  for (final roles in kHospitalRolesByCategory.values) {
    all.addAll(roles);
  }
  all.sort((a, b) => a.compareTo(b));
  return all;
}
