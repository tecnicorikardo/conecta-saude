import 'package:flutter/foundation.dart';

enum LanguageRiskLevel {
  level0Normal,
  level1PotentiallyInappropriate,
  level2OffensiveOrHostile,
  level3SevereOrDiscriminatory,
}

enum LanguageCategory {
  normal,
  informalIntimate,
  directedInsult,
  severeThreat,
  discrimination,
  sexualMisconduct,
  clinicalExemption,
}

class FilterEvaluationResult {
  final LanguageRiskLevel level;
  final LanguageCategory category;
  final String? matchedPattern;
  final String title;
  final String message;
  final String reasonCode;
  final bool allowsBypass;

  const FilterEvaluationResult({
    required this.level,
    required this.category,
    this.matchedPattern,
    required this.title,
    required this.message,
    required this.reasonCode,
    required this.allowsBypass,
  });

  bool get isClean => level == LanguageRiskLevel.level0Normal;
  bool get needsWarning => level == LanguageRiskLevel.level1PotentiallyInappropriate;
  bool get isBlocked =>
      level == LanguageRiskLevel.level2OffensiveOrHostile ||
      level == LanguageRiskLevel.level3SevereOrDiscriminatory;
}

class LanguageFilterService {
  LanguageFilterService._();

  static final LanguageFilterService instance = LanguageFilterService._();

  // ─── TERMOS CLÍNICOS / EXCEÇÃO HOSPITALAR ──────────────────────────────────
  static const Set<String> _clinicalLegitimatePhrases = {
    'equipe',
    'querida equipe',
    'bom dia equipe',
    'boa tarde equipe',
    'boa noite equipe',
    'leito',
    'paciente',
    'prontuario',
    'plantao',
    'evolucao',
    'prescricao',
    'emergencia',
    'uti',
    'cti',
    'upa',
    'reanimacao',
    'parada',
    'medicacao',
    'dosagem',
    'glicemia',
    'saturacao',
    'oxigenio',
    'hemoderivado',
    'cirurgia',
    'centro cirurgico',
    'relatorio',
    'doutor',
    'doutora',
    'enfermeiro',
    'enfermeira',
    'tecnico',
    'coordenador',
    'coordenadora',
    'diretor',
    'diretora',
    'professor',
    'professora',
  };

  // ─── NÍVEL 1: Termos Informais / Íntimos no Trabalho ───────────────────────
  static const List<String> _level1IntimateTerms = [
    'meu bem',
    'meu amor',
    'amorzinho',
    'queridinha',
    'queridinho',
    'docinho',
    'gatinha',
    'gatinho',
    'linda',
    'lindo',
    'princesa',
    'principe',
    'bb',
    'bebe',
    'fofinha',
    'fofinho',
    'delicia',
    'gostosa',
    'gostoso',
    'corpitcho',
  ];

  // ─── NÍVEL 2: Insultos Direcionados, Palavrões e Humilhação ────────────────
  static const List<String> _level2HostileTerms = [
    'incompetente',
    'idiota',
    'imbecil',
    'burro',
    'burra',
    'estupido',
    'estupida',
    'retardado',
    'retardada',
    'inutil',
    'palhaco',
    'palhaca',
    'lixo',
    'vagabundo',
    'vagabunda',
    'preguicoso',
    'preguicosa',
    'desgracado',
    'desgracada',
    'arrombado',
    'arrombada',
    'filho da puta',
    'filha da puta',
    'fdp',
    'vai se foder',
    'vai tomar no cu',
    'vtnc',
    'vsf',
    'cala a boca',
    'voce nao serve pra nada',
    'nunca faz nada direito',
    'pessimo profissional',
    'pessima profissional',
    'nao sabe trabalhar',
  ];

  // ─── NÍVEL 3: Ameaças Graves, Discriminação e Assédio Sexual Explícito ──────
  static const List<String> _level3SeverePatterns = [
    // Ameaça física / profissional grave
    'vou te pegar',
    'vou te matar',
    'te quebro a cara',
    'vou acabar com voce',
    'vou te destruir',
    'voce vai pagar caro',
    'vou mandar te demitir',
    'vou te prejudicar',
    'te pego la fora',
    'vou te agredir',
    
    // Assédio sexual explícito / chantagem
    'dorme comigo',
    'fica comigo ou',
    'transa comigo',
    'manda nudes',
    'manda foto pelada',
    'manda foto pelado',
    'quero ver seu corpo',
    'chupame',
    'sexo oral',
    
    // Discriminação / Preconceito
    'macaco',
    'macaca',
    'viadinho',
    'sapatona',
    'traveco',
    'aleijado',
    'aleijada',
    'nordestino de merda',
    'sua cor',
    'sua raca',
    'sua religiao lixo',
  ];

  /// Normaliza o texto removendo acentuação, caracteres repetitivos, números substitutos e pontuações
  static String normalizeText(String input) {
    String text = input.toLowerCase().trim();

    // Substituições comuns de contorno (leetspeak)
    text = text
        .replaceAll('@', 'a')
        .replaceAll('4', 'a')
        .replaceAll('3', 'e')
        .replaceAll('1', 'i')
        .replaceAll('!', 'i')
        .replaceAll('0', 'o')
        .replaceAll('5', 's')
        .replaceAll('7', 't')
        .replaceAll(r'$', 's');

    // Remoção de acentos diacríticos
    const withAccents = 'áàãâäéèêëíìîïóòõôöúùûüçñ';
    const withoutAccents = 'aaaaaeeeeiiiiooooouuuucn';
    for (int i = 0; i < withAccents.length; i++) {
      text = text.replaceAll(withAccents[i], withoutAccents[i]);
    }

    // Redução de caracteres repetidos sucessivos (ex: "buuuurro" -> "burro", "idiiooota" -> "idiota")
    final buffer = StringBuffer();
    int repeatCount = 0;
    String lastChar = '';

    for (int i = 0; i < text.length; i++) {
      final char = text[i];
      if (char == lastChar) {
        repeatCount++;
        if (repeatCount < 2) {
          buffer.write(char);
        }
      } else {
        lastChar = char;
        repeatCount = 0;
        buffer.write(char);
      }
    }

    return buffer.toString();
  }

