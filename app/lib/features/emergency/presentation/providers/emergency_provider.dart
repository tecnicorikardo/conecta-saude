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

  const EmergencyState({
    this.isLoading = false,
    this.activeAlert,
    this.history = const [],
    this.errorMessage,
  });

  bool get hasActiveAlert => activeAlert != null && activeAlert!.isAtivo;

  EmergencyState copyWith({
    bool? isLoading,
    EmergencyAlertEntity? Function()? activeAlert,
    List<EmergencyAlertEntity>? history,
    String? errorMessage,
  }) {
    return EmergencyState(
      isLoading: isLoading ?? this.isLoading,
      activeAlert: activeAlert != null ? activeAlert() : this.activeAlert,
      history: history ?? this.history,
      errorMessage: errorMessage,
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
    try {
      final active = await _repository.getActiveEmergency();
      if (state.activeAlert != active) {
        state = state.copyWith(activeAlert: () => active);
      }
    } catch (_) {}
  }

  Future<void> loadData() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final active = await _repository.getActiveEmergency();
      final history = await _repository.getEmergencyHistory();
      state = state.copyWith(
        isLoading: false,
        activeAlert: () => active,
        history: history,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Erro ao carregar dados de emergência.',
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
      state = state.copyWith(
        activeAlert: () => created,
        history: [created, ...state.history],
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> resolveEmergency(String id, {String? observacao}) async {
    try {
      final success = await _repository.resolveEmergencyAlert(id, observacao: observacao);
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
