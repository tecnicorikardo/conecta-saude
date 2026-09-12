import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/http_service.dart';
import 'current_user_provider.dart';

/// Provider para gerenciar o estado de serviço do usuário
final serviceStatusProvider = StateNotifierProvider<ServiceStatusNotifier, AsyncValue<bool>>((ref) {
  return ServiceStatusNotifier(ref);
});

class ServiceStatusNotifier extends StateNotifier<AsyncValue<bool>> {
  final Ref _ref;

  ServiceStatusNotifier(this._ref) : super(const AsyncValue.loading()) {
    _initialize();
  }

  void _initialize() {
    final user = _ref.read(currentUserProvider).valueOrNull;
    if (user != null) {
      state = AsyncValue.data(user.emServico);
    } else {
      state = const AsyncValue.data(true); // default
    }
  }

  /// Alterna o status de serviço (Em Serviço ↔ Fora de Serviço)
  Future<void> toggle() async {
    final currentValue = state.valueOrNull ?? true;
    final newValue = !currentValue;

    // Otimistic update
    state = AsyncValue.data(newValue);

    try {
      final http = _ref.read(httpServiceProvider);
      await http.patch('/users/me/service-status', data: {
        'emServico': newValue,
      });

      // Recarregar usuário para garantir sincronização
      await _ref.read(currentUserProvider.notifier).refreshUser();

      debugPrint('[ServiceStatus] Status alterado para: ${newValue ? "Em Serviço" : "Fora de Serviço"}');
    } catch (error) {
      // Reverter em caso de erro
      state = AsyncValue.data(currentValue);
      debugPrint('[ServiceStatus] Erro ao atualizar status: $error');
      rethrow;
    }
  }

  /// Define o status explicitamente
  Future<void> setStatus(bool emServico) async {
    if (state.valueOrNull == emServico) return; // Já está no estado desejado

    state = AsyncValue.data(emServico);

    try {
      final http = _ref.read(httpServiceProvider);
      await http.patch('/users/me/service-status', data: {
        'emServico': emServico,
      });

      await _ref.read(currentUserProvider.notifier).refreshUser();

      debugPrint('[ServiceStatus] Status definido para: ${emServico ? "Em Serviço" : "Fora de Serviço"}');
    } catch (error) {
      // Reverter em caso de erro
      state = AsyncValue.data(!emServico);
      debugPrint('[ServiceStatus] Erro ao definir status: $error');
      rethrow;
    }
  }
}
