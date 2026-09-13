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
                when (call.method) {
                    "show" -> {
                        try {
                            result.success(notifications.show(
                                call.argument<String>("title") ?: "Conecta Saúde",
                                call.argument<String>("body") ?: "",
                                call.argument<String>("tag") ?: "chat",
                                call.argument<String>("type")
                            ))
                        } catch (error: Exception) {
                            result.error("notification_failed", error.message, null)
                        }
                    }
                    "updateWidget" -> {
                        try {
                            val isEmServico = call.argument<Boolean>("emServico") ?: true
                            val userName = call.argument<String>("userName") ?: "Conecta Saúde"
                            val token = call.argument<String>("token")

                            val prefs = getSharedPreferences(ServiceStatusWidgetProvider.PREFS_NAME, MODE_PRIVATE)
                            val editor = prefs.edit()
                                .putBoolean("flutter.widget_em_servico", isEmServico)
                                .putString("flutter.widget_user_name", userName)
                            if (token != null) {
                                editor.putString("flutter.widget_auth_token", token)
                            }
                            editor.apply()

                            ServiceStatusWidgetProvider.updateAllWidgets(this)
                            result.success(true)
                        } catch (error: Exception) {
                            result.error("widget_update_failed", error.message, null)
                        }
                    }
                    else -> result.notImplemented()
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
