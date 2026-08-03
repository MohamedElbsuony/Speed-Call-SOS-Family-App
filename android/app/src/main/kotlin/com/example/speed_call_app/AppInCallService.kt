package com.example.speed_call_app

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.telecom.Call
import android.telecom.CallAudioState
import android.telecom.InCallService
import android.telecom.VideoProfile
import android.util.Log

class AppInCallService : InCallService() {

    companion object {
        private const val TAG = "AppInCallService"
        var activeCall: Call? = null
        var listener: CallStateListener? = null

        fun answerCall() {
            try {
                activeCall?.answer(VideoProfile.STATE_AUDIO_ONLY)
            } catch (e: Exception) {
                Log.e(TAG, "Error answering call", e)
            }
        }

        fun rejectCall() {
            try {
                if (activeCall?.state == Call.STATE_RINGING) {
                    activeCall?.reject(false, null)
                } else {
                    activeCall?.disconnect()
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error rejecting call", e)
            }
        }

        fun hangUp() {
            try {
                activeCall?.disconnect()
            } catch (e: Exception) {
                Log.e(TAG, "Error hanging up call", e)
            }
        }

        fun playDtmf(digit: Char) {
            try {
                activeCall?.playDtmfTone(digit)
                Handler(Looper.getMainLooper()).postDelayed({
                    try {
                        activeCall?.stopDtmfTone()
                    } catch (_: Exception) {}
                }, 200)
            } catch (e: Exception) {
                Log.e(TAG, "Error playing DTMF tone", e)
            }
        }
    }

    interface CallStateListener {
        fun onCallStateChanged(stateMap: Map<String, Any?>)
    }

    private var callStartTime: Long = 0L
    private lateinit var callAudioRecorder: CallAudioRecorder

    override fun onCreate() {
        super.onCreate()
        callAudioRecorder = CallAudioRecorder(this)
    }

    private val callCallback = object : Call.Callback() {
        override fun onStateChanged(call: Call, state: Int) {
            super.onStateChanged(call, state)
            handleCallStateChange(call, state)
        }
    }

    override fun onCallAdded(call: Call) {
        super.onCallAdded(call)
        activeCall = call
        call.registerCallback(callCallback)
        handleCallStateChange(call, call.state)

        // Launch app activity to display full-screen custom UI
        launchInCallUi()
    }

    override fun onCallRemoved(call: Call) {
        super.onCallRemoved(call)
        call.unregisterCallback(callCallback)
        if (activeCall == call) {
            activeCall = null
            notifyCallEnded(call)
        }
    }

    private fun handleCallStateChange(call: Call, state: Int) {
        val number = extractPhoneNumber(call)

        val stateString = when (state) {
            Call.STATE_RINGING -> "RINGING"
            Call.STATE_DIALING, Call.STATE_CONNECTING -> "DIALING"
            Call.STATE_ACTIVE -> {
                if (callStartTime == 0L) {
                    callStartTime = System.currentTimeMillis()
                    // Automatically start recording audio when call connects
                    callAudioRecorder.startRecording(number)
                }
                "ACTIVE"
            }
            Call.STATE_HOLDING -> "HOLDING"
            Call.STATE_DISCONNECTED, Call.STATE_DISCONNECTING -> {
                "DISCONNECTED"
            }
            else -> "UNKNOWN"
        }

        val isIncoming = state == Call.STATE_RINGING || (call.details?.callDirection == Call.Details.DIRECTION_INCOMING)

        var recordedPath: String? = null
        if (state == Call.STATE_DISCONNECTED || state == Call.STATE_DISCONNECTING) {
            if (callAudioRecorder.isRecording) {
                recordedPath = callAudioRecorder.stopRecording()
            }
        }

        val map = mutableMapOf<String, Any?>(
            "state" to stateString,
            "phoneNumber" to number,
            "isIncoming" to isIncoming,
            "startTime" to callStartTime,
            "callDuration" to if (callStartTime > 0) (System.currentTimeMillis() - callStartTime) / 1000 else 0
        )

        if (!recordedPath.isNullOrEmpty()) {
            map["recordedFilePath"] = recordedPath
        }

        Handler(Looper.getMainLooper()).post {
            listener?.onCallStateChanged(map)
        }
    }

    private fun notifyCallEnded(call: Call) {
        var recordedPath: String? = null
        if (callAudioRecorder.isRecording) {
            recordedPath = callAudioRecorder.stopRecording()
        }

        val durationSeconds = if (callStartTime > 0) (System.currentTimeMillis() - callStartTime) / 1000 else 0
        val map = mutableMapOf<String, Any?>(
            "state" to "DISCONNECTED",
            "phoneNumber" to extractPhoneNumber(call),
            "isIncoming" to (call.details?.callDirection == Call.Details.DIRECTION_INCOMING),
            "callDuration" to durationSeconds,
            "startTime" to callStartTime
        )

        if (!recordedPath.isNullOrEmpty()) {
            map["recordedFilePath"] = recordedPath
        }

        callStartTime = 0L
        Handler(Looper.getMainLooper()).post {
            listener?.onCallStateChanged(map)
        }
    }

    private fun extractPhoneNumber(call: Call): String {
        return try {
            val handle: Uri? = call.details?.handle
            val raw = handle?.schemeSpecificPart ?: ""
            raw.replace(Regex("[^0-9+#*]"), "")
        } catch (e: Exception) {
            ""
        }
    }

    private fun launchInCallUi() {
        try {
            val intent = Intent(this, MainActivity::class.java).apply {
                action = Intent.ACTION_MAIN
                addCategory(Intent.CATEGORY_LAUNCHER)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_REORDER_TO_FRONT
                putExtra("action", "show_in_call_screen")
            }
            startActivity(intent)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to launch main activity for call UI", e)
        }
    }

    fun setMute(muted: Boolean) {
        try {
            setMuted(muted)
        } catch (e: Exception) {
            Log.e(TAG, "Error setting mute", e)
        }
    }

    fun setSpeakerphone(speakerOn: Boolean) {
        try {
            val route = if (speakerOn) CallAudioState.ROUTE_SPEAKER else CallAudioState.ROUTE_EARPIECE
            setAudioRoute(route)
        } catch (e: Exception) {
            Log.e(TAG, "Error setting speakerphone", e)
        }
    }
}
