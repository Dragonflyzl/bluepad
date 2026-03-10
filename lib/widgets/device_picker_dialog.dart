import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/device_info.dart' as models;
import '../providers/bluetooth_provider.dart';
import '../theme/app_colors.dart';
import '../utils/l10n_utils.dart';

/// 设备选择对话框
/// 对应 Android: DevicePickerModal.kt
class DevicePickerDialog extends ConsumerStatefulWidget {
  const DevicePickerDialog({super.key});

  @override
  ConsumerState<DevicePickerDialog> createState() => _DevicePickerDialogState();
}

class _DevicePickerDialogState extends ConsumerState<DevicePickerDialog> {
  bool _isScanning = false;
  String? _connectingAddress;  // 正在连接的设备地址
  static bool _isDialogOpen = false;  // 防止重复打开

  @override
  void initState() {
    super.initState();
    if (!_isDialogOpen) {
      _isDialogOpen = true;
      _startScan();
    }
  }

  @override
  void dispose() {
    _isDialogOpen = false;
    ref.read(bluetoothActionsProvider).stopScan();
    super.dispose();
  }

  Future<void> _startScan() async {
    if (_isScanning) return;
    setState(() => _isScanning = true);
    
    final actions = ref.read(bluetoothActionsProvider);
    final hasPermission = await actions.checkBluetooth();
    if (!hasPermission) {
      if (mounted) setState(() => _isScanning = false);
      return;
    }
    
    await actions.startScan(timeout: 10);
    // 扫描会自动在 provider 中更新状态，这里只是为了 UI 显示
    await Future.delayed(const Duration(seconds: 10));
    if (mounted) setState(() => _isScanning = false);
  }

  Future<void> _connectToDevice(models.DeviceInfo device) async {
    // 设置连接中状态
    setState(() => _connectingAddress = device.address);

    final actions = ref.read(bluetoothActionsProvider);
    await actions.stopScan();

    final success = await actions.connect(device);

    if (mounted) {
      setState(() => _connectingAddress = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Connected to ${device.name}' : 'Connection Failed'),
          backgroundColor: success ? DarkColors.green : DarkColors.red,
          duration: const Duration(seconds: 2),
        ),
      );
      if (success) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pairedDevices = ref.watch(pairedDevicesProvider);
    final discoveredDevices = ref.watch(discoveredDevicesProvider);
    final connectedDevice = ref.watch(connectedDeviceProvider);
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? DarkColors.bg2 : LightColors.bg;
    final onSurface = isDark ? DarkColors.text : LightColors.text;
    final onSurfaceVariant = isDark ? DarkColors.text2 : LightColors.text2;
    final outlineColor = isDark ? DarkColors.border : LightColors.border;
    final accentColor = isDark ? DarkColors.accent : LightColors.primary;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40),
      child: Container(
        width: 320,
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: outlineColor),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        context.s('device_select_title'),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: onSurface,
                        ),
                      ),
                      if (_isScanning) ...[
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                          ),
                        ),
                      ],
                    ],
                  ),
                  GestureDetector(
                    onTap: _isScanning ? null : _startScan,
                    child: Text(
                      _isScanning ? context.s('device_scanning') : context.s('device_refresh'),
                      style: TextStyle(
                        fontSize: 12,
                        color: _isScanning ? onSurfaceVariant : accentColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            Divider(height: 1, color: outlineColor),
            
            // List
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 400),
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  // Paired Section
                  _buildSectionHeader(context.s('device_paired_section'), accentColor),
                  if (pairedDevices.isEmpty)
                    _buildEmptyText('No paired devices', onSurfaceVariant)
                  else
                    ...pairedDevices.map((device) => _DeviceItem(
                      device: device,
                      isConnected: device.address == connectedDevice?.address,
                      isConnecting: device.address == _connectingAddress,
                      onTap: _connectingAddress == null ? () => _connectToDevice(device) : null,
                    )),

                  const SizedBox(height: 8),

                  // Available Section
                  _buildSectionHeader(context.s('device_available_section'), accentColor),
                  if (discoveredDevices.isEmpty)
                    _buildEmptyText(_isScanning ? 'Searching...' : 'No devices found', onSurfaceVariant)
                  else
                    ...discoveredDevices.map((device) => _DeviceItem(
                      device: device,
                      isConnected: false,
                      isConnecting: device.address == _connectingAddress,
                      onTap: _connectingAddress == null ? () => _connectToDevice(device) : null,
                    )),
                ],
              ),
            ),
            
            Divider(height: 1, color: outlineColor),
            
            // Footer
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: GestureDetector(
                onTap: () {
                  ref.read(bluetoothActionsProvider).stopScan();
                  Navigator.pop(context);
                },
                child: Text(
                  context.s('device_close'),
                  style: TextStyle(
                    color: onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildEmptyText(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: color,
        ),
      ),
    );
  }
}

