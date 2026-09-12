class NotificationConstants {
  NotificationConstants._();

  // Tipos de notificação
  static const String typeMessage = 'message';
  static const String typeAlert = 'alert';
  static const String typeEmergency = 'emergency';

  // Cores em hexadecimal
  static const String colorMessage = '#005CA9';    // Azul SUS
  static const String colorAlert = '#FFA000';      // Amarelo Âmbar
  static const String colorEmergency = '#D32F2F';  // Vermelho Material

  // Canais Android
  static const String channelMessages = 'conecta_messages';
  static const String channelAlerts = 'conecta_alerts';
  static const String channelEmergency = 'conecta_emergency';

  // Nomes de exibição dos canais
  static const String channelNameMessages = 'Mensagens e Conversas';
  static const String channelNameAlerts = 'Comunicados e Alertas';
  static const String channelNameEmergency = 'Emergências Médicas';

  // Descrições dos canais
  static const String channelDescMessages = 'Conversas individuais e grupos';
  static const String channelDescAlerts = 'Comunicados oficiais da instituição';
  static const String channelDescEmergency = 'Alertas críticos (PCR, trauma, O₂)';
}
