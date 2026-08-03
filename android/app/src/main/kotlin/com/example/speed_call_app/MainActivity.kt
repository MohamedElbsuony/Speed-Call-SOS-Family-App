package com.example.speed_call_app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.media.AudioManager
import android.media.ToneGenerator
import android.os.Build
import android.os.Bundle
import android.telephony.SmsManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val DIRECT_CALL_CHANNEL = "com.speedcall.app/direct_call"
    private val SIM_INFO_CHANNEL = "com.speedcall.app/sim_info"
    private val WIDGET_CHANNEL = "com.speedcall.app/widgets"
    private val SMS_CHANNEL = "com.speedcall.app/sms"

    private lateinit var directCallManager: DirectCallManager
    private lateinit var simManager: SimManager
    private var toneGenerator: ToneGenerator? = null

    private var pendingGpsResult: MethodChannel.Result? = null
    private val REQUEST_CODE_LOCATION_SETTINGS = 1099

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQUEST_CODE_LOCATION_SETTINGS) {
            val locationManager = getSystemService(Context.LOCATION_SERVICE) as? android.location.LocationManager
            val isGpsEnabled = locationManager?.isProviderEnabled(android.location.LocationManager.GPS_PROVIDER) == true ||
                               locationManager?.isProviderEnabled(android.location.LocationManager.NETWORK_PROVIDER) == true
            pendingGpsResult?.success(isGpsEnabled)
            pendingGpsResult = null
        }
    }

    private var pendingInitialAction: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        directCallManager = DirectCallManager(this)
        simManager = SimManager(this)
        checkIntentForSosAction(intent)
        try {
            toneGenerator = ToneGenerator(AudioManager.STREAM_SYSTEM, 85)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        checkIntentForSosAction(intent)
    }

    private fun checkIntentForSosAction(intent: Intent?) {
        val actionStr = intent?.getStringExtra("action")
        val intentAction = intent?.action
        if (actionStr == "trigger_family_sos" ||
            intentAction == "com.example.speed_call_app.ACTION_TRIGGER_SOS" ||
            intentAction == FamilySosWidgetProvider.ACTION_TRIGGER_SOS) {
            pendingInitialAction = "trigger_family_sos"
            intent?.removeExtra("action")
            if (intent?.action == "com.example.speed_call_app.ACTION_TRIGGER_SOS" ||
                intent?.action == FamilySosWidgetProvider.ACTION_TRIGGER_SOS) {
                intent?.action = Intent.ACTION_MAIN
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Direct Call Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, DIRECT_CALL_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "makeCall" -> {
                    val number = call.argument<String>("phoneNumber") ?: ""
                    val simMode = call.argument<Int>("simSelectionMode") ?: 0
                    val subId = call.argument<Int>("subscriptionId")
                    val success = directCallManager.placeDirectCall(number, simMode, subId)
                    result.success(success)
                }
                "playDtmfTone" -> {
                    val digit = call.argument<String>("digit") ?: ""
                    playDtmf(digit)
                    result.success(true)
                }
                "getGpsLocation" -> {
                    getFreshGpsLocation(result)
                }
                "checkAndEnableGps" -> {
                    val locationManager = getSystemService(Context.LOCATION_SERVICE) as? android.location.LocationManager
                    val isGpsEnabled = locationManager?.isProviderEnabled(android.location.LocationManager.GPS_PROVIDER) == true ||
                                       locationManager?.isProviderEnabled(android.location.LocationManager.NETWORK_PROVIDER) == true
                    if (!isGpsEnabled) {
                        pendingGpsResult = result
                        try {
                            val intent = Intent(android.provider.Settings.ACTION_LOCATION_SOURCE_SETTINGS)
                            startActivityForResult(intent, REQUEST_CODE_LOCATION_SETTINGS)
                        } catch (e: Exception) {
                            result.success(false)
                            pendingGpsResult = null
                        }
                    } else {
                        result.success(true)
                    }
                }
                "insertContact" -> {
                    val number = call.argument<String>("phoneNumber") ?: ""
                    val intent = Intent(Intent.ACTION_INSERT).apply {
                        type = android.provider.ContactsContract.RawContacts.CONTENT_TYPE
                        putExtra(android.provider.ContactsContract.Intents.Insert.PHONE, number)
                    }
                    try {
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        val fallbackIntent = Intent(Intent.ACTION_INSERT_OR_EDIT).apply {
                            type = android.provider.ContactsContract.Contacts.CONTENT_ITEM_TYPE
                            putExtra(android.provider.ContactsContract.Intents.Insert.PHONE, number)
                        }
                        try {
                            startActivity(fallbackIntent)
                            result.success(true)
                        } catch (ex: Exception) {
                            result.success(false)
                        }
                    }
                }
                "isDefaultDialer" -> {
                    val telecomManager = getSystemService(Context.TELECOM_SERVICE) as? android.telecom.TelecomManager
                    val isDefault = telecomManager?.defaultDialerPackage == packageName
                    result.success(isDefault)
                }
                "requestDefaultDialer" -> {
                    requestDefaultDialerRole()
                    result.success(true)
                }
                "openAppSettings" -> {
                    try {
                        val intent = Intent(android.provider.Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                            data = android.net.Uri.fromParts("package", packageName, null)
                        }
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                "answerCall" -> {
                    AppInCallService.answerCall()
                    result.success(true)
                }
                "rejectCall" -> {
                    AppInCallService.rejectCall()
                    result.success(true)
                }
                "hangUp" -> {
                    AppInCallService.hangUp()
                    result.success(true)
                }
                "setMuted" -> {
                    val muted = call.argument<Boolean>("muted") ?: false
                    AppInCallService.activeCall?.let {
                        // handled inside AppInCallService
                    }
                    result.success(true)
                }
                "setSpeaker" -> {
                    val speakerOn = call.argument<Boolean>("speakerOn") ?: false
                    // handled inside AppInCallService
                    result.success(true)
                }
                "getSystemCallLogs" -> {
                    val callLogManager = CallLogManager(this)
                    val logs = callLogManager.getSystemCallLogs(100)
                    result.success(logs)
                }
                "getInitialAction" -> {
                    val action = pendingInitialAction ?: intent?.getStringExtra("action") ?: ""
                    pendingInitialAction = null
                    intent?.removeExtra("action")
                    if (intent?.action == "com.example.speed_call_app.ACTION_TRIGGER_SOS" ||
                        intent?.action == FamilySosWidgetProvider.ACTION_TRIGGER_SOS) {
                        intent?.action = Intent.ACTION_MAIN
                    }
                    result.success(action)
                }
                else -> result.notImplemented()
            }
        }

        // Call State Stream Channel
        io.flutter.plugin.common.EventChannel(flutterEngine.dartExecutor.binaryMessenger, "com.speedcall.app/call_state")
            .setStreamHandler(object : io.flutter.plugin.common.EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: io.flutter.plugin.common.EventChannel.EventSink?) {
                    AppInCallService.listener = object : AppInCallService.CallStateListener {
                        override fun onCallStateChanged(stateMap: Map<String, Any?>) {
                            events?.success(stateMap)
                        }
                    }
                }
                override fun onCancel(arguments: Any?) {
                    AppInCallService.listener = null
                }
            })

        // SIM Info Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SIM_INFO_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getAvailableSims" -> {
                    val sims = simManager.getAvailableSims()
                    val resultList = sims.map {
                        mapOf(
                            "slotIndex" to it.slotIndex,
                            "subscriptionId" to it.subscriptionId,
                            "carrierName" to it.carrierName,
                            "displayName" to it.displayName,
                            "iccId" to (it.iccId ?: "")
                        )
                    }
                    result.success(resultList)
                }
                else -> result.notImplemented()
            }
        }

        // Native Direct SMS Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SMS_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "sendDirectSms" -> {
                    val number = call.argument<String>("phoneNumber") ?: ""
                    val message = call.argument<String>("message") ?: ""
                    val success = sendNativeSms(number, message)
                    result.success(success)
                }
                else -> result.notImplemented()
            }
        }

        // Widget Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WIDGET_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "saveSosConfig" -> {
                    val configJson = call.argument<String>("configJson") ?: ""
                    val prefs = getSharedPreferences("sos_prefs", Context.MODE_PRIVATE)
                    prefs.edit().putString("sos_config_json", configJson).apply()
                    result.success(true)
                }
                "saveWidgetConfig" -> {
                    val widgetId = call.argument<Int>("widgetId") ?: -1
                    val configJson = call.argument<String>("configJson") ?: ""
                    if (widgetId != -1 && configJson.isNotEmpty()) {
                        saveAndRefreshWidget(widgetId, configJson)
                        result.success(true)
                    } else {
                        result.success(false)
                    }
                }
                "pinWidget" -> {
                    val configJson = call.argument<String>("configJson") ?: ""
                    val success = requestPinWidget(configJson)
                    result.success(success)
                }
                "pinSosWidget" -> {
                    val success = requestPinSosWidget()
                    result.success(success)
                }
                "getWidgetIds" -> {
                    val appWidgetManager = AppWidgetManager.getInstance(this)
                    val component = ComponentName(this, DirectDialWidgetProvider::class.java)
                    val ids = appWidgetManager.getAppWidgetIds(component)
                    result.success(ids.toList())
                }
                "deleteWidget" -> {
                    val widgetId = call.argument<Int>("widgetId") ?: -1
                    if (widgetId != -1) {
                        val prefs = getSharedPreferences("widget_configs", Context.MODE_PRIVATE)
                        prefs.edit().remove("widget_$widgetId").apply()
                        result.success(true)
                    } else {
                        result.success(false)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun playDtmf(digit: String) {
        val tone = when (digit) {
            "1" -> ToneGenerator.TONE_DTMF_1
            "2" -> ToneGenerator.TONE_DTMF_2
            "3" -> ToneGenerator.TONE_DTMF_3
            "4" -> ToneGenerator.TONE_DTMF_4
            "5" -> ToneGenerator.TONE_DTMF_5
            "6" -> ToneGenerator.TONE_DTMF_6
            "7" -> ToneGenerator.TONE_DTMF_7
            "8" -> ToneGenerator.TONE_DTMF_8
            "9" -> ToneGenerator.TONE_DTMF_9
            "0" -> ToneGenerator.TONE_DTMF_0
            "*" -> ToneGenerator.TONE_DTMF_S
            "#" -> ToneGenerator.TONE_DTMF_P
            else -> ToneGenerator.TONE_PROP_BEEP
        }
        try {
            toneGenerator?.startTone(tone, 120)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun sendNativeSms(number: String, message: String): Boolean {
        return try {
            val cleanNumber = number.replace(Regex("[^0-9+]"), "")
            if (cleanNumber.isEmpty()) return false

            val smsManager: SmsManager = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                this.getSystemService(SmsManager::class.java)
            } else {
                SmsManager.getDefault()
            }

            val parts = smsManager.divideMessage(message)
            if (parts.size > 1) {
                smsManager.sendMultipartTextMessage(cleanNumber, null, parts, null, null)
            } else {
                smsManager.sendTextMessage(cleanNumber, null, message, null, null)
            }
            true
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }

    private fun saveAndRefreshWidget(widgetId: Int, configJson: String) {
        val prefs = getSharedPreferences("widget_configs", Context.MODE_PRIVATE)
        prefs.edit().putString("widget_$widgetId", configJson).apply()

        val appWidgetManager = AppWidgetManager.getInstance(this)
        WidgetRenderUtils.updateAppWidget(this, appWidgetManager, widgetId)
    }

    private fun requestPinWidget(configJson: String): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val appWidgetManager = AppWidgetManager.getInstance(this)
            val myProvider = ComponentName(this, DirectDialWidgetProvider::class.java)

            if (appWidgetManager.isRequestPinAppWidgetSupported) {
                val prefs = getSharedPreferences("widget_configs", Context.MODE_PRIVATE)
                prefs.edit().putString("pending_pin_config", configJson).apply()

                val successCallback = PendingIntent.getBroadcast(
                    this,
                    0,
                    Intent(this, DirectDialWidgetProvider::class.java),
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )

                appWidgetManager.requestPinAppWidget(myProvider, null, successCallback)
                return true
            }
        }
        return false
    }

    private fun requestPinSosWidget(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val appWidgetManager = AppWidgetManager.getInstance(this)
            val myProvider = ComponentName(this, FamilySosWidgetProvider::class.java)

            if (appWidgetManager.isRequestPinAppWidgetSupported) {
                val successCallback = PendingIntent.getBroadcast(
                    this,
                    0,
                    Intent(this, FamilySosWidgetProvider::class.java),
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )

                appWidgetManager.requestPinAppWidget(myProvider, null, successCallback)
                return true
            }
        }
        return false
    }

    private fun getFreshGpsLocation(result: io.flutter.plugin.common.MethodChannel.Result) {
        try {
            if (androidx.core.content.ContextCompat.checkSelfPermission(this, android.Manifest.permission.ACCESS_FINE_LOCATION) != android.content.pm.PackageManager.PERMISSION_GRANTED &&
                androidx.core.content.ContextCompat.checkSelfPermission(this, android.Manifest.permission.ACCESS_COARSE_LOCATION) != android.content.pm.PackageManager.PERMISSION_GRANTED) {
                result.success("")
                return
            }

            val locationManager = getSystemService(Context.LOCATION_SERVICE) as? android.location.LocationManager
            if (locationManager == null) {
                result.success("")
                return
            }

            var bestLoc: android.location.Location? = null
            val providers = locationManager.getProviders(true)
            for (provider in providers) {
                val l = locationManager.getLastKnownLocation(provider) ?: continue
                if (bestLoc == null || l.time > bestLoc.time) {
                    bestLoc = l
                }
            }

            if (bestLoc != null && (System.currentTimeMillis() - bestLoc.time) < 60000) {
                result.success("${bestLoc.latitude},${bestLoc.longitude}")
                return
            }

            var hasResponded = false
            val listener = object : android.location.LocationListener {
                override fun onLocationChanged(loc: android.location.Location) {
                    if (!hasResponded) {
                        hasResponded = true
                        try { locationManager.removeUpdates(this) } catch (_: Exception) {}
                        result.success("${loc.latitude},${loc.longitude}")
                    }
                }
                override fun onStatusChanged(provider: String?, status: Int, extras: android.os.Bundle?) {}
                override fun onProviderEnabled(provider: String) {}
                override fun onProviderDisabled(provider: String) {}
            }

            var requested = false
            if (locationManager.isProviderEnabled(android.location.LocationManager.GPS_PROVIDER)) {
                try {
                    locationManager.requestLocationUpdates(android.location.LocationManager.GPS_PROVIDER, 0L, 0f, listener, mainLooper)
                    requested = true
                } catch (_: Exception) {}
            }
            if (locationManager.isProviderEnabled(android.location.LocationManager.NETWORK_PROVIDER)) {
                try {
                    locationManager.requestLocationUpdates(android.location.LocationManager.NETWORK_PROVIDER, 0L, 0f, listener, mainLooper)
                    requested = true
                } catch (_: Exception) {}
            }

            if (!requested) {
                if (bestLoc != null) {
                    result.success("${bestLoc.latitude},${bestLoc.longitude}")
                } else {
                    result.success("")
                }
                return
            }

            android.os.Handler(mainLooper).postDelayed({
                if (!hasResponded) {
                    hasResponded = true
                    try { locationManager.removeUpdates(listener) } catch (_: Exception) {}
                    if (bestLoc != null) {
                        result.success("${bestLoc.latitude},${bestLoc.longitude}")
                    } else {
                        result.success("")
                    }
                }
            }, 3000)

        } catch (e: Exception) {
            result.success("")
        }
    }

    private fun requestDefaultDialerRole() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val roleManager = getSystemService(Context.ROLE_SERVICE) as? android.app.role.RoleManager
            if (roleManager != null && roleManager.isRoleAvailable(android.app.role.RoleManager.ROLE_DIALER)) {
                val intent = roleManager.createRequestRoleIntent(android.app.role.RoleManager.ROLE_DIALER)
                try {
                    startActivityForResult(intent, 1088)
                    return
                } catch (e: Exception) {
                    e.printStackTrace()
                }
            }
        }
        try {
            val intent = Intent(android.telecom.TelecomManager.ACTION_CHANGE_DEFAULT_DIALER).apply {
                putExtra(android.telecom.TelecomManager.EXTRA_CHANGE_DEFAULT_DIALER_PACKAGE_NAME, packageName)
            }
            startActivity(intent)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
}
