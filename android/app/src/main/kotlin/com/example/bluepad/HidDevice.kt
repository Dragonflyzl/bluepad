package com.example.bluepad

import android.annotation.SuppressLint
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothHidDevice
import android.bluetooth.BluetoothHidDeviceAppQosSettings
import android.bluetooth.BluetoothHidDeviceAppSdpSettings
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothProfile
import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

/**
 * HidDevice - 单例类
 * 负责管理蓝牙 HID 设备的连接、注册和报告发送
 */
@SuppressLint("MissingPermission")
class HidDevice private constructor(private val context: Context) {

    companion object {
        private const val TAG = "HidDevice"
        
        @Volatile
        private var INSTANCE: HidDevice? = null

        fun getInstance(context: Context): HidDevice {
            return INSTANCE ?: synchronized(this) {
                INSTANCE ?: HidDevice(context.applicationContext).also { INSTANCE = it }
            }
        }

        // 报告 ID
        const val ID_MOUSE = 1
        const val ID_KEYBOARD = 2
        const val ID_CONSUMER = 3
    }

    private val bluetoothManager = context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
    private val bluetoothAdapter: BluetoothAdapter? = bluetoothManager.adapter
    
    private var hidProfile: BluetoothHidDevice? = null
    var connectedDevice: BluetoothDevice? = null
        private set
    
    var isRegistered = false
        private set

    private var methodChannel: MethodChannel? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    fun setMethodChannel(channel: MethodChannel) {
        this.methodChannel = channel
    }

    private val callback = object : BluetoothHidDevice.Callback() {
        override fun onAppStatusChanged(pluggedDevice: BluetoothDevice?, registered: Boolean) {
            Log.d(TAG, "onAppStatusChanged: registered=$registered")
            isRegistered = registered
            if (registered && pluggedDevice != null) {
                connectedDevice = pluggedDevice
                notifyConnected(pluggedDevice.address)
            }
        }

        override fun onConnectionStateChanged(device: BluetoothDevice?, state: Int) {
            Log.d(TAG, "onConnectionStateChanged: device=${device?.address}, state=$state")
            when (state) {
                BluetoothProfile.STATE_CONNECTED -> {
                    connectedDevice = device
                    notifyConnected(device?.address)
                }
                BluetoothProfile.STATE_DISCONNECTED -> {
                    if (connectedDevice?.address == device?.address) {
                        connectedDevice = null
                    }
                    notifyDisconnected(device?.address)
                }
            }
        }
    }

    private fun notifyConnected(address: String?) {
        mainHandler.post {
            methodChannel?.invokeMethod("onConnected", address)
        }
    }

    private fun notifyDisconnected(address: String?) {
        mainHandler.post {
            methodChannel?.invokeMethod("onDisconnected", address)
        }
    }

    private val serviceListener = object : BluetoothProfile.ServiceListener {
        override fun onServiceConnected(profile: Int, proxy: BluetoothProfile) {
            if (profile == BluetoothProfile.HID_DEVICE) {
                Log.d(TAG, "HID profile connected")
                hidProfile = proxy as BluetoothHidDevice
                registerApp()
            }
        }

        override fun onServiceDisconnected(profile: Int) {
            if (profile == BluetoothProfile.HID_DEVICE) {
                Log.d(TAG, "HID profile disconnected")
                hidProfile = null
                isRegistered = false
                connectedDevice = null
            }
        }
    }

    fun initialize() {
        if (bluetoothAdapter == null || hidProfile != null) {
            if (hidProfile != null && !isRegistered) registerApp()
            return
        }
        bluetoothAdapter.getProfileProxy(context, serviceListener, BluetoothProfile.HID_DEVICE)
    }

