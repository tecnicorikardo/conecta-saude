import 'package:flutter_test/flutter_test.dart';

String formatGreetingName(String fullName) {
  final trimmed = fullName.trim();
  if (trimmed.isEmpty) return 'Usuário';
  final parts = trimmed.split(RegExp(r'\s+'));
  if (parts.isEmpty) return 'Usuário';

  final titles = {
    'dr.', 'dr', 'dra.', 'dra', 'enf.', 'enf',
    'enfermeiro', 'enfermeira', 'prof.', 'prof',
    'profa.', 'profa', 'tec.', 'tec', 'técnico', 'técnica',
    'sr.', 'sr', 'sra.', 'sra', 'med.', 'médico', 'médica'
  };
  final firstLower = parts.first.toLowerCase();
  if (titles.contains(firstLower) && parts.length > 1) {
    return '${parts[0]} ${parts[1]}';
  }
  return parts.first;
}

String extractInitials(String name) {
  final clean = name.trim();
  if (clean.isEmpty) return 'U';
  final parts = clean.split(RegExp(r'\s+'));
  final titles = {
    'dr.', 'dr', 'dra.', 'dra', 'enf.', 'enf',
    'enfermeiro', 'enfermeira', 'prof.', 'prof',
    'profa.', 'profa', 'tec.', 'tec', 'técnico', 'técnica',
    'sr.', 'sr', 'sra.', 'sra', 'med.', 'médico', 'médica'
  };
  if (parts.isNotEmpty && titles.contains(parts.first.toLowerCase()) && parts.length > 1) {
    if (parts.length >= 3) {
      return '${parts[1][0]}${parts[2][0]}'.toUpperCase();
    }
    return parts[1][0].toUpperCase();
  }
  if (parts.length >= 2) {
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
  return parts.isNotEmpty && parts[0].isNotEmpty ? parts[0][0].toUpperCase() : 'U';
}

void main() {
  group('Hospital Greeting & Initials Formatting', () {
    test('Formata títulos médicos e de enfermagem corretamente', () {
      expect(formatGreetingName('Dr. Roberto Vasconcelos'), 'Dr. Roberto');
      expect(formatGreetingName('Dra. Mariana Silva'), 'Dra. Mariana');
      expect(formatGreetingName('Enf. Carlos Alberto'), 'Enf. Carlos');
      expect(formatGreetingName('Prof. Fernando'), 'Prof. Fernando');
      expect(formatGreetingName('Tec. João Pedro'), 'Tec. João');
    });

    test('Formata nomes regulares sem título usando apenas o primeiro nome', () {
      expect(formatGreetingName('Ricardo Santana'), 'Ricardo');
      expect(formatGreetingName('Paula Souza'), 'Paula');
      expect(formatGreetingName('Ana'), 'Ana');
      expect(formatGreetingName(''), 'Usuário');
    });

    test('Extrai iniciais ignorando títulos institucionais', () {
      expect(extractInitials('Dr. Roberto Vasconcelos'), 'RV');
      expect(extractInitials('Dra. Mariana Silva Santos'), 'MS');
      expect(extractInitials('Ricardo Santana'), 'RS');
      expect(extractInitials('Carlos'), 'C');
    });
  });
}
