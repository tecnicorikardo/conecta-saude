package com.conectasaude.conecta_saude

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL
import kotlin.concurrent.thread

/**
 * ServiceStatusWidgetProvider
 * Widget nativo REDONDO (1x1) para a tela inicial do Android.
 * 1 Toque: Alterna entre Em Serviço (Verde) e Fora de Serviço (Cinza) em background.
 */
class ServiceStatusWidgetProvider : AppWidgetProvider() {

    companion object {
        const val ACTION_TOGGLE_STATUS = "com.conectasaude.conecta_saude.ACTION_TOGGLE_STATUS"
        const val PREFS_NAME = "FlutterSharedPreferences"

        fun updateAllWidgets(context: Context) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val componentName = ComponentName(context, ServiceStatusWidgetProvider::class.java)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(componentName)
            val intent = Intent(context, ServiceStatusWidgetProvider::class.java).apply {
                action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, appWidgetIds)
            }
            context.sendBroadcast(intent)
        }
    }

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == ACTION_TOGGLE_STATUS) {
            toggleServiceStatus(context)
        }
    }

    private fun updateWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
        val views = RemoteViews(context.packageName, R.layout.widget_service_status)
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

        val isEmServico = prefs.getBoolean("flutter.widget_em_servico", true)

        if (isEmServico) {
            views.setInt(R.id.widget_root_layout, "setBackgroundResource", R.drawable.widget_background_on)
            views.setTextViewText(R.id.widget_status_label, "EM SERVIÇO")
        } else {
            views.setInt(R.id.widget_root_layout, "setBackgroundResource", R.drawable.widget_background_off)
            views.setTextViewText(R.id.widget_status_label, "FORA SERVIÇO")
        }

        val toggleIntent = Intent(context, ServiceStatusWidgetProvider::class.java).apply {
            action = ACTION_TOGGLE_STATUS
        }
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            appWidgetId,
            toggleIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_root_layout, pendingIntent)

        appWidgetManager.updateAppWidget(appWidgetId, views)
    }

    private fun toggleServiceStatus(context: Context) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val currentStatus = prefs.getBoolean("flutter.widget_em_servico", true)
        val newStatus = !currentStatus
        val token = prefs.getString("flutter.widget_auth_token", null)

        // 1. Atualização visual instantânea (otimista) no widget
        prefs.edit().putBoolean("flutter.widget_em_servico", newStatus).apply()
        updateAllWidgets(context)

        // 2. Disparo assíncrono em background para atualizar no PostgreSQL
        if (!token.isNullOrEmpty()) {
            thread {
                try {
                    val url = URL("https://conecta-saude-backende.onrender.com/api/users/me/service-status")
                    val conn = url.openConnection() as HttpURLConnection
                    conn.requestMethod = "PATCH"
                    conn.setRequestProperty("Content-Type", "application/json")
                    conn.setRequestProperty("Authorization", "Bearer $token")
                    conn.doOutput = true
                    conn.connectTimeout = 15000
                    conn.readTimeout = 15000

                    val jsonInput = JSONObject().put("emServico", newStatus).toString()
                    conn.outputStream.use { os ->
                        os.write(jsonInput.toByteArray(Charsets.UTF_8))
                    }

                    val code = conn.responseCode
                    if (code in 200..299) {
                        // Sucesso: mantém novo status
                    } else if (code == 401 || code == 403) {
                        // Token expirado ou sem autorização: reverte
                        prefs.edit().putBoolean("flutter.widget_em_servico", currentStatus).apply()
                        updateAllWidgets(context)
                    }
                    conn.disconnect()
                } catch (e: Exception) {
                    // Em caso de falha de conexão de rede, mantém o estado offline
                }
            }
        }
    }
}
