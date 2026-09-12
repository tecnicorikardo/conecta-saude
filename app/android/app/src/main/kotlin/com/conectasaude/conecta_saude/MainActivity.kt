package com.conectasaude.conecta_saude

import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val notifications = AndroidPushNotifications(this)
        notifications.createChannels() // Mudou de createChannel() para createChannels()
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "conecta_saude/notifications")
            .setMethodCallHandler { call, result ->
                if (call.method != "show") {
                    result.notImplemented()
                } else {
                    try {
                        result.success(notifications.show(
                            call.argument<String>("title") ?: "Conecta Saúde",
                            call.argument<String>("body") ?: "",
                            call.argument<String>("tag") ?: "chat",
                            call.argument<String>("type") // Novo parâmetro
                        ))
                    } catch (error: Exception) {
                        result.error("notification_failed", error.message, null)
                    }
                }
            }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Bloqueio de capturas de tela (print), gravacao de tela e preview em apps recentes (LGPD / Seguranca Hospitalar)
        window.setFlags(
            WindowManager.LayoutParams.FLAG_SECURE,
            WindowManager.LayoutParams.FLAG_SECURE
        )
    }
}
