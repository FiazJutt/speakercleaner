package com.example.speakercleaner

import android.content.Context
import android.media.AudioDeviceInfo
import android.media.AudioManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.speakercleaner/routing"
    private var audioManager: AudioManager? = null
    private val handler = Handler(Looper.getMainLooper())

    private var currentDeviceType: Int = AudioDeviceInfo.TYPE_BUILTIN_SPEAKER

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getAvailableDevices" -> {
                        val devices = getAvailableAudioDevices()
                        result.success(devices)
                    }
                    "setAudioDevice" -> {
                        val deviceType = call.argument<Int>("deviceType") ?: -1
                        val success = setAudioOutputDevice(deviceType)
                        result.success(success)
                    }
                    "prepareForPlayback" -> {
                        val deviceType = call.argument<Int>("deviceType") ?: currentDeviceType
                        val success = setAudioOutputDevice(deviceType)
                        result.success(success)
                    }
                    "getCurrentDevice" -> {
                        result.success(currentDeviceType)
                    }
                    "resetAudioMode" -> {
                        resetToSpeaker()
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun getAvailableAudioDevices(): List<Map<String, Any>> {
        val deviceList = mutableListOf<Map<String, Any>>()

        audioManager?.let { am ->
            val devices = am.getDevices(AudioManager.GET_DEVICES_OUTPUTS)

            for (device in devices) {
                if (device.type == AudioDeviceInfo.TYPE_BUILTIN_SPEAKER ||
                    device.type == AudioDeviceInfo.TYPE_BUILTIN_EARPIECE ||
                    device.type == AudioDeviceInfo.TYPE_WIRED_HEADSET ||
                    device.type == AudioDeviceInfo.TYPE_WIRED_HEADPHONES ||
                    device.type == AudioDeviceInfo.TYPE_BLUETOOTH_A2DP ||
                    device.type == AudioDeviceInfo.TYPE_BLUETOOTH_SCO ||
                    device.type == AudioDeviceInfo.TYPE_USB_DEVICE ||
                    device.type == AudioDeviceInfo.TYPE_USB_HEADSET) {

                    deviceList.add(mapOf(
                        "id" to device.id,
                        "type" to device.type,
                        "name" to getDeviceTypeName(device.type),
                        "productName" to (device.productName?.toString() ?: "Unknown"),
                        "isSource" to device.isSource,
                        "isSink" to device.isSink
                    ))
                }
            }
        }

        return deviceList
    }

    private fun getDeviceTypeName(type: Int): String {
        return when (type) {
            AudioDeviceInfo.TYPE_BUILTIN_SPEAKER -> "Bottom Speaker"
            AudioDeviceInfo.TYPE_BUILTIN_EARPIECE -> "Top Earpiece"
            AudioDeviceInfo.TYPE_WIRED_HEADSET -> "Wired Headset"
            AudioDeviceInfo.TYPE_WIRED_HEADPHONES -> "Wired Headphones"
            AudioDeviceInfo.TYPE_BLUETOOTH_A2DP -> "Bluetooth Audio"
            AudioDeviceInfo.TYPE_BLUETOOTH_SCO -> "Bluetooth SCO"
            AudioDeviceInfo.TYPE_USB_DEVICE -> "USB Audio"
            AudioDeviceInfo.TYPE_USB_HEADSET -> "USB Headset"
            else -> "Unknown Device ($type)"
        }
    }

    private fun setAudioOutputDevice(deviceType: Int): Boolean {
        return try {
            audioManager?.let { am ->
                android.util.Log.d("AudioRouting", "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                android.util.Log.d("AudioRouting", "Switching to: ${getDeviceTypeName(deviceType)}")

                // CRITICAL: Clear everything first
                clearAllRouting(am)

                // Small delay to let system reset
                Thread.sleep(100)

                when (deviceType) {
                    AudioDeviceInfo.TYPE_BUILTIN_SPEAKER -> {
                        routeToSpeaker(am)
                    }
                    AudioDeviceInfo.TYPE_BUILTIN_EARPIECE -> {
                        routeToEarpiece(am)
                    }
                    AudioDeviceInfo.TYPE_WIRED_HEADSET,
                    AudioDeviceInfo.TYPE_WIRED_HEADPHONES -> {
                        routeToWired(am)
                    }
                    AudioDeviceInfo.TYPE_BLUETOOTH_A2DP,
                    AudioDeviceInfo.TYPE_BLUETOOTH_SCO -> {
                        routeToBluetooth(am)
                    }
                    else -> {
                        android.util.Log.e("AudioRouting", "Unknown device type: $deviceType")
                        return@let false
                    }
                }

                currentDeviceType = deviceType

                // Verify after a short delay
                handler.postDelayed({
                    logCurrentState(am)
                }, 300)

                true
            } ?: false
        } catch (e: Exception) {
            android.util.Log.e("AudioRouting", " Error: ${e.message}")
            e.printStackTrace()
            false
        }
    }

    /**
     * CRITICAL: Clear all routing before switching
     */
    private fun clearAllRouting(am: AudioManager) {
        android.util.Log.d("AudioRouting", "Clearing all routing...")

        // Stop Bluetooth SCO if active
        try {
            am.isBluetoothScoOn = false
            am.stopBluetoothSco()
        } catch (e: Exception) {
            // Ignore
        }

        // Clear communication device (Android 12+)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            try {
                am.clearCommunicationDevice()
                android.util.Log.d("AudioRouting", "   ✓ Cleared communication device")
            } catch (e: Exception) {
                android.util.Log.w("AudioRouting", "   ! clearCommunicationDevice: ${e.message}")
            }
        }

        // Reset to normal mode
        am.mode = AudioManager.MODE_NORMAL
        am.isSpeakerphoneOn = false

        android.util.Log.d("AudioRouting", "   ✓ Reset to MODE_NORMAL, speaker OFF")
    }

    /**
     * Route to SPEAKER (Bottom)
     */
    private fun routeToSpeaker(am: AudioManager): Boolean {
        android.util.Log.d("AudioRouting", "Configuring SPEAKER output...")

        // For speaker: Use NORMAL mode with speakerphone ON
        am.mode = AudioManager.MODE_NORMAL
        am.isSpeakerphoneOn = true

        // Android 12+: Also set communication device to speaker for certainty
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            try {
                // First clear any previous setting
                am.clearCommunicationDevice()

                // Find and set speaker
                val devices = am.availableCommunicationDevices
                val speaker = devices.find { it.type == AudioDeviceInfo.TYPE_BUILTIN_SPEAKER }

                if (speaker != null) {
                    val success = am.setCommunicationDevice(speaker)
                    android.util.Log.d("AudioRouting", "   setCommunicationDevice(SPEAKER): $success")
                } else {
                    android.util.Log.d("AudioRouting", "   Speaker not in comm devices, using speakerphone flag")
                }
            } catch (e: Exception) {
                android.util.Log.w("AudioRouting", "   setCommunicationDevice error: ${e.message}")
            }
        }

        android.util.Log.d("AudioRouting", "SPEAKER configured | mode=NORMAL, speakerOn=true")
        return true
    }

    /**
     * Route to EARPIECE (Top)
     */
    private fun routeToEarpiece(am: AudioManager): Boolean {
        android.util.Log.d("AudioRouting", "Configuring EARPIECE output...")

        // For earpiece: MUST use IN_COMMUNICATION mode
        am.mode = AudioManager.MODE_IN_COMMUNICATION
        am.isSpeakerphoneOn = false

        // Android 12+: Must explicitly set communication device
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            try {
                val devices = am.availableCommunicationDevices
                android.util.Log.d("AudioRouting", "   Available comm devices: ${devices.map { getDeviceTypeName(it.type) }}")

                val earpiece = devices.find { it.type == AudioDeviceInfo.TYPE_BUILTIN_EARPIECE }

                if (earpiece != null) {
                    val success = am.setCommunicationDevice(earpiece)
                    android.util.Log.d("AudioRouting", "   setCommunicationDevice(EARPIECE): $success")
                } else {
                    android.util.Log.e("AudioRouting", "   Earpiece not found in available devices!")
                }
            } catch (e: Exception) {
                android.util.Log.e("AudioRouting", "   setCommunicationDevice error: ${e.message}")
            }
        }

        android.util.Log.d("AudioRouting", "EARPIECE configured | mode=IN_COMMUNICATION, speakerOn=false")
        return true
    }

    private fun routeToWired(am: AudioManager): Boolean {
        android.util.Log.d("AudioRouting", "Configuring WIRED output...")
        am.mode = AudioManager.MODE_NORMAL
        am.isSpeakerphoneOn = false
        return true
    }

    private fun routeToBluetooth(am: AudioManager): Boolean {
        android.util.Log.d("AudioRouting", "Configuring BLUETOOTH output...")
        am.mode = AudioManager.MODE_IN_COMMUNICATION
        am.isSpeakerphoneOn = false
        am.isBluetoothScoOn = true
        am.startBluetoothSco()
        return true
    }

    private fun resetToSpeaker() {
        audioManager?.let { am ->
            clearAllRouting(am)
            am.mode = AudioManager.MODE_NORMAL
            am.isSpeakerphoneOn = true
            currentDeviceType = AudioDeviceInfo.TYPE_BUILTIN_SPEAKER
            android.util.Log.d("AudioRouting", "Reset to speaker")
        }
    }

    private fun logCurrentState(am: AudioManager) {
        val modeName = when (am.mode) {
            AudioManager.MODE_NORMAL -> "NORMAL"
            AudioManager.MODE_IN_COMMUNICATION -> "IN_COMMUNICATION"
            AudioManager.MODE_IN_CALL -> "IN_CALL"
            AudioManager.MODE_RINGTONE -> "RINGTONE"
            else -> "UNKNOWN(${am.mode})"
        }

        android.util.Log.d("AudioRouting", """
            |  CURRENT STATE:
            |   Mode: $modeName
            |   SpeakerphoneOn: ${am.isSpeakerphoneOn}
            |   BluetoothScoOn: ${am.isBluetoothScoOn}
            |   Target: ${getDeviceTypeName(currentDeviceType)}
        """.trimMargin())

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val commDevice = am.communicationDevice
            android.util.Log.d("AudioRouting", "|   CommDevice: ${commDevice?.let { getDeviceTypeName(it.type) } ?: "None"}")
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        resetToSpeaker()
    }
}