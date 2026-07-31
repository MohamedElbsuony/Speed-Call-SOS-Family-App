package com.example.speed_call_app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.RectF
import android.net.Uri
import android.os.Build
import android.telephony.SmsManager
import android.widget.RemoteViews
import org.json.JSONObject
import java.net.URLEncoder

class FamilySosWidgetProvider : AppWidgetProvider() {

    companion object {
        const val ACTION_TRIGGER_SOS = "com.example.speed_call_app.ACTION_TRIGGER_SOS"
    }

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_sos)

            val redBgBitmap = createCompactRedBitmap(120, 120)
            views.setImageViewBitmap(R.id.widget_background_image, redBgBitmap)

            val intent = Intent(context, FamilySosWidgetProvider::class.java).apply {
                action = ACTION_TRIGGER_SOS
            }

            val pendingIntent = PendingIntent.getBroadcast(
                context,
                appWidgetId,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            views.setOnClickPendingIntent(R.id.widget_container, pendingIntent)
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }

    private fun createCompactRedBitmap(width: Int, height: Int): Bitmap {
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.parseColor("#D32F2F")
            style = Paint.Style.FILL
        }
        val rectF = RectF(0f, 0f, width.toFloat(), height.toFloat())
        canvas.drawRoundRect(rectF, width / 2f, height / 2f, paint)
        return bitmap
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == ACTION_TRIGGER_SOS) {
            executeImmediateBackgroundSos(context)
        }
    }

    private fun executeImmediateBackgroundSos(context: Context) {
        try {
            val prefs = context.getSharedPreferences("sos_prefs", Context.MODE_PRIVATE)
            val configString = prefs.getString("sos_config_json", null)

            var primaryNumber = ""
            var sosMessage = "⚠️ EMERGENCY ALERT! I am currently in a crisis. Please reach out to me immediately!"
            val emergencyContacts = mutableListOf<String>()
            var sosActionMode = 0 // 0: Call Only, 1: WhatsApp Only, 2: SMS Only

            if (!configString.isNullOrEmpty()) {
                try {
                    val json = JSONObject(configString)
                    primaryNumber = json.optString("primaryCallNumber", "")
                    sosMessage = json.optString("sosMessageText", sosMessage)
                    sosActionMode = json.optInt("sosActionMode", 0)

                    val contactsArray = json.optJSONArray("emergencyContacts")
                    if (contactsArray != null) {
                        for (i in 0 until contactsArray.length()) {
                            emergencyContacts.add(contactsArray.getString(i))
                        }
                    }
                } catch (e: Exception) {
                    e.printStackTrace()
                }
            }

            var targetCallNumber = primaryNumber.trim()
            if (targetCallNumber.isEmpty() && emergencyContacts.isNotEmpty()) {
                targetCallNumber = emergencyContacts.first().trim()
            }

            val fullSosText = "$sosMessage\n\n📍 موقع الطوارئ المباشر:\nhttps://maps.google.com/?q=EmergencyAlertLocation"

            // Mode 0: Voice Call Only (Default)
            if (sosActionMode == 0) {
                if (targetCallNumber.isNotEmpty()) {
                    DirectCallManager(context).placeDirectCall(targetCallNumber, 0, null)
                }
                return
            }

            // Mode 1: WhatsApp Message Only
            if (sosActionMode == 1) {
                val encodedText = URLEncoder.encode(fullSosText, "UTF-8")
                for (phone in emergencyContacts) {
                    val cleanPhone = phone.replace(Regex("[^0-9+]"), "").replace("+", "")
                    if (cleanPhone.isNotEmpty()) {
                        try {
                            val whatsappIntent = Intent(Intent.ACTION_VIEW, Uri.parse("https://wa.me/$cleanPhone?text=$encodedText")).apply {
                                flags = Intent.FLAG_ACTIVITY_NEW_TASK
                            }
                            context.startActivity(whatsappIntent)
                        } catch (_: Exception) {}
                    }
                }
                return
            }

            // Mode 2: Offline Direct SMS Only
            if (sosActionMode == 2) {
                val smsManager: SmsManager = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    context.getSystemService(SmsManager::class.java)
                } else {
                    SmsManager.getDefault()
                }
                for (phone in emergencyContacts) {
                    val cleanPhone = phone.replace(Regex("[^0-9+]"), "")
                    if (cleanPhone.isNotEmpty()) {
                        try {
                            val parts = smsManager.divideMessage(fullSosText)
                            if (parts.size > 1) {
                                smsManager.sendMultipartTextMessage(cleanPhone, null, parts, null, null)
                            } else {
                                smsManager.sendTextMessage(cleanPhone, null, fullSosText, null, null)
                            }
                        } catch (_: Exception) {}
                    }
                }
                return
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
}
