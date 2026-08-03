package com.example.speed_call_app

import android.content.Context
import android.content.pm.PackageManager
import android.media.MediaRecorder
import android.os.Build
import android.util.Log
import androidx.core.content.ContextCompat
import java.io.File

class CallAudioRecorder(private val context: Context) {

    companion object {
        private const val TAG = "CallAudioRecorder"
    }

    private var recorder: MediaRecorder? = null
    private var currentOutputFile: File? = null
    var isRecording = false
        private set

    fun startRecording(phoneNumber: String): Boolean {
        if (ContextCompat.checkSelfPermission(context, android.Manifest.permission.RECORD_AUDIO)
            != PackageManager.PERMISSION_GRANTED) {
            Log.w(TAG, "RECORD_AUDIO permission not granted")
            return false
        }

        if (isRecording) {
            stopRecording()
        }

        return try {
            val fileName = "temp_call_rec_${System.currentTimeMillis()}.m4a"
            val outputDir = File(context.cacheDir, "call_recordings").apply { mkdirs() }
            currentOutputFile = File(outputDir, fileName)

            recorder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                MediaRecorder(context)
            } else {
                @Suppress("DEPRECATION")
                MediaRecorder()
            }.apply {
                try {
                    setAudioSource(MediaRecorder.AudioSource.VOICE_COMMUNICATION)
                } catch (e: Exception) {
                    setAudioSource(MediaRecorder.AudioSource.MIC)
                }
                setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
                setAudioEncoder(MediaRecorder.AudioEncoder.AAC)
                setAudioEncodingBitRate(128000)
                setAudioSamplingRate(44100)
                setOutputFile(currentOutputFile?.absolutePath)
                prepare()
                start()
            }

            isRecording = true
            Log.d(TAG, "Call recording started: ${currentOutputFile?.absolutePath}")
            true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start call recording", e)
            cleanup()
            false
        }
    }

    fun stopRecording(): String? {
        if (!isRecording) return null

        var recordedPath: String? = null
        try {
            recorder?.stop()
            recordedPath = currentOutputFile?.absolutePath
            Log.d(TAG, "Call recording stopped successfully: $recordedPath")
        } catch (e: Exception) {
            Log.e(TAG, "Error stopping recorder", e)
            currentOutputFile?.delete()
        } finally {
            cleanup()
        }

        return recordedPath
    }

    private fun cleanup() {
        try {
            recorder?.reset()
            recorder?.release()
        } catch (_: Exception) {}
        recorder = null
        isRecording = false
    }
}
