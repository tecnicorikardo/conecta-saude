abstract class AppConstants {
  // ─── App ──────────────────────────────────────────────────────────────────
  static const String appName = 'Conecta Saúde';
  static const String appVersion = '1.0.0';

  // ─── API ──────────────────────────────────────────────────────────────────
  static const String apiBaseUrlDev = 'http://10.0.2.2:3000/api';
  static const String apiBaseUrlProd = 'https://api.conectasaude.com.br/api';

  // ─── Timeouts ─────────────────────────────────────────────────────────────
  static const int connectTimeoutMs = 10000;
  static const int receiveTimeoutMs = 15000;

  // ─── Edição de mensagens ──────────────────────────────────────────────────
  static const int messageEditWindowMinutes = 5;

  // ─── Hierarquia ──────────────────────────────────────────────────────────
  static const int hierarquiaDirecao = 1;
  static const int hierarquiaCoordenacao = 2;
  static const int hierarquiaSupervisao = 3;
  static const int hierarquiaFuncionario = 4;

  // ─── Paginação ────────────────────────────────────────────────────────────
  static const int pageSize = 30;
  static const int messageBatchSize = 50;

  // ─── Storage keys ─────────────────────────────────────────────────────────
  static const String keyFcmToken = 'fcm_token';
  static const String keyThemeMode = 'theme_mode';
}
