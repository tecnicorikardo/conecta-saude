import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/domain/entities/user_entity.dart';
import '../../features/auth/presentation/providers/current_user_provider.dart';
import '../../core/constants/app_constants.dart';

// ─── Modelo de permissões ─────────────────────────────────────────────────────
class UserPermissions {
  final UserEntity? user;

  const UserPermissions(this.user);

  int get nivel => user?.hierarquiaNivel ?? AppConstants.hierarquiaFuncionario;
  bool get isLoggedIn => user != null && (user?.ativo ?? false);

  // ─── Níveis ────────────────────────────────────────────────────────────────
  bool get isDirecao      => nivel == AppConstants.hierarquiaDirecao;
  bool get isCoordenacao  => nivel == AppConstants.hierarquiaCoordenacao;
  bool get isSupervisao   => nivel == AppConstants.hierarquiaSupervisao;
  bool get isFuncionario  => nivel == AppConstants.hierarquiaFuncionario;

  /// Nível 1 ou 2 — acesso administrativo
  bool get isAdmin        => nivel <= AppConstants.hierarquiaCoordenacao;

  /// Nível 1, 2 ou 3 — acesso de liderança
  bool get isLideranca    => nivel <= AppConstants.hierarquiaSupervisao;

  // ─── Permissões de navegação ───────────────────────────────────────────────

  /// Pode ver aba Administração no menu
  bool get canAccessAdmin => isDirecao;

  /// Pode ver painel de funcionários
  bool get canManageEmployees => isDirecao;

  /// Pode criar comunicados
  bool get canCreateAnnouncement => isAdmin;

  /// Pode ver estatísticas de leitura dos comunicados
  bool get canViewAnnouncementStats => isAdmin;

  /// Pode criar canais
  bool get canCreateChannel => isAdmin;

  /// Pode ver denúncias (admin)
  bool get canViewReports => isAdmin;

  /// Pode ver auditoria
  bool get canViewAudit => isDirecao;

  /// Pode ver canal de emergência
  bool get canAccessEmergency => true; // todos podem ver emergência

  /// Pode criar mensagem no canal de emergência
  bool get canPostEmergency => isLideranca;

  /// Pode ver conversas do setor inteiro (não só as suas)
  bool get canViewAllSectorConversations => isLideranca;

  /// Pode moderar mensagens (excluir mensagens de outros)
  bool get canModerateMessages => isDirecao;

  /// Pode ativar/desativar funcionários
  bool get canToggleUserStatus => isDirecao;

  // ─── Label e cor do badge ──────────────────────────────────────────────────
  String get hierarquiaLabel {
    switch (nivel) {
      case AppConstants.hierarquiaDirecao:     return 'DIREÇÃO';
      case AppConstants.hierarquiaCoordenacao: return 'COORDENAÇÃO';
      case AppConstants.hierarquiaSupervisao:  return 'SUPERVISÃO';
      default:                                  return 'FUNCIONÁRIO';
    }
  }

  /// Cor associada ao nível hierárquico
  static const _levelColors = {
    1: 0xFF1565C0, // azul SUS — Direção
    2: 0xFF1976D2, // azul médio — Coordenação
    3: 0xFF42A5F5, // azul claro — Supervisão
    4: 0xFF8FA3BC, // cinza azulado — Funcionário
  };

  int get levelColorHex => _levelColors[nivel] ?? 0xFF8FA3BC;
}

// ─── Provider global de permissões ────────────────────────────────────────────
final permissionsProvider = Provider<UserPermissions>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  return UserPermissions(userAsync.value);
});
