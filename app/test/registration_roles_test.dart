import 'package:flutter_test/flutter_test.dart';
import 'package:conecta_saude/core/constants/hospital_roles.dart';

void main() {
  test('Cargos do cadastro pertencem a um único grupo coerente', () {
    expect(registrationRolesForLevel(3), contains('Enfermeiro(a) Geral'));
    expect(registrationRolesForLevel(2),
        contains('Enfermeiro(a) Chefe / Coordenação'));
    expect(registrationRolesForLevel(4), contains('Técnico(a) em Enfermagem'));
    final grouped = [2, 3, 4].expand(registrationRolesForLevel).toList();
    expect(grouped.length, kAllHospitalRoles.length);
    expect(grouped.toSet(), kAllHospitalRoles.toSet());
    expect(kRegistrationLevelLabels.containsKey(1), isFalse);
  });
}
