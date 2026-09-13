import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class BiometricService {
  BiometricService._();
  static final BiometricService instance = BiometricService._();

  final LocalAuthentication _auth = LocalAuthentication();
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  static const _keyEnabled = 'biometric_enabled';
  static const _keySavedEmail = 'biometric_saved_email';
  static const _keySavedPassword = 'biometric_saved_password';

  /// Verifica se o dispositivo possui hardware biométrico compatível
  Future<bool> isBiometricAvailable() async {
    if (kIsWeb) return false;
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isDeviceSupported = await _auth.isDeviceSupported();
      return canCheck && isDeviceSupported;
    } catch (e) {
      debugPrint('[BiometricService] Erro ao checar biometria: $e');
      return false;
    }
  }

  /// Verifica se a biometria está ativada nas preferências do app
  Future<bool> isBiometricEnabled() async {
    if (kIsWeb) return false;
    try {
      final val = await _storage.read(key: _keyEnabled);
      return val == 'true';
    } catch (_) {
      return false;
    }
  }

  /// Salva credenciais seguras para autenticação rápida com biometria
  Future<void> saveBiometricCredentials({
    required String email,
    required String password,
  }) async {
    if (kIsWeb) return;
    try {
      await _storage.write(key: _keyEnabled, value: 'true');
      await _storage.write(key: _keySavedEmail, value: email);
      await _storage.write(key: _keySavedPassword, value: password);
    } catch (e) {
      debugPrint('[BiometricService] Erro ao salvar credenciais: $e');
    }
  }

  /// Limpa credenciais biométricas (desativa biometria)
  Future<void> clearBiometricCredentials() async {
    if (kIsWeb) return;
    try {
      await _storage.delete(key: _keyEnabled);
      await _storage.delete(key: _keySavedEmail);
      await _storage.delete(key: _keySavedPassword);
    } catch (e) {
      debugPrint('[BiometricService] Erro ao limpar biometria: $e');
    }
  }

  /// Obtém as credenciais salvas apenas se o usuário autenticar biometricamente
  Future<Map<String, String>?> authenticateAndGetCredentials() async {
    if (kIsWeb) return null;
    try {
      final available = await isBiometricAvailable();
      if (!available) return null;

      final enabled = await isBiometricEnabled();
      if (!enabled) return null;

      final email = await _storage.read(key: _keySavedEmail);
      final password = await _storage.read(key: _keySavedPassword);

      if (email == null || password == null) return null;

      final didAuth = await _auth.authenticate(
        localizedReason: 'Toque o sensor de biometria para acessar o Conecta Saúde',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );

      if (didAuth) {
        return {
          'email': email,
          'password': password,
        };
      }
    } catch (e) {
      debugPrint('[BiometricService] Falha na autenticação biométrica: $e');
    }
    return null;
  }
}
