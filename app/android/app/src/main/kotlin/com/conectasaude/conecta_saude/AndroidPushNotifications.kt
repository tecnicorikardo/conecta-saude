package com.conectasaude.conecta_saude

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build

class AndroidPushNotifications(private val context: Context) {
    private val manager = context.getSystemService(NotificationManager::class.java)

    fun createChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            // Canal de Emergências (VERMELHO) - Prioridade Máxima
            manager.createNotificationChannel(
                NotificationChannel(CHANNEL_EMERGENCY, "Emergências Médicas", NotificationManager.IMPORTANCE_HIGH).apply {
                    description = "Alertas críticos (PCR, trauma, O₂)"
                    enableVibration(true)
                    vibrationPattern = longArrayOf(0, 500, 200, 500, 200, 500) // Vibração intensa
                    setShowBadge(true)
                }
            )

            // Canal de Alertas/Comunicados (AMARELO) - Alta Prioridade
            manager.createNotificationChannel(
                NotificationChannel(CHANNEL_ALERTS, "Comunicados e Alertas", NotificationManager.IMPORTANCE_HIGH).apply {
                    description = "Comunicados oficiais da instituição"
                    enableVibration(true)
                    vibrationPattern = longArrayOf(0, 300, 150, 300) // Vibração moderada
                    setShowBadge(true)
                }
            )

            // Canal de Mensagens (AZUL) - Prioridade Padrão
            manager.createNotificationChannel(
                NotificationChannel(CHANNEL_MESSAGES, "Mensagens e Conversas", NotificationManager.IMPORTANCE_DEFAULT).apply {
                    description = "Conversas individuais e grupos"
                    enableVibration(true)
                    vibrationPattern = longArrayOf(0, 250) // Vibração leve
                    setShowBadge(true)
                }
            )
        }
    }

    fun show(title: String, body: String, tag: String, type: String?): Boolean {
        if (Build.VERSION.SDK_INT >= 33 &&
            context.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) {
            return false
        }
        if (!manager.areNotificationsEnabled()) return false
        
        createChannels() // Garante que canais existem
        
        // Determinar canal e cor baseado no tipo
        val channelId: String
        val color: Int
        
        when (type) {
            "emergency" -> {
                channelId = CHANNEL_EMERGENCY
                color = 0xFFD32F2F.toInt() // Vermelho
            }
            "alert" -> {
                channelId = CHANNEL_ALERTS
                color = 0xFFFFA000.toInt() // Amarelo
            }
            else -> {
                channelId = CHANNEL_MESSAGES
                color = 0xFF005CA9.toInt() // Azul SUS
            }
        }
        
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        val pendingIntent = PendingIntent.getActivity(
            context, 0, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(context, channelId)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(context).setPriority(Notification.PRIORITY_HIGH)
                .setDefaults(Notification.DEFAULT_ALL)
        }
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            builder.setColorized(true)
        }
        manager.notify(tag, 0, builder
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(Notification.BigTextStyle().bigText(body))
            .setCategory(Notification.CATEGORY_MESSAGE)
            .setVisibility(Notification.VISIBILITY_PRIVATE)
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)
            .setColor(color)     // Aplica a cor
            .build())
        return true
    }

    companion object {
        const val CHANNEL_EMERGENCY = "conecta_emergency"
        const val CHANNEL_ALERTS = "conecta_alerts"
        const val CHANNEL_MESSAGES = "conecta_messages"
    }
}
