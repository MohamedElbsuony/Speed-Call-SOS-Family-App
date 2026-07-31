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
import android.widget.RemoteViews

class FamilySosWidgetProvider : AppWidgetProvider() {

    companion object {
        const val ACTION_TRIGGER_SOS = "com.example.speed_call_app.ACTION_TRIGGER_SOS"
    }

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_sos)

            val redBgBitmap = createCompactRedBitmap(120, 120)
            views.setImageViewBitmap(R.id.widget_background_image, redBgBitmap)

            val intent = Intent(context, MainActivity::class.java).apply {
                action = ACTION_TRIGGER_SOS
                putExtra("action", "trigger_family_sos")
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
            }

            val pendingIntent = PendingIntent.getActivity(
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
            val launchIntent = Intent(context, MainActivity::class.java).apply {
                action = ACTION_TRIGGER_SOS
                putExtra("action", "trigger_family_sos")
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
            }
            context.startActivity(launchIntent)
        }
    }
}
