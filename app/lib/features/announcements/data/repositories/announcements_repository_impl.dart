import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/http_service.dart';
import '../../domain/entities/announcement_entity.dart';
import '../../domain/repositories/announcements_repository.dart';

class AnnouncementsRepositoryImpl implements AnnouncementsRepository {
  // Implementa o contrato do domínio usando HTTP. A tela depende do contrato,
  // enquanto este arquivo conhece os caminhos e o formato JSON do servidor.
  final HttpService _http;

  AnnouncementsRepositoryImpl(this._http);

  @override
  Future<void> deleteAnnouncement(String id) async {
    try {
      await _http.delete('/announcements/$id');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<List<AnnouncementEntity>> getAnnouncements() async {
    try {
      final response = await _http.get('/announcements');
      final data = response.data['data'] as Map<String, dynamic>? ?? {};
      final items = data['items'] as List? ?? [];

      return items.map((j) => _fromJson(j as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<bool> confirmRead(String id) async {
    try {
      final response = await _http.post('/announcements/$id/read');
      return response.data['success'] == true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<AnnouncementEntity> createAnnouncement({
    required String titulo,
    required String mensagem,
    required AnnouncementPriority prioridade,
  }) async {
    // O servidor obtém o autor pela sessão. Não enviamos cargo, nível ou autor
    // no formulário: esses valores não podem ser escolhidos pelo aplicativo.
    try {
      final response = await _http.post('/announcements', data: {
        'titulo': titulo,
        'mensagem': mensagem,
        'prioridade': prioridade.name,
      });

      final data = response.data['data'] as Map<String, dynamic>;
      return _fromJson(data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<Map<String, int>> getStats(String id) async {
    try {
      final response = await _http.get('/announcements/$id/stats');
      final data = response.data['data'] as Map<String, dynamic>? ?? {};

      return {
        'totalLeituras': data['totalReads'] as int? ?? 0,
        'totalUsuarios': data['totalUsers'] as int? ?? 0,
        'percentual': data['percentual'] as int? ?? 0,
      };
    } catch (_) {
      return {
        'totalLeituras': 0,
        'totalUsuarios': 0,
        'percentual': 0,
      };
    }
  }

  @override
  Future<AnnouncementStatsEntity> getAnnouncementReaders(String id) async {
    try {
      final response = await _http.get('/announcements/$id/stats');
      final data = response.data['data'] as Map<String, dynamic>? ?? {};

      final readersList = (data['readers'] as List? ?? []).map((r) {
        final rMap = r as Map<String, dynamic>;
        return AnnouncementReaderEntity(
          userId: rMap['userId'] as String? ?? '',
          nome: rMap['nome'] as String? ?? '',
          cargo: rMap['cargo'] as String? ?? '',
          setorNome: rMap['setorNome'] as String? ?? '',
          fotoUrl: rMap['fotoUrl'] as String?,
          hierarquiaNivel: rMap['hierarquiaNivel'] as int? ?? 4,
          lidoEm: DateTime.tryParse(rMap['lidoEm']?.toString() ?? '')?.toLocal() ?? DateTime.now(),
        );
      }).toList();

      final pendingList = (data['pending'] as List? ?? []).map((p) {
        final pMap = p as Map<String, dynamic>;
        return AnnouncementReaderEntity(
          userId: pMap['userId'] as String? ?? '',
          nome: pMap['nome'] as String? ?? '',
          cargo: pMap['cargo'] as String? ?? '',
          setorNome: pMap['setorNome'] as String? ?? '',
          fotoUrl: pMap['fotoUrl'] as String?,
          hierarquiaNivel: pMap['hierarquiaNivel'] as int? ?? 4,
          lidoEm: null,
        );
      }).toList();

      return AnnouncementStatsEntity(
        announcementId: data['announcementId'] as String? ?? id,
        totalUsers: data['totalUsers'] as int? ?? 0,
        totalReads: data['totalReads'] as int? ?? 0,
        percentual: data['percentual'] as int? ?? 0,
        readers: readersList,
        pending: pendingList,
      );
    } catch (e) {
      throw Exception('Erro ao buscar leitores do comunicado: $e');
    }
  }

  static AnnouncementEntity _fromJson(Map<String, dynamic> j) {
    final criador = j['criador'] as Map<String, dynamic>?;
    final lidoEmStr = j['lidoEm']?.toString();
    final lidoEm = lidoEmStr != null ? DateTime.tryParse(lidoEmStr)?.toLocal() : null;

    return AnnouncementEntity(
      canDelete: j['canDelete'] == true,
      id: j['id'] as String,
      titulo: j['titulo'] as String? ?? '',
      mensagem: j['mensagem'] as String? ?? '',
      prioridade: AnnouncementPriority.fromString(j['prioridade'] as String? ?? 'normal'),
      publicadoEm: DateTime.tryParse(j['publicadoEm'] as String? ?? '')?.toLocal() ?? DateTime.now(),
      criadorNome: criador?['nome'] as String? ?? 'Administração',
      criadorCargo: criador?['cargo'] as String? ?? 'Direção / Coordenação',
      lido: j['lido'] as bool? ?? false,
      lidoEm: lidoEm,
      totalLeituras: j['totalLeituras'] as int? ?? 0,
      totalUsuarios: j['totalUsuarios'] as int? ?? 0,
    );
  }

  Exception _handleError(DioException e) {
    // DioException representa uma falha HTTP/rede. Quando existe resposta,
    // mostramos a explicação da API em vez de esconder a causa do bloqueio.
    final msg = e.response?.data?['error'] as String?;
    final status = e.response?.statusCode;
    if (status == 401) return Exception('Sessão expirada.');
    if (status == 403) return Exception(msg ?? 'Sem permissão para criar comunicados.');
    return Exception(msg ?? 'Erro ao buscar comunicados.');
  }
}

final announcementsRepositoryProvider = Provider<AnnouncementsRepository>((ref) {
  final http = ref.watch(httpServiceProvider);
  return AnnouncementsRepositoryImpl(http);
});
