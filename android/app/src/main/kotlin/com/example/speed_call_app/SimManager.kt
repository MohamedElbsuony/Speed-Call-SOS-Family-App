package com.example.speed_call_app

import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.telecom.PhoneAccountHandle
import android.telecom.TelecomManager
import android.telephony.SubscriptionInfo
import android.telephony.SubscriptionManager
import android.telephony.TelephonyManager
import androidx.core.content.ContextCompat

data class SimInfo(
    val slotIndex: Int,
    val subscriptionId: Int,
    val carrierName: String,
    val displayName: String,
    val iccId: String?
)

class SimManager(private val context: Context) {

    fun getAvailableSims(): List<SimInfo> {
        val simList = mutableListOf<SimInfo>()
        
        // 1. Check active subscriptions if READ_PHONE_STATE is granted
        if (ContextCompat.checkSelfPermission(context, android.Manifest.permission.READ_PHONE_STATE) 
            == PackageManager.PERMISSION_GRANTED) {
            try {
                val subscriptionManager = context.getSystemService(Context.TELEPHONY_SUBSCRIPTION_SERVICE) as? SubscriptionManager
                if (subscriptionManager != null) {
                    val activeList: List<SubscriptionInfo>? = subscriptionManager.activeSubscriptionInfoList
                    if (!activeList.isNullOrEmpty()) {
                        for (info in activeList) {
                            val carrierName = info.carrierName?.toString() ?: "SIM ${info.simSlotIndex + 1}"
                            val displayName = info.displayName?.toString() ?: carrierName
                            simList.add(
                                SimInfo(
                                    slotIndex = info.simSlotIndex,
                                    subscriptionId = info.subscriptionId,
                                    carrierName = carrierName,
                                    displayName = displayName,
                                    iccId = info.iccId
                                )
                            )
                        }
                    }
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }

        // 2. Hardware fallback: check modem count or telecom accounts if list size < 2
        if (simList.size < 2) {
            try {
                val telephonyManager = context.getSystemService(Context.TELEPHONY_SERVICE) as? TelephonyManager
                val phoneCount = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                    telephonyManager?.activeModemCount ?: 1
                } else {
                    telephonyManager?.phoneCount ?: 1
                }

                if (phoneCount >= 2 && simList.size < 2) {
                    return listOf(
                        SimInfo(slotIndex = 0, subscriptionId = 1, carrierName = "SIM 1", displayName = "SIM 1", iccId = ""),
                        SimInfo(slotIndex = 1, subscriptionId = 2, carrierName = "SIM 2", displayName = "SIM 2", iccId = "")
                    )
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }

        return simList
    }

    fun getPhoneAccountHandleForSubscription(subscriptionId: Int): PhoneAccountHandle? {
        val telecomManager = context.getSystemService(Context.TELECOM_SERVICE) as? TelecomManager ?: return null
        if (ContextCompat.checkSelfPermission(context, android.Manifest.permission.READ_PHONE_STATE) 
            != PackageManager.PERMISSION_GRANTED) {
            return null
        }

        try {
            val callCapableHandles = telecomManager.callCapablePhoneAccounts
            for (handle in callCapableHandles) {
                if (handle.id.contains(subscriptionId.toString())) {
                    return handle
                }
            }
            if (callCapableHandles.isNotEmpty()) {
                val index = if (subscriptionId >= 0 && subscriptionId < callCapableHandles.size) subscriptionId else 0
                return callCapableHandles[index]
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
        return null
    }
}
