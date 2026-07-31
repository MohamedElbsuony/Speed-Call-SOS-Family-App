package com.example.speed_call_app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.graphics.*
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import org.json.JSONObject

object WidgetRenderUtils {

    fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
        val prefs = context.getSharedPreferences("widget_configs", Context.MODE_PRIVATE)
        val jsonStr = prefs.getString("widget_$appWidgetId", null) ?: return

        try {
            val json = JSONObject(jsonStr)
            val contactName = json.optString("contactName", "Speed Call")
            val phoneNumber = json.optString("phoneNumber", "")
            val photoPath = json.optString("photoPath", "")
            val widgetSize = json.optString("widgetSize", "small") // small, medium, large
            val shape = json.optString("imageShape", "circular") // circular, rounded, square
            val backgroundColor = json.optInt("backgroundColor", Color.parseColor("#1F1F2F"))
            val textColor = json.optInt("textColor", Color.parseColor("#FFFFFF"))
            val showName = json.optBoolean("showName", true)
            val showPhone = json.optBoolean("showPhone", true)
            val borderRadius = json.optDouble("borderRadius", 16.0).toFloat()
            val simSelectionMode = json.optInt("simSelectionMode", 0) // 0: Default, 1: SIM 1, 2: SIM 2, 3: Ask

            val layoutId = when (widgetSize.lowercase()) {
                "medium" -> R.layout.widget_medium
                "large" -> R.layout.widget_large
                else -> R.layout.widget_small
            }

            val views = RemoteViews(context.packageName, layoutId)

            // Setup PendingIntent for One-Tap Direct Dial
            val callIntent = Intent(context, DirectDialWidgetProvider::class.java).apply {
                action = DirectDialWidgetProvider.ACTION_DIRECT_CALL
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
                putExtra("phoneNumber", phoneNumber)
                putExtra("simSelectionMode", simSelectionMode)
                data = Uri.parse("speedcall://widget/$appWidgetId")
            }

            val pendingIntent = PendingIntent.getBroadcast(
                context,
                appWidgetId,
                callIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            views.setOnClickPendingIntent(R.id.widget_container, pendingIntent)

            // Background
            val bgBitmap = createBackgroundBitmap(300, 300, backgroundColor, borderRadius)
            views.setImageViewBitmap(R.id.widget_background_image, bgBitmap)

            // Name & Phone
            if (showName) {
                views.setViewVisibility(R.id.widget_name, View.VISIBLE)
                views.setTextViewText(R.id.widget_name, contactName)
                views.setTextColor(R.id.widget_name, textColor)
            } else {
                views.setViewVisibility(R.id.widget_name, View.GONE)
            }

            if (widgetSize.lowercase() != "small") {
                if (showPhone && phoneNumber.isNotEmpty()) {
                    views.setViewVisibility(R.id.widget_phone, View.VISIBLE)
                    views.setTextViewText(R.id.widget_phone, phoneNumber)
                    views.setTextColor(R.id.widget_phone, textColor)
                } else {
                    views.setViewVisibility(R.id.widget_phone, View.GONE)
                }
            }

            if (widgetSize.lowercase() == "large") {
                val simLabel = when (simSelectionMode) {
                    1 -> "SIM 1"
                    2 -> "SIM 2"
                    3 -> "Ask"
                    else -> "Default SIM"
                }
                views.setTextViewText(R.id.widget_sim_badge, simLabel)
            }

            // Avatar
            val avatarBitmap = loadAvatarBitmap(context, photoPath, contactName, shape)
            views.setImageViewBitmap(R.id.widget_avatar, avatarBitmap)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun createBackgroundBitmap(width: Int, height: Int, color: Int, radiusDp: Float): Bitmap {
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            this.color = color
            style = Paint.Style.FILL
        }
        val rectF = RectF(0f, 0f, width.toFloat(), height.toFloat())
        canvas.drawRoundRect(rectF, radiusDp, radiusDp, paint)
        return bitmap
    }

    private fun loadAvatarBitmap(context: Context, photoPath: String, name: String, shape: String): Bitmap {
        var srcBitmap: Bitmap? = null
        if (photoPath.isNotEmpty()) {
            try {
                srcBitmap = BitmapFactory.decodeFile(photoPath)
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }

        if (srcBitmap == null) {
            srcBitmap = createPlaceholderAvatar(name)
        }

        return cropBitmapToShape(srcBitmap, shape)
    }

    private fun createPlaceholderAvatar(name: String): Bitmap {
        val width = 120
        val height = 120
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.parseColor("#4A6572")
            style = Paint.Style.FILL
        }
        canvas.drawRect(0f, 0f, width.toFloat(), height.toFloat(), paint)

        val initial = if (name.isNotEmpty()) name.substring(0, 1).uppercase() else "?"
        val textPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.WHITE
            textSize = 50f
            textAlign = Paint.Align.CENTER
            typeface = Typeface.DEFAULT_BOLD
        }
        val xPos = canvas.width / 2f
        val yPos = (canvas.height / 2f) - ((textPaint.descent() + textPaint.ascent()) / 2f)
        canvas.drawText(initial, xPos, yPos, textPaint)

        return bitmap
    }

    private fun cropBitmapToShape(src: Bitmap, shape: String): Bitmap {
        val size = Math.min(src.width, src.height)
        val output = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(output)

        val paint = Paint(Paint.ANTI_ALIAS_FLAG)
        val rect = Rect(0, 0, size, size)
        val rectF = RectF(rect)

        canvas.drawARGB(0, 0, 0, 0)
        paint.isFilterBitmap = true

        when (shape.lowercase()) {
            "circular" -> {
                canvas.drawRoundRect(rectF, size / 2f, size / 2f, paint)
            }
            "rounded" -> {
                canvas.drawRoundRect(rectF, 24f, 24f, paint)
            }
            else -> { // square
                canvas.drawRect(rectF, paint)
            }
        }

        paint.xfermode = PorterDuffXfermode(PorterDuff.Mode.SRC_IN)
        canvas.drawBitmap(src, rect, rect, paint)

        return output
    }
}
