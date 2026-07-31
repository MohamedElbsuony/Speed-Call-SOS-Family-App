package com.example.speed_call_app

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import androidx.core.content.ContextCompat

class DirectDialWidgetProvider : AppWidgetProvider() {

    companion object {
        const val ACTION_DIRECT_CALL = "com.example.speed_call_app.ACTION_DIRECT_CALL"
    }

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            WidgetRenderUtils.updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onDeleted(context: Context, appWidgetIds: IntArray) {
        val prefs = context.getSharedPreferences("widget_configs", Context.MODE_PRIVATE)
        val editor = prefs.edit()
        for (id in appWidgetIds) {
            editor.remove("widget_$id")
        }
        editor.apply()
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)

        if (intent.action == ACTION_DIRECT_CALL) {
            val phoneNumber = intent.getStringExtra("phoneNumber") ?: ""
            val simSelectionMode = intent.getIntExtra("simSelectionMode", 0)

            if (phoneNumber.isNotEmpty()) {
                val hasCallPermission = ContextCompat.checkSelfPermission(
                    context,
                    android.Manifest.permission.CALL_PHONE
                ) == PackageManager.PERMISSION_GRANTED

                if (hasCallPermission) {
                    val directCallManager = DirectCallManager(context)
                    directCallManager.placeDirectCall(phoneNumber, simSelectionMode, null)
                } else {
                    // Permission revoked/missing: launch MainActivity to prompt user
                    val launchIntent = Intent(context, MainActivity::class.java).apply {
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                        putExtra("pending_call_number", phoneNumber)
                        putExtra("pending_call_sim", simSelectionMode)
                        putExtra("action", "request_permission_and_call")
                    }
                    context.startActivity(launchIntent)
                }
            }
        }
    }
}
