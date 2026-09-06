import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/http_service.dart';
import '../../domain/entities/conversation_entity.dart';
import '../../domain/entities/message_entity.dart';
import '../models/conversation_model.dart';

/// ConversationRepository — todas as chamadas ao backend para
/// conversas, mensagens e usuários disponíveis para conversa.
class ConversationRepository {
  ConversationRepository(this._http);

  final HttpService _http;

  // ─── Conversas ────────────────────────────────────────────────────────────

  /// GET /api/conversations
  Future<List<ConversationEntity>> listConversations() async {
    try {
      final response = await _http.get('/conversations');
      final data = response.data['data'] as List? ?? [];
      return data
          .map((j) => ConversationModel.fromJson(j as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// POST /api/conversations — criar conversa individual ou grupo
  Future<ConversationEntity> createConversation({
    required String tipo, // 'individual' | 'grupo'
    String? nome,
    required List<String> participantIds,
  }) async {
    try {
      final response = await _http.post('/conversations', data: {
        'tipo': tipo,
        if (nome != null && nome.isNotEmpty) 'nome': nome,
        'participantIds': participantIds,
      });
      return ConversationModel.fromJson(
          response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ─── Mensagens ────────────────────────────────────────────────────────────

  /// GET /api/conversations/:id/messages
  Future<List<MessageEntity>> listMessages(
    String conversationId, {
    String? cursor,
    int limit = 50,
  }) async {
    try {
      final response = await _http.get(
        '/conversations/$conversationId/messages',
        queryParameters: {
          if (cursor != null) 'cursor': cursor,
          'limit': limit,
        },
      );
      final items = response.data['data']['items'] as List? ?? [];
      return items
          .map((j) => MessageModel.fromJson(
              j as Map<String, dynamic>, conversationId))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// POST /api/conversations/:id/messages
  Future<MessageEntity> sendMessage(
      String conversationId, String texto) async {
    try {
      final response = await _http.post(
        '/conversations/$conversationId/messages',
        data: {'texto': texto},
      );
      return MessageModel.fromJson(
          response.data['data'] as Map<String, dynamic>, conversationId);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// PUT /api/messages/:id
  Future<MessageEntity> editMessage(
      String conversationId, String messageId, String novoTexto) async {
    try {
      final response = await _http.put(
        '/messages/$messageId',
        data: {'texto': novoTexto},
      );
      final data = response.data['data'] as Map<String, dynamic>;
      return MessageModel.fromJson(
          {...data, 'remetente': {}}, conversationId);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// DELETE /api/messages/:id
  Future<void> deleteMessage(String messageId) async {
    try {
      await _http.delete('/messages/$messageId');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ─── Usuários disponíveis ─────────────────────────────────────────────────

  /// GET /api/users — lista usuários que o usuário logado pode contactar
  Future<List<UserSummary>> listAvailableUsers({
    String? search,
    String? setorId,
  }) async {
    try {
      final response = await _http.get('/users', queryParameters: {
        if (search != null && search.isNotEmpty) 'search': search,
        if (setorId != null) 'setorId': setorId,
        'excludeSelf': 'true',
        'ativo': 'true',
        'limit': 100,
      });
      final items = response.data['data']['items'] as List? ?? [];
      return items
          .map((j) => UserSummary.fromJson(j as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ─── Tratamento de erros ──────────────────────────────────────────────────
  Exception _handleError(DioException e) {
    final msg = e.response?.data?['error'] as String?;
    final status = e.response?.statusCode;

    if (status == 401) return Exception('Sessão expirada. Faça login novamente.');
    if (status == 403) return Exception(msg ?? 'Sem permissão para esta ação.');
    if (status == 404) return Exception(msg ?? 'Recurso não encontrado.');
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return Exception('Servidor demorou a responder. Tente novamente.');
    }
    if (e.type == DioExceptionType.connectionError) {
      return Exception('Sem conexão com o servidor.');
    }

    return Exception(msg ?? 'Erro inesperado. Tente novamente.');
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────
final conversationRepositoryProvider =
    Provider<ConversationRepository>((ref) {
  final http = ref.watch(httpServiceProvider);
  return ConversationRepository(http);
});
