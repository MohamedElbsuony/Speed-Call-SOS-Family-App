package com.example.speed_call_app

import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.telecom.PhoneAccountHandle
import android.telecom.TelecomManager
import androidx.core.content.ContextCompat

class DirectCallManager(private val context: Context) {

    fun placeDirectCall(phoneNumber: String, simSelectionMode: Int, subscriptionId: Int?): Boolean {
        if (ContextCompat.checkSelfPermission(context, android.Manifest.permission.CALL_PHONE) 
            != PackageManager.PERMISSION_GRANTED) {
            return false
        }

        val cleanNumber = phoneNumber.replace(Regex("[^0-9+#*]"), "")
        if (cleanNumber.isEmpty()) return false

        val intent = Intent(Intent.ACTION_CALL).apply {
            data = Uri.parse("tel:$cleanNumber")
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
        }

        val simManager = SimManager(context)

        when (simSelectionMode) {
            1 -> { // Always SIM 1
                applySimToIntent(intent, 0, subscriptionId, simManager)
            }
            2 -> { // Always SIM 2
                applySimToIntent(intent, 1, subscriptionId, simManager)
            }
            3 -> { // Ask Every Time: Use ACTION_DIAL or let TelecomManager prompt
                intent.action = Intent.ACTION_DIAL
            }
            else -> { // Default SIM: ACTION_CALL without specific SIM handle
            }
        }

        return try {
            context.startActivity(intent)
            true
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }

    private fun applySimToIntent(intent: Intent, targetSlot: Int, explicitSubId: Int?, simManager: SimManager) {
        val availableSims = simManager.getAvailableSims()
        val targetSim = availableSims.firstOrNull { it.slotIndex == targetSlot } 
            ?: availableSims.firstOrNull { explicitSubId != null && it.subscriptionId == explicitSubId }

        if (targetSim != null) {
            val handle = simManager.getPhoneAccountHandleForSubscription(targetSim.subscriptionId)
            if (handle != null) {
                intent.putExtra(TelecomManager.EXTRA_PHONE_ACCOUNT_HANDLE, handle)
            }
            // Fallbacks for various OEM dual SIM implementations
            intent.putExtra("com.android.phone.force.slot", targetSlot)
            intent.putExtra("Cdma_Sub", targetSlot)
            intent.putExtra("simSlot", targetSlot)
            intent.putExtra("subscription", targetSim.subscriptionId)
        }
    }
}
