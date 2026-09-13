import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/http_service.dart';
import '../../domain/entities/user_entity.dart';
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
    _ref.listen<AsyncValue<UserEntity?>>(currentUserProvider, (prev, next) {
      final user = next.valueOrNull;
      if (user != null) {
        state = AsyncValue.data(user.emServico);
        _syncNativeWidget(user.emServico, user.nome);
      }
    });

    final user = _ref.read(currentUserProvider).valueOrNull;
    if (user != null) {
      state = AsyncValue.data(user.emServico);
      _syncNativeWidget(user.emServico, user.nome);
    } else {
      state = const AsyncValue.data(true); // default
    }
  }

  /// Alterna o status de serviço (Em Serviço ↔ Fora de Serviço)
  Future<void> toggle([bool? targetValue]) async {
    final user = _ref.read(currentUserProvider).valueOrNull;
    final currentStatus = user?.emServico ?? state.valueOrNull ?? true;
    final newValue = targetValue ?? !currentStatus;

    // Atualização otimista no currentUserNotifier imediatamente para atualizar toda a UI
    if (user != null) {
      _ref.read(currentUserProvider.notifier).setUser(user.copyWith(emServico: newValue));
    }
    state = AsyncValue.data(newValue);

    try {
      final http = _ref.read(httpServiceProvider);
      await http.patch('/users/me/service-status', data: {
        'emServico': newValue,
      });

      // Recarregar usuário do backend para garantir sincronização final
      await _ref.read(currentUserProvider.notifier).refreshUser();

      // Sincronizar com o Widget de Tela Inicial no Android
      _syncNativeWidget(newValue, user?.nome);

      debugPrint('[ServiceStatus] Status alterado com sucesso para: ${newValue ? "Em Serviço" : "Fora de Serviço"}');
    } catch (error) {
      // Reverter em caso de erro
      if (user != null) {
        _ref.read(currentUserProvider.notifier).setUser(user.copyWith(emServico: currentStatus));
      }
      state = AsyncValue.data(currentStatus);
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

      _syncNativeWidget(emServico, _ref.read(currentUserProvider).valueOrNull?.nome);

      debugPrint('[ServiceStatus] Status definido para: ${emServico ? "Em Serviço" : "Fora de Serviço"}');
    } catch (error) {
      // Reverter em caso de erro
      state = AsyncValue.data(!emServico);
      debugPrint('[ServiceStatus] Erro ao definir status: $error');
      rethrow;
    }
  }

  /// Sincroniza o status com o AppWidget da tela inicial do Android
  Future<void> _syncNativeWidget(bool emServico, String? userName) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();
      await const MethodChannel('conecta_saude/notifications').invokeMethod('updateWidget', {
        'emServico': emServico,
        'userName': userName ?? 'Conecta Saúde',
        if (token != null) 'token': token,
      });
      debugPrint('[ServiceStatus] Widget nativo da tela inicial atualizado.');
    } catch (e) {
      debugPrint('[ServiceStatus] Falha ao atualizar widget nativo: $e');
    }
  }
}
