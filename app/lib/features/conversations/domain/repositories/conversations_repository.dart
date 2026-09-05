import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/conversation_entity.dart';
import '../entities/message_entity.dart';

/// Repositório abstrato de conversas e mensagens
abstract class ConversationsRepository {
  /// Retorna a lista de conversas do usuário logado
  Future<Either<Failure, List<ConversationEntity>>> getConversations();

  /// Cria uma nova conversa individual com outro usuário
  Future<Either<Failure, ConversationEntity>> createConversation({
    required String targetUserId,
  });

  /// Retorna as mensagens de uma conversa (cursor-based pagination)
  Future<Either<Failure, List<MessageEntity>>> getMessages({
    required String conversationId,
    String? cursor,
    int limit = 50,
  });

  /// Envia uma nova mensagem de texto
  Future<Either<Failure, MessageEntity>> sendMessage({
    required String conversationId,
    required String texto,
  });

  /// Edita uma mensagem existente (janela de 5 minutos)
  Future<Either<Failure, MessageEntity>> editMessage({
    required String messageId,
    required String texto,
  });

  /// Exclui uma mensagem (soft delete)
  Future<Either<Failure, void>> deleteMessage({required String messageId});
}