    private fun registerApp() {
        val hid = hidProfile ?: return
        if (isRegistered) return

        Log.d(TAG, "Registering HID App")
        
        val hidDescriptor = byteArrayOf(
            // --- 鼠标 (ID 1) ---
            0x05.toByte(), 0x01.toByte(), 0x09.toByte(), 0x02.toByte(), 0xA1.toByte(), 0x01.toByte(),
            0x85.toByte(), ID_MOUSE.toByte(), 0x09.toByte(), 0x01.toByte(), 0xA1.toByte(), 0x00.toByte(),
            0x05.toByte(), 0x09.toByte(), 0x19.toByte(), 0x01.toByte(), 0x29.toByte(), 0x03.toByte(),
            0x15.toByte(), 0x00.toByte(), 0x25.toByte(), 0x01.toByte(), 0x95.toByte(), 0x03.toByte(),
            0x75.toByte(), 0x01.toByte(), 0x81.toByte(), 0x02.toByte(), 0x95.toByte(), 0x01.toByte(),
            0x75.toByte(), 0x05.toByte(), 0x81.toByte(), 0x03.toByte(), 0x05.toByte(), 0x01.toByte(),
            0x09.toByte(), 0x30.toByte(), 0x09.toByte(), 0x31.toByte(), 0x15.toByte(), 0x81.toByte(),
            0x25.toByte(), 0x7F.toByte(), 0x75.toByte(), 0x08.toByte(), 0x95.toByte(), 0x02.toByte(),
            0x81.toByte(), 0x06.toByte(),
            // 垂直滚轮
            0x09.toByte(), 0x38.toByte(), 0x15.toByte(), 0x81.toByte(), 0x25.toByte(), 0x7F.toByte(),
            0x75.toByte(), 0x08.toByte(), 0x95.toByte(), 0x01.toByte(), 0x81.toByte(), 0x06.toByte(),
            // 水平滚轮 (AC Pan)
            0x05.toByte(), 0x0C.toByte(), 0x0A.toByte(), 0x38.toByte(), 0x02.toByte(),
            0x15.toByte(), 0x81.toByte(), 0x25.toByte(), 0x7F.toByte(), 0x75.toByte(), 0x08.toByte(),
            0x95.toByte(), 0x01.toByte(), 0x81.toByte(), 0x06.toByte(),
            0xC0.toByte(), 0xC0.toByte(),
            
            // --- 键盘 (ID 2) ---
            0x05.toByte(), 0x01.toByte(), 0x09.toByte(), 0x06.toByte(), 0xA1.toByte(), 0x01.toByte(),
            0x85.toByte(), ID_KEYBOARD.toByte(), 0x05.toByte(), 0x07.toByte(), 0x19.toByte(), 0xE0.toByte(),
            0x29.toByte(), 0xE7.toByte(), 0x15.toByte(), 0x00.toByte(), 0x25.toByte(), 0x01.toByte(),
            0x75.toByte(), 0x01.toByte(), 0x95.toByte(), 0x08.toByte(), 0x81.toByte(), 0x02.toByte(),
            0x95.toByte(), 0x01.toByte(), 0x75.toByte(), 0x08.toByte(), 0x81.toByte(), 0x03.toByte(),
            0x95.toByte(), 0x06.toByte(), 0x75.toByte(), 0x08.toByte(), 0x15.toByte(), 0x00.toByte(),
            0x25.toByte(), 0x65.toByte(), 0x05.toByte(), 0x07.toByte(), 0x19.toByte(), 0x00.toByte(),
            0x29.toByte(), 0x65.toByte(), 0x81.toByte(), 0x00.toByte(), 0xC0.toByte(),
            
            // --- 消费控制 (ID 3) ---
            0x05.toByte(), 0x0C.toByte(), 0x09.toByte(), 0x01.toByte(), 0xA1.toByte(), 0x01.toByte(),
            0x85.toByte(), ID_CONSUMER.toByte(), 0x15.toByte(), 0x00.toByte(), 0x25.toByte(), 0x01.toByte(),
            0x75.toByte(), 0x01.toByte(), 0x95.toByte(), 0x07.toByte(), 0x09.toByte(), 0xB5.toByte(),
            0x09.toByte(), 0xB6.toByte(), 0x09.toByte(), 0xB7.toByte(), 0x09.toByte(), 0xCD.toByte(),
            0x09.toByte(), 0xE2.toByte(), 0x09.toByte(), 0xE9.toByte(), 0x09.toByte(), 0xEA.toByte(),
            0x81.toByte(), 0x02.toByte(), 0x95.toByte(), 0x01.toByte(), 0x81.toByte(), 0x03.toByte(),
            0xC0.toByte()
        )

        val sdpSettings = BluetoothHidDeviceAppSdpSettings(
            "BluePad", "Remote HID Input", "Android",
            BluetoothHidDevice.SUBCLASS1_COMBO, hidDescriptor
        )

        val qosSettings = BluetoothHidDeviceAppQosSettings(
            BluetoothHidDeviceAppQosSettings.SERVICE_BEST_EFFORT,
            800, 9, 0, 11250, 0
        )

        try {
            hid.registerApp(sdpSettings, null, qosSettings, Executors.newCachedThreadPool(), callback)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to register HID app", e)
        }
    }

