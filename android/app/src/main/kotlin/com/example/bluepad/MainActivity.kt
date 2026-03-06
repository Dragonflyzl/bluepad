package com.example.bluepad

import android.Manifest
import android.bluetooth.BluetoothDevice
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.provider.Settings
import android.util.Log
import androidx.appcompat.app.AlertDialog
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
        private const val PREFS_NAME = "bluepad_prefs"
        private const val KEY_PERMISSIONS_GRANTED = "permissions_granted_version"
        private const val PERMISSIONS_VERSION = 2  // 当权限需求变更时递增此值
    }

    private lateinit var hidDevice: HidDevice
    private var vibrator: Vibrator? = null
    private lateinit var methodChannel: MethodChannel
    private lateinit var permissionPrefs: SharedPreferences

    private val requiredPermissions = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
        // Android 14+ (API 34+) 需要前台服务权限
        arrayOf(
            Manifest.permission.BLUETOOTH_SCAN,
            Manifest.permission.BLUETOOTH_CONNECT,
            Manifest.permission.BLUETOOTH_ADVERTISE,
            Manifest.permission.ACCESS_FINE_LOCATION,
            Manifest.permission.POST_NOTIFICATIONS,
            Manifest.permission.FOREGROUND_SERVICE_CONNECTED_DEVICE
        )
    } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
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

        // 初始化权限偏好设置
        permissionPrefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

        // 仅当权限未授予或版本变更时检查权限
        if (permissionPrefs.getInt(KEY_PERMISSIONS_GRANTED, 0) < PERMISSIONS_VERSION) {
            checkPermissionsWithRationale()
        }
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

    /**
     * 检查权限并处理 "不再询问" 状态
     * 仅在权限未授予或版本变更时请求权限
     */
    private fun checkPermissionsWithRationale(): Boolean {
        val missingPermissions = requiredPermissions.filter {
            ContextCompat.checkSelfPermission(this, it) != PackageManager.PERMISSION_GRANTED
        }

        if (missingPermissions.isEmpty()) {
            // 所有权限已授予，保存状态
            permissionPrefs.edit().putInt(KEY_PERMISSIONS_GRANTED, PERMISSIONS_VERSION).apply()
            return true
        }

        // 检查是否应该显示解释（用户未勾选 "不再询问"）
        val shouldShowRationale = missingPermissions.any {
            shouldShowRequestPermissionRationale(it)
        }

        if (shouldShowRationale) {
            // 用户之前拒绝过但未选 "不再询问"，显示解释对话框
            showPermissionRationaleDialog(missingPermissions.toTypedArray())
        } else {
            // 首次请求或用户已选 "不再询问"
            ActivityCompat.requestPermissions(this, missingPermissions.toTypedArray(), PERMISSION_REQUEST_CODE)
        }
        return false
    }

    /**
     * 显示权限解释对话框
     */
    private fun showPermissionRationaleDialog(permissions: Array<String>) {
        AlertDialog.Builder(this)
            .setTitle("蓝牙权限请求")
            .setMessage("BluePad 需要蓝牙权限来连接您的设备并作为远程输入设备使用。")
            .setPositiveButton("授权") { _, _ ->
                ActivityCompat.requestPermissions(this, permissions, PERMISSION_REQUEST_CODE)
            }
            .setNegativeButton("取消", null)
            .show()
    }

    /**
     * 处理权限请求结果
     */
    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == PERMISSION_REQUEST_CODE) {
            val allGranted = grantResults.all { it == PackageManager.PERMISSION_GRANTED }
            if (allGranted) {
                // 所有权限已授予，保存状态
                permissionPrefs.edit().putInt(KEY_PERMISSIONS_GRANTED, PERMISSIONS_VERSION).apply()
            } else {
                // 检查是否有权限被永久拒绝
                val permanentlyDenied = permissions.any {
                    !shouldShowRequestPermissionRationale(it) &&
                    ContextCompat.checkSelfPermission(this, it) != PackageManager.PERMISSION_GRANTED
                }
                if (permanentlyDenied) {
                    // 引导用户去设置页面
                    showSettingsDialog()
                }
            }
        }
    }

    /**
     * 显示引导用户去设置的对话框
     */
    private fun showSettingsDialog() {
        AlertDialog.Builder(this)
            .setTitle("权限被拒绝")
            .setMessage("某些权限被拒绝且选择了\"不再询问\"。请在设置中手动开启这些权限以使用 BluePad 的完整功能。")
            .setPositiveButton("去设置") { _, _ ->
                startActivity(Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                    data = Uri.fromParts("package", packageName, null)
                })
            }
            .setNegativeButton("取消", null)
            .show()
    }

    /**
     * 旧方法保留兼容性，现在调用新方法
     */
    private fun checkPermissions(): Boolean {
        return checkPermissionsWithRationale()
    }

    private fun vibrate(duration: Int) {
        if (vibrator == null) {
            Log.w(TAG, "Vibrator is null, device may not support vibration")
            return
        }
        if (!vibrator!!.hasVibrator()) {
            Log.w(TAG, "Device does not have a vibrator")
            return
        }
        Log.d(TAG, "Vibrating for ${duration}ms")
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            vibrator!!.vibrate(VibrationEffect.createOneShot(duration.toLong(), VibrationEffect.DEFAULT_AMPLITUDE))
        } else {
            @Suppress("DEPRECATION")
            vibrator!!.vibrate(duration.toLong())
        }
    }
}
