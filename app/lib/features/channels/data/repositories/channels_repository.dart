import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/http_service.dart';
import '../../domain/entities/channel_entity.dart';

class ChannelsRepository {
  final HttpService _http;

  ChannelsRepository(this._http);

  Future<List<ChannelEntity>> listAllChannels() async {
    try {
      final response = await _http.get('/channels/all');
      final items = response.data['data'] as List? ?? [];
      return items.map((j) => _fromJson(j as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<ChannelEntity>> listMyChannels() async {
    try {
      final response = await _http.get('/channels');
      final items = response.data['data'] as List? ?? [];
      return items.map((j) => _fromJson(j as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<ChannelEntity> createChannel({
    required String nome,
    String? descricao,
    required String tipo,
    String? setorId,
  }) async {
    try {
      final response = await _http.post('/channels', data: {
        'nome': nome,
        if (descricao != null && descricao.isNotEmpty) 'descricao': descricao,
        'tipo': tipo,
        if (setorId != null && setorId.isNotEmpty) 'setorId': setorId,
      });
      final data = response.data['data'] as Map<String, dynamic>;
      return _fromJson(data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> addMember(String channelId, String userId) async {
    try {
      await _http.post('/channels/$channelId/members', data: {'userId': userId});
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> removeMember(String channelId, String userId) async {
    try {
      await _http.delete('/channels/$channelId/members/$userId');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<ChannelMessageEntity>> listChannelMessages(String channelId) async {
    try {
      final response = await _http.get('/channels/$channelId/messages');
      final items = response.data['data'] as List? ?? [];
      return items.map((j) => _messageFromJson(j as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<ChannelMessageEntity> postChannelMessage(String channelId, String texto) async {
    try {
      final response = await _http.post('/channels/$channelId/messages', data: {
        'texto': texto,
      });
      final data = response.data['data'] as Map<String, dynamic>;
      return _messageFromJson(data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<ChannelMessageStatsEntity> getMessageReaders(String channelId, String messageId) async {
    try {
      final response = await _http.get('/channels/$channelId/messages/$messageId/reads');
      final data = response.data['data'] as Map<String, dynamic>;
      final readersList = (data['readers'] as List? ?? []).map((r) {
        final rMap = r as Map<String, dynamic>;
        return ChannelReaderEntity(
          userId: rMap['userId'] as String? ?? '',
          nome: rMap['nome'] as String? ?? '',
          cargo: rMap['cargo'] as String? ?? '',
          setorNome: rMap['setorNome'] as String? ?? '',
          fotoUrl: rMap['fotoUrl'] as String?,
          hierarquiaNivel: rMap['hierarquiaNivel'] as int? ?? 4,
          lidoEm: DateTime.tryParse(rMap['lidoEm']?.toString() ?? '')?.toLocal() ?? DateTime.now(),
        );
      }).toList();

      return ChannelMessageStatsEntity(
        messageId: data['messageId'] as String? ?? messageId,
        totalMembers: data['totalMembers'] as int? ?? 0,
        totalReads: data['totalReads'] as int? ?? 0,
        percentual: data['percentual'] as int? ?? 0,
        readers: readersList,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  static ChannelEntity _fromJson(Map<String, dynamic> j) {
    final setor = j['setor'] as Map<String, dynamic>?;
    final setorNome = setor?['nome'] as String? ?? '';
    final count = j['_count'] as Map<String, dynamic>?;
    final totalMembros = count?['members'] as int? ?? 0;
    final tipoStr = j['tipo'] as String? ?? 'geral';
    final ultimaMsg = j['ultimaMensagem'] as String?;
    final ultimaHoraStr = j['ultimaMensagemHora']?.toString();
    final ultimaHora = ultimaHoraStr != null ? DateTime.tryParse(ultimaHoraStr)?.toLocal() : null;
    final naoLidas = j['naoLidas'] as int? ?? 0;

    // Inferir centroTag a partir do setorNome, nome do canal e tipo
    String centroTag = 'GERAL';
    if (tipoStr == 'emergencia') {
      centroTag = 'EMERGENCIA';
    } else {
      final combined = '${j['nome']} $setorNome'.toUpperCase();
      if (combined.contains('CCD') || combined.contains('IMAGEM')) {
        centroTag = 'CCD';
      } else if (combined.contains('CCO') || combined.contains('OLHO')) {
        centroTag = 'CCO';
      } else if (combined.contains('CCE') || combined.contains('ESPECIALIDADE')) {
        centroTag = 'CCE';
      }
    }

    return ChannelEntity(
      id: j['id'] as String,
      nome: j['nome'] as String? ?? '',
      descricao: j['descricao'] as String?,
      tipo: ChannelType.fromString(tipoStr),
      centroTag: centroTag,
      setorId: j['setorId'] as String? ?? setor?['id'] as String?,
      setorNome: setorNome.isNotEmpty ? setorNome : null,
      totalMembros: totalMembros,
      ultimaMensagem: ultimaMsg,
      ultimaMensagemHora: ultimaHora,
      naoLidas: naoLidas,
    );
  }

  static ChannelMessageEntity _messageFromJson(Map<String, dynamic> j) {
    return ChannelMessageEntity(
      id: j['id'] as String? ?? '',
      channelId: j['channelId'] as String? ?? '',
      remetenteId: j['remetenteId'] as String? ?? '',
      remetenteNome: j['remetenteNome'] as String? ?? 'Usuário',
      remetenteCargo: j['remetenteCargo'] as String? ?? 'Colaborador',
      remetenteFotoUrl: j['remetenteFotoUrl'] as String?,
      remetenteHierarquia: j['remetenteHierarquia'] as int? ?? 4,
      texto: j['texto'] as String? ?? '',
      criadoEm: DateTime.tryParse(j['criadoEm']?.toString() ?? '')?.toLocal() ?? DateTime.now(),
      readsCount: j['readsCount'] as int? ?? 0,
      lidoPorMim: j['lidoPorMim'] as bool? ?? true,
    );
  }

  Exception _handleError(DioException e) {
    final msg = e.response?.data?['error'] as String?;
    final status = e.response?.statusCode;
    if (status == 401) return Exception('Sessão expirada. Faça login novamente.');
    if (status == 403) return Exception(msg ?? 'Sem permissão para acessar estes canais.');
    if (status == 404) return Exception(msg ?? 'Canal não encontrado.');
    return Exception(msg ?? 'Erro ao comunicar com o servidor.');
  }
}

final channelsRepositoryProvider = Provider<ChannelsRepository>((ref) {
  final http = ref.watch(httpServiceProvider);
  return ChannelsRepository(http);
});
