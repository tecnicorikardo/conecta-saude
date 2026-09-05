import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:conecta_saude/core/constants/app_constants.dart';
import 'package:conecta_saude/core/widgets/hierarchy_badge.dart';
import 'package:conecta_saude/core/widgets/status_badge.dart';
import 'package:conecta_saude/features/auth/data/models/user_model.dart';
import 'package:conecta_saude/features/sectors/data/models/sector_model.dart';

void main() {
  group('AppConstants Tests', () {
    test('Hierarquia levels are properly defined', () {
      expect(AppConstants.hierarquiaDirecao, 1);
      expect(AppConstants.hierarquiaCoordenacao, 2);
      expect(AppConstants.hierarquiaSupervisao, 3);
      expect(AppConstants.hierarquiaFuncionario, 4);
    });
  });

  group('UserModel Tests', () {
    test('UserModel.fromJson parses flat and nested setor correctly', () {
      final flatJson = {
        'id': 'usr_1',
        'firebaseUid': 'fb_1',
        'nome': 'Dra. Maria',
        'email': 'maria@hospital.com',
        'cargo': 'Médica Plantonista',
        'hierarquiaNivel': 1,
        'setorId': 'sec_1',
        'setorNome': 'Diretoria Médica',
        'fotoUrl': null,
        'ativo': true,
        'criadoEm': '2026-09-01T10:00:00.000Z',
      };

      final user1 = UserModel.fromJson(flatJson);
      expect(user1.id, 'usr_1');
      expect(user1.isDirecao, isTrue);
      expect(user1.isAdmin, isTrue);
      expect(user1.hierarquiaNome, 'Direção');

      final nestedJson = {
        'id': 'usr_2',
        'nome': 'Carlos Enfermeiro',
        'email': 'carlos@hospital.com',
        'cargo': 'Enfermeiro Chefe',
        'hierarquiaNivel': 3,
        'setor': {'id': 'sec_enf', 'nome': 'Enfermagem'},
        'ativo': false,
      };

      final user2 = UserModel.fromJson(nestedJson);
      expect(user2.id, 'usr_2');
      expect(user2.setorId, 'sec_enf');
      expect(user2.setorNome, 'Enfermagem');
      expect(user2.isSupervisao, isTrue);
      expect(user2.ativo, isFalse);
    });
  });

  group('SectorModel Tests', () {
    test('SectorModel.fromJson parses correctly', () {
      final json = {
        'id': 'sec_ti',
        'nome': 'Tecnologia da Informação',
        'descricao': 'Suporte técnico e infraestrutura',
        'ativo': true,
        'criadoEm': '2026-09-01T10:00:00.000Z',
      };

      final sector = SectorModel.fromJson(json);
      expect(sector.id, 'sec_ti');
      expect(sector.nome, 'Tecnologia da Informação');
      expect(sector.descricao, 'Suporte técnico e infraestrutura');
      expect(sector.ativo, isTrue);
    });
  });

  group('Widgets Tests', () {
    testWidgets('HierarchyBadge renders correct label for Direção',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HierarchyBadge(nivel: 1),
          ),
        ),
      );

      expect(find.text('DIREÇÃO'), findsOneWidget);
    });

    testWidgets('HierarchyBadge renders correct label for Funcionário',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HierarchyBadge(nivel: 4),
          ),
        ),
      );

      expect(find.text('FUNCIONÁRIO'), findsOneWidget);
    });

    testWidgets('StatusBadge renders Ativo and Inativo correctly',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                StatusBadge(ativo: true),
                StatusBadge(ativo: false),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Ativo'), findsOneWidget);
      expect(find.text('Inativo'), findsOneWidget);
    });
  });
}
