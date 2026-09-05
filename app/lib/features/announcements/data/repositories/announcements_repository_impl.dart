import 'dart:async';
import 'package:uuid/uuid.dart';
import '../../domain/entities/announcement_entity.dart';
import '../../domain/repositories/announcements_repository.dart';

class AnnouncementsRepositoryImpl implements AnnouncementsRepository {
  final List<AnnouncementEntity> _announcements = [
    AnnouncementEntity(
      id: 'ann-1',
      titulo: 'Direção Geral — Reunião de Integração: CCDTI, CCO e CCE',
      mensagem:
          'Informamos a todas as coordenações e equipes técnicas que haverá reunião geral de alinhamento integrado amanhã às 14h no auditório central.\n\nPauta principal: fluxos de encaminhamento entre os centros, protocolos de regulação e escala de plantão integrada.',
      prioridade: AnnouncementPriority.urgente,
      publicadoEm: DateTime.now().subtract(const Duration(hours: 2)),
      criadorNome: 'Carlos Eduardo Mendes',
      criadorCargo: 'Diretor Geral / Admin Geral',
      lido: false,
      totalLeituras: 18,
      totalUsuarios: 30,
    ),
    AnnouncementEntity(
      id: 'ann-2',
      titulo: 'CCO — Mutirão de Cirurgias de Catarata neste Sábado',
      mensagem:
          'O Centro Carioca do Olho (CCO) realizará força-tarefa cirúrgica no próximo sábado a partir das 07h.\n\nAs equipes de enfermagem cirúrgica e apoio técnico devem comparecer conforme escala divulgada pelo Dr. Roberto Vasconcelos.',
      prioridade: AnnouncementPriority.alta,
      publicadoEm: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
      criadorNome: 'Dr. Roberto Vasconcelos',
      criadorCargo: 'Coordenador Médico — CCO',
      lido: true,
      lidoEm: DateTime.now().subtract(const Duration(hours: 10)),
      totalLeituras: 24,
      totalUsuarios: 30,
    ),
    AnnouncementEntity(
      id: 'ann-3',
      titulo: 'CCDTI — Novo Protocolo de Preparo para Tomografia e Ressonância',
      mensagem:
          'O Centro Carioca de Diagnóstico e Tratamento por Imagem (CCDTI) atualizou as orientações de jejum e hidratação para exames contrastados. O documento está disponível no manual institucional do CCDTI.',
      prioridade: AnnouncementPriority.normal,
      publicadoEm: DateTime.now().subtract(const Duration(days: 2)),
      criadorNome: 'Dra. Juliana Moreira',
      criadorCargo: 'Coordenadora — CCDTI',
      lido: true,
      lidoEm: DateTime.now().subtract(const Duration(days: 1)),
      totalLeituras: 28,
      totalUsuarios: 30,
    ),
    AnnouncementEntity(
      id: 'ann-4',
      titulo: 'CCE — Abertura de Vagas Extras para Regulação em Cardiologia',
      mensagem:
          'O Centro Carioca de Especialidades (CCE) abriu 60 novas vagas ambulatoriais de cardiologia para atender demandas prioritárias reguladas pelo SISREG.',
      prioridade: AnnouncementPriority.normal,
      publicadoEm: DateTime.now().subtract(const Duration(days: 3)),
      criadorNome: 'Dra. Beatriz Castro',
      criadorCargo: 'Coordenadora — CCE',
      lido: true,
      lidoEm: DateTime.now().subtract(const Duration(days: 2)),
      totalLeituras: 26,
      totalUsuarios: 30,
    ),
  ];

  @override
  Future<List<AnnouncementEntity>> getAnnouncements() async {
    await Future.delayed(const Duration(milliseconds: 300));
    // Ordena do mais recente ao mais antigo
    _announcements.sort((a, b) => b.publicadoEm.compareTo(a.publicadoEm));
    return List.unmodifiable(_announcements);
  }

  @override
  Future<bool> confirmRead(String id) async {
    await Future.delayed(const Duration(milliseconds: 250));
    final index = _announcements.indexWhere((a) => a.id == id);
    if (index != -1) {
      final current = _announcements[index];
      if (!current.lido) {
        _announcements[index] = current.copyWith(
          lido: true,
          lidoEm: DateTime.now(),
          totalLeituras: current.totalLeituras + 1,
        );
      }
      return true;
    }
    return false;
  }

  @override
  Future<AnnouncementEntity> createAnnouncement({
    required String titulo,
    required String mensagem,
    required AnnouncementPriority prioridade,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final newAnnouncement = AnnouncementEntity(
      id: 'ann-${const Uuid().v4().substring(0, 8)}',
      titulo: titulo,
      mensagem: mensagem,
      prioridade: prioridade,
      publicadoEm: DateTime.now(),
      criadorNome: 'Coordenação Geral',
      criadorCargo: 'Diretoria / Coordenação',
      lido: true,
      lidoEm: DateTime.now(),
      totalLeituras: 1,
      totalUsuarios: 25,
    );
    _announcements.insert(0, newAnnouncement);
    return newAnnouncement;
  }

  @override
  Future<Map<String, int>> getStats(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final announcement = _announcements.firstWhere((a) => a.id == id);
    return {
      'totalLeituras': announcement.totalLeituras,
      'totalUsuarios': announcement.totalUsuarios,
      'percentual': announcement.percentualLeitura,
    };
  }
}
