import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:conecta_saude/features/auth/domain/entities/user_entity.dart';

void main() {
  group('UserEntity - Escala e Disponibilidade em Plantão', () {
    test('Usuário em plantão extra sempre retorna isCurrentlyWorking = true', () {
      final user = UserEntity(
        id: 'u-1',
        firebaseUid: 'fb-1',
        nome: 'Dra. Ana',
        email: 'ana@hospital.com',
        cargo: 'Médica Plantonista',
        hierarquiaNivel: 4,
        setorId: 'sec-1',
        setorNome: 'CCO',
        ativo: true,
        jornadaInicio: '01:00',
        jornadaFim: '02:00',
        jornadaDias: 'dom',
        emPlantaoExtra: true,
        criadoEm: DateTime.now(),
      );

      expect(user.isCurrentlyWorking, isTrue);
      expect(user.workStatusLabel, 'Em Plantão Extra');
      expect(user.workStatusColor, const Color(0xFF0288D1));
    });

    test('Usuário inativo sempre retorna status Inativo', () {
      final user = UserEntity(
        id: 'u-2',
        firebaseUid: 'fb-2',
        nome: 'Carlos Inativo',
        email: 'carlos@hospital.com',
        cargo: 'Técnico',
        hierarquiaNivel: 4,
        setorId: 'sec-1',
        setorNome: 'CCO',
        ativo: false,
        criadoEm: DateTime.now(),
      );

      expect(user.isCurrentlyWorking, isFalse);
      expect(user.workStatusLabel, 'Inativo');
    });

    test('Turno regular que engloba horário atual retorna Em Serviço', () {
      // 00:00 as 23:59 cobre qualquer momento do dia
      final user = UserEntity(
        id: 'u-3',
        firebaseUid: 'fb-3',
        nome: 'Enfermeiro Marcos',
        email: 'marcos@hospital.com',
        cargo: 'Enfermeiro Geral',
        hierarquiaNivel: 4,
        setorId: 'sec-1',
        setorNome: 'CCO',
        ativo: true,
        jornadaInicio: '00:00',
        jornadaFim: '23:59',
        jornadaDias: 'seg,ter,qua,qui,sex,sab,dom',
        emPlantaoExtra: false,
        criadoEm: DateTime.now(),
      );

      expect(user.isCurrentlyWorking, isTrue);
      expect(user.workStatusLabel, 'Em Serviço');
      expect(user.workStatusColor, const Color(0xFF2E7D32));
    });

    test('Dia de folga retorna Fora de Escala', () {
      final user = UserEntity(
        id: 'u-4',
        firebaseUid: 'fb-4',
        nome: 'Juliana Folga',
        email: 'juliana@hospital.com',
        cargo: 'Recepcionista',
        hierarquiaNivel: 4,
        setorId: 'sec-1',
        setorNome: 'CCO',
        ativo: true,
        jornadaInicio: '00:00',
        jornadaFim: '23:59',
        jornadaDias: 'nenhum_dia',
        emPlantaoExtra: false,
        criadoEm: DateTime.now(),
      );

      expect(user.isCurrentlyWorking, isFalse);
      expect(user.workStatusLabel, 'Fora de Escala');
      expect(user.workStatusColor, const Color(0xFFF57C00));
    });
  });
}
