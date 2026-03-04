package com.example.bluepad

import android.Manifest
import android.bluetooth.BluetoothDevice
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * MainActivity - Flutter 主活动
 * 委托 HID 功能给 HidDevice 单例，并管理 MethodChannel
 */
class MainActivity : FlutterActivity() {

    companion object {
        private const val TAG = "BluePad"
        private const val CHANNEL = "com.example.bluepad/hid"
        private const val PERMISSION_REQUEST_CODE = 1001
    }

    private lateinit var hidDevice: HidDevice
    private var vibrator: Vibrator? = null
    private lateinit var methodChannel: MethodChannel

    private val requiredPermissions = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
        arrayOf(
            Manifest.permission.BLUETOOTH_SCAN,
            Manifest.permission.BLUETOOTH_CONNECT,
            Manifest.permission.BLUETOOTH_ADVERTISE,
            Manifest.permission.ACCESS_FINE_LOCATION,
            Manifest.permission.POST_NOTIFICATIONS
        )
    } else {
        arrayOf(
            Manifest.permission.BLUETOOTH,
            Manifest.permission.BLUETOOTH_ADMIN,
            Manifest.permission.ACCESS_FINE_LOCATION
        )
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        hidDevice = HidDevice.getInstance(this)
        super.onCreate(savedInstanceState)

        vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val vibratorManager = getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager
            vibratorManager.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
        }

        checkPermissions()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        hidDevice.setMethodChannel(methodChannel)

        methodChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "initializeHid" -> {
                    HidService.start(this)
                    hidDevice.initialize()
                    result.success(true)
                }

                "getPairedDevices" -> {
                    val devices = hidDevice.getPairedDevices().map { device: BluetoothDevice ->
                        mapOf(
                            "name" to (device.name ?: "Unknown"),
                            "address" to device.address
                        )
                    }
                    result.success(devices)
                }

                "connect" -> {
                    val address = call.argument<String>("address")
                    if (address != null) {
                        result.success(hidDevice.connect(address))
                    } else {
                        result.error("INVALID_ADDRESS", "Device address is null", null)
                    }
                }

                "disconnect" -> {
                    result.success(hidDevice.disconnect())
                }

                "getConnectionState" -> {
                    result.success(hidDevice.connectedDevice != null)
                }

                "sendMouseReport" -> {
                    val buttons = call.argument<Int>("buttons") ?: 0
                    val dx = call.argument<Int>("dx") ?: 0
                    val dy = call.argument<Int>("dy") ?: 0
                    val wheel = call.argument<Int>("wheel") ?: 0
                    val hWheel = call.argument<Int>("hWheel") ?: 0
                    result.success(hidDevice.sendMouseReport(buttons, dx, dy, wheel, hWheel))
                }

                "sendKeyboardReport" -> {
                    val modifiers = call.argument<Int>("modifiers") ?: 0
                    @Suppress("UNCHECKED_CAST")
                    val keys = (call.argument<List<Int>>("keys") ?: emptyList()) as List<Int>
                    result.success(hidDevice.sendKeyboardReport(modifiers, keys))
                }

                "sendConsumerReport" -> {
                    val mask = call.argument<Int>("mask") ?: 0
                    result.success(hidDevice.sendConsumerReport(mask))
                }

                "vibrate" -> {
                    val duration = call.argument<Int>("duration") ?: 20
                    vibrate(duration)
                    result.success(null)
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun checkPermissions(): Boolean {
        val missingPermissions = requiredPermissions.filter {
            ContextCompat.checkSelfPermission(this, it) != PackageManager.PERMISSION_GRANTED
        }

        return if (missingPermissions.isNotEmpty()) {
            ActivityCompat.requestPermissions(this, missingPermissions.toTypedArray(), PERMISSION_REQUEST_CODE)
            false
        } else {
            true
        }
    }

    private fun vibrate(duration: Int) {
        vibrator?.let { v ->
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                v.vibrate(VibrationEffect.createOneShot(duration.toLong(), VibrationEffect.DEFAULT_AMPLITUDE))
            } else {
                @Suppress("DEPRECATION")
                v.vibrate(duration.toLong())
            }
        }
    }
}
