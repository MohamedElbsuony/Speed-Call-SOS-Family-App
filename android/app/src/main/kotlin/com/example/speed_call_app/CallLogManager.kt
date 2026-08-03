package com.example.speed_call_app

import android.content.Context
import android.content.pm.PackageManager
import android.provider.CallLog
import androidx.core.content.ContextCompat

class CallLogManager(private val context: Context) {

    fun getSystemCallLogs(limit: Int = 100): List<Map<String, Any?>> {
        val list = mutableListOf<Map<String, Any?>>()

        if (ContextCompat.checkSelfPermission(context, android.Manifest.permission.READ_CALL_LOG)
            != PackageManager.PERMISSION_GRANTED) {
            return list
        }

        val projection = arrayOf(
            CallLog.Calls._ID,
            CallLog.Calls.NUMBER,
            CallLog.Calls.CACHED_NAME,
            CallLog.Calls.TYPE,
            CallLog.Calls.DATE,
            CallLog.Calls.DURATION
        )

        try {
            val cursor = context.contentResolver.query(
                CallLog.Calls.CONTENT_URI,
                projection,
                null,
                null,
                "${CallLog.Calls.DATE} DESC LIMIT $limit"
            )

            cursor?.use {
                val numberIndex = it.getColumnIndex(CallLog.Calls.NUMBER)
                val nameIndex = it.getColumnIndex(CallLog.Calls.CACHED_NAME)
                val typeIndex = it.getColumnIndex(CallLog.Calls.TYPE)
                val dateIndex = it.getColumnIndex(CallLog.Calls.DATE)
                val durationIndex = it.getColumnIndex(CallLog.Calls.DURATION)
                val idIndex = it.getColumnIndex(CallLog.Calls._ID)

                while (it.moveToNext()) {
                    val id = if (idIndex >= 0) it.getString(idIndex) else System.currentTimeMillis().toString()
                    val number = if (numberIndex >= 0) it.getString(numberIndex) ?: "" else ""
                    val name = if (nameIndex >= 0) it.getString(nameIndex) ?: "" else ""
                    val typeInt = if (typeIndex >= 0) it.getInt(typeIndex) else 1
                    val dateLong = if (dateIndex >= 0) it.getLong(dateIndex) else System.currentTimeMillis()
                    val duration = if (durationIndex >= 0) it.getInt(durationIndex) else 0

                    val typeStr = when (typeInt) {
                        CallLog.Calls.INCOMING_TYPE -> "incoming"
                        CallLog.Calls.OUTGOING_TYPE -> "outgoing"
                        CallLog.Calls.MISSED_TYPE -> "missed"
                        CallLog.Calls.REJECTED_TYPE -> "rejected"
                        else -> "incoming"
                    }

                    list.add(
                        mapOf(
                            "id" to id,
                            "phoneNumber" to number,
                            "contactName" to (if (name.isNotEmpty()) name else number),
                            "callType" to typeStr,
                            "timestamp" to dateLong,
                            "durationSeconds" to duration
                        )
                    )
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }

        return list
    }
}