class _DeviceItem extends StatelessWidget {
  final models.DeviceInfo device;
  final bool isConnected;
  final bool isConnecting;
  final VoidCallback? onTap;

  const _DeviceItem({
    required this.device,
    required this.isConnected,
    this.isConnecting = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final info = _getDeviceTypeInfo(device.name);

    final accentColor = isDark ? DarkColors.accent : LightColors.primary;
    final greenColor = isDark ? DarkColors.green : LightColors.success;
    final orangeColor = isDark ? DarkColors.orange : const Color(0xFFF97316);
    final onSurface = isDark ? DarkColors.text : LightColors.text;
    final onSurfaceVariant = isDark ? DarkColors.text2 : LightColors.text2;
    final surfaceVariant = isDark ? DarkColors.bg3 : LightColors.bg2;

    final bgColor = isConnected ? greenColor.withOpacity(0.08)
        : isConnecting ? orangeColor.withOpacity(0.08)
        : Colors.transparent;
    final borderColor = isConnected ? greenColor
        : isConnecting ? orangeColor
        : Colors.transparent;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: surfaceVariant,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              // Device Icon
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: (isConnected ? greenColor : accentColor).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: (isConnected ? greenColor : accentColor).withOpacity(0.25)),
                ),
                alignment: Alignment.center,
                child: Text(
                  info['icon']!,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
              const SizedBox(width: 12),
              // Name and Address
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device.name.isNotEmpty ? device.name : "Unknown Device",
                      style: TextStyle(
                        color: onSurface,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      "${info['os']} · ${device.address}",
                      style: TextStyle(
                        color: onSurfaceVariant,
                        fontSize: 10,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              // Status Badge
              if (isConnecting)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        valueColor: AlwaysStoppedAnimation<Color>(orangeColor),
                      ),
                    ),
                    const SizedBox(width: 6),
                    _StatusBadge(label: 'Connecting...', color: orangeColor),
                  ],
                )
              else if (isConnected)
                _StatusBadge(label: context.s('conn_connected'), color: greenColor)
              else
                _StatusBadge(label: context.s('conn_paired'), color: accentColor),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, String> _getDeviceTypeInfo(String deviceName) {
    final name = deviceName.toLowerCase();
    if (name.contains("mac") || name.contains("macbook") || name.contains("imac")) {
      return {"os": "macOS", "icon": "💻"};
    } else if (name.contains("ipad") || name.contains("iphone")) {
      return {"os": "iOS", "icon": "📱"};
    } else if (name.contains("win") || name.contains("desktop") || name.contains("pc")) {
      return {"os": "Windows", "icon": "🖥"};
    } else if (name.contains("android") || name.contains("galaxy") || name.contains("pixel")) {
      return {"os": "Android", "icon": "📱"};
    } else if (name.contains("linux") || name.contains("ubuntu")) {
      return {"os": "Linux", "icon": "🐧"};
    } else {
      return {"os": "BT Device", "icon": "🔌"};
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}
