import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/emergency_entity.dart';
import '../../domain/repositories/emergency_repository.dart';
import '../../data/repositories/emergency_repository_impl.dart';

class EmergencyState {
  final bool isLoading;
  final EmergencyAlertEntity? activeAlert;
  final List<EmergencyAlertEntity> history;
  final String? errorMessage;
  final bool statusConfirmed;
  final String? statusError;

  const EmergencyState({
    this.isLoading = false,
    this.activeAlert,
    this.history = const [],
    this.errorMessage,
    this.statusConfirmed = false,
    this.statusError,
  });

  bool get hasActiveAlert => activeAlert != null && activeAlert!.isAtivo;

  EmergencyState copyWith({
    bool? isLoading,
    EmergencyAlertEntity? Function()? activeAlert,
    List<EmergencyAlertEntity>? history,
    String? errorMessage,
    bool? statusConfirmed,
    String? Function()? statusError,
  }) {
    return EmergencyState(
      isLoading: isLoading ?? this.isLoading,
      activeAlert: activeAlert != null ? activeAlert() : this.activeAlert,
      history: history ?? this.history,
      errorMessage: errorMessage,
      statusConfirmed: statusConfirmed ?? this.statusConfirmed,
      statusError: statusError != null ? statusError() : this.statusError,
    );
  }
}

class EmergencyNotifier extends StateNotifier<EmergencyState> {
  final EmergencyRepository _repository;
  Timer? _pollingTimer;

  EmergencyNotifier(this._repository) : super(const EmergencyState()) {
    loadData();
    _startPolling();
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      _pollActive();
    });
  }

  Future<void> _pollActive() async {
    if (!mounted || state.isLoading) return;
    try {
      final active = await _repository.getActiveEmergency();
      if (!mounted) return;
      state = state.copyWith(
          activeAlert: () => active,
          statusConfirmed: true,
          statusError: () => null);
    } catch (_) {
      if (!mounted) return;
      state = state.copyWith(
          statusConfirmed: false,
          statusError: () =>
              'Não foi possível confirmar o status de emergência. Atualize para tentar novamente.');
    }
  }

  Future<void> loadData() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final active = await _repository.getActiveEmergency();
      if (!mounted) return;
      state = state.copyWith(
          activeAlert: () => active,
          statusConfirmed: true,
          statusError: () => null);
      final history = await _repository.getEmergencyHistory();
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        history: history,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Erro ao carregar dados de emergência.',
        statusConfirmed: false,
        statusError: () =>
            'Não foi possível confirmar o status de emergência. Atualize para tentar novamente.',
      );
    }
  }

  Future<bool> triggerEmergency({
    required EmergencyType tipo,
    required String titulo,
    String? descricao,
    required String localizacao,
  }) async {
    try {
      final created = await _repository.createEmergencyAlert(
        tipo: tipo,
        titulo: titulo,
        descricao: descricao,
        localizacao: localizacao,
      );
      if (!mounted) return false;
      state = state.copyWith(
        activeAlert: () => created,
        history: [created, ...state.history],
        statusConfirmed: true,
        statusError: () => null,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> resolveEmergency(String id, {String? observacao}) async {
    try {
      final success =
          await _repository.resolveEmergencyAlert(id, observacao: observacao);
      if (!mounted) return false;
      if (success) {
        state = state.copyWith(
          activeAlert: () => null,
        );
        await loadData();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }
}

final emergencyProvider =
    StateNotifierProvider<EmergencyNotifier, EmergencyState>((ref) {
  final repo = ref.watch(emergencyRepositoryProvider);
  return EmergencyNotifier(repo);
});