    fun getPairedDevices(): List<BluetoothDevice> {
        return try {
            bluetoothAdapter?.bondedDevices?.toList() ?: emptyList()
        } catch (e: Exception) {
            emptyList()
        }
    }

    fun connect(address: String): Boolean {
        val hid = hidProfile
        if (hid == null) {
            Log.e(TAG, "Cannot connect: hidProfile is null. Re-initializing...")
            initialize()
            return false
        }
        
        if (!isRegistered) {
            Log.e(TAG, "Cannot connect: App is not registered yet. Re-registering...")
            registerApp()
            return false
        }

        val device = bluetoothAdapter?.getRemoteDevice(address)
        if (device == null) {
            Log.e(TAG, "Cannot connect: Device not found for address $address")
            return false
        }
        
        Log.d(TAG, "Connecting to ${device.name} ($address)")
        
        if (connectedDevice != null && connectedDevice?.address != address) {
            Log.d(TAG, "Disconnecting previous device ${connectedDevice?.address}")
            hid.disconnect(connectedDevice!!)
        }
        
        val result = hid.connect(device)
        Log.d(TAG, "hid.connect(device) returned $result")
        return result
    }

    fun disconnect(): Boolean {
        val hid = hidProfile ?: return false
        val device = connectedDevice ?: return false
        return hid.disconnect(device)
    }

    fun sendMouseReport(buttons: Int, dx: Int, dy: Int, wheel: Int, hWheel: Int = 0): Boolean {
        val hid = hidProfile ?: return false
        val device = connectedDevice ?: return false
        
        val report = ByteArray(5)
        report[0] = (buttons and 0x07).toByte()
        report[1] = dx.toByte()
        report[2] = dy.toByte()
        report[3] = wheel.toByte()
        report[4] = hWheel.toByte()
        
        return hid.sendReport(device, ID_MOUSE, report)
    }

    fun sendKeyboardReport(modifiers: Int, keys: List<Int>): Boolean {
        val hid = hidProfile ?: return false
        val device = connectedDevice ?: return false
        val report = ByteArray(8)
        report[0] = (modifiers and 0xFF).toByte()
        report[1] = 0
        for (i in 0 until minOf(keys.size, 6)) {
            report[2 + i] = (keys[i] and 0xFF).toByte()
        }
        return hid.sendReport(device, ID_KEYBOARD, report)
    }

    fun sendConsumerReport(mask: Int): Boolean {
        val hid = hidProfile ?: return false
        val device = connectedDevice ?: return false
        val report = ByteArray(1)
        report[0] = (mask and 0xFF).toByte()
        return hid.sendReport(device, ID_CONSUMER, report)
    }

    fun close() {
        try {
            if (isRegistered) hidProfile?.unregisterApp()
            bluetoothAdapter?.closeProfileProxy(BluetoothProfile.HID_DEVICE, hidProfile)
        } catch (e: Exception) {
            Log.e(TAG, "Error closing HID", e)
        }
        hidProfile = null
        isRegistered = false
        connectedDevice = null
    }
}