  /// Avalia a mensagem para determinar o nível de risco e a orientação institucional aplicável
  FilterEvaluationResult evaluateMessage({
    required String text,
    bool isEmergencyChannel = false,
    bool isOperationalUrgent = false,
  }) {
    if (text.trim().isEmpty) {
      return const FilterEvaluationResult(
        level: LanguageRiskLevel.level0Normal,
        category: LanguageCategory.normal,
        title: 'Mensagem Normal',
        message: '',
        reasonCode: 'empty',
        allowsBypass: true,
      );
    }

    final normalized = normalizeText(text);

    // ─── EXCEÇÃO 1: Expressão de Comunicação Operacional ou Clínica Legítima ──
    // Se a mensagem contiver contexto de trabalho reconhecido e for em canal de emergência
    if (isEmergencyChannel || isOperationalUrgent) {
      for (final phrase in _clinicalLegitimatePhrases) {
        if (normalized.contains(phrase)) {
          // Permite passar diretamente para garantir agilidade no atendimento do hospital
          return const FilterEvaluationResult(
            level: LanguageRiskLevel.level0Normal,
            category: LanguageCategory.clinicalExemption,
            title: 'Comunicação Clínica',
            message: 'Mensagem de contexto operacional/clínico autorizada.',
            reasonCode: 'clinical_authorized',
            allowsBypass: true,
          );
        }
      }
    }

    // Casos legítimos de saudação de equipe não devem disparar nível 1
    if (normalized.contains('querida equipe') ||
        normalized.contains('bom dia equipe') ||
        normalized.contains('boa tarde equipe') ||
        normalized.contains('boa noite equipe') ||
        normalized.contains('queridos colegas') ||
        normalized.contains('queridas colegas')) {
      return const FilterEvaluationResult(
        level: LanguageRiskLevel.level0Normal,
        category: LanguageCategory.normal,
        title: 'Saudação Legítima',
        message: '',
        reasonCode: 'team_greeting_allowed',
        allowsBypass: true,
      );
    }

    // ─── CHECAGEM DE NÍVEL 3 (Ameaças, Discriminação, Assédio Grave) ──────────
    for (final pattern in _level3SeverePatterns) {
      if (_matchesTerm(normalized, pattern)) {
        return FilterEvaluationResult(
          level: LanguageRiskLevel.level3SevereOrDiscriminatory,
          category: LanguageCategory.severeThreat,
          matchedPattern: pattern,
          title: 'Bloqueio Institucional',
          message:
              'Esta mensagem não foi enviada porque contém linguagem potencialmente grave ou incompatível com a política de comunicação profissional do Conecta Saúde.\n\nSe você precisa relatar uma situação, utilize o canal de Ouvidoria ou Denúncia Institucional.',
          reasonCode: 'level3_severe_policy_violation',
          allowsBypass: false,
        );
      }
    }

    // ─── CHECAGEM DE NÍVEL 2 (Insultos Direcionados, Palavrões e Humilhação) ────
    for (final term in _level2HostileTerms) {
      if (_matchesTerm(normalized, term)) {
        return FilterEvaluationResult(
          level: LanguageRiskLevel.level2OffensiveOrHostile,
          category: LanguageCategory.directedInsult,
          matchedPattern: term,
          title: 'Envio Não Permitido',
          message:
              'Não foi possível enviar esta mensagem porque ela pode conter ofensa ou linguagem inadequada para o ambiente profissional.\n\nRevise o texto ou utilize o canal institucional apropriado para registrar uma ocorrência.',
          reasonCode: 'level2_directed_insult',
          allowsBypass: false,
        );
      }
    }

    // ─── CHECAGEM DE NÍVEL 1 (Termos excessivamente informais / íntimos) ──────
    // Não bloqueia isolados como "amor", mas avisa educativamente se houver padrão informal
    for (final term in _level1IntimateTerms) {
      if (_matchesTerm(normalized, term)) {
        return FilterEvaluationResult(
          level: LanguageRiskLevel.level1PotentiallyInappropriate,
          category: LanguageCategory.informalIntimate,
          matchedPattern: term,
          title: 'Aviso de Linguagem Profissional',
          message:
              'Esta mensagem contém uma expressão que pode ser interpretada como informal ou inadequada no ambiente hospitalar profissional.\n\nDeseja revisar antes de enviar?',
          reasonCode: 'level1_informal_intimate',
          allowsBypass: true,
        );
      }
    }

    // ─── NÍVEL 0: Tudo certo ──────────────────────────────────────────────────
    return const FilterEvaluationResult(
      level: LanguageRiskLevel.level0Normal,
      category: LanguageCategory.normal,
      title: 'Mensagem Normal',
      message: '',
      reasonCode: 'clean',
      allowsBypass: true,
    );
  }

  /// Verifica casamento por palavra exata ou limites de palavra para evitar falsos positivos
  static bool _matchesTerm(String normalizedText, String term) {
    if (term.contains(' ')) {
      return normalizedText.contains(term);
    }
    
    // Regexp para buscar a palavra completa
    final regex = RegExp(r'(^|[^\w])' + RegExp.escape(term) + r'([^\w]|$)');
    return regex.hasMatch(normalizedText);
  }
}