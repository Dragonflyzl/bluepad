import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/device_info.dart' as models;
import '../providers/bluetooth_provider.dart';
import '../theme/app_colors.dart';
import '../utils/l10n_utils.dart';
import 'device_picker_dialog.dart';

/// 根据设备名称推断设备类型、图标和系统符号
Map<String, String> getDeviceInfo(String deviceName) {
  final name = deviceName.toLowerCase();
  if (name.contains("mac") || name.contains("macbook") || name.contains("imac")) {
    return {"os": "macOS", "icon": "💻", "symbol": "⌘"};
  } else if (name.contains("ipad") || name.contains("iphone")) {
    return {"os": "iOS", "icon": "📱", "symbol": "⌘"};
  } else if (name.contains("win") || name.contains("desktop") || name.contains("pc")) {
    return {"os": "Windows", "icon": "🖥", "symbol": "⊞"};
  } else if (name.contains("android") || name.contains("galaxy") || name.contains("pixel")) {
    return {"os": "Android", "icon": "📱", "symbol": "⌘"};
  } else if (name.contains("linux") || name.contains("ubuntu")) {
    return {"os": "Linux", "icon": "🐧", "symbol": "⌘"};
  } else {
    return {"os": "Unknown", "icon": "💻", "symbol": "⌘"};
  }
}

class ConnectionBar extends ConsumerWidget {
  const ConnectionBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionState = ref.watch(connectionStateProvider);
    final connectedDevice = ref.watch(connectedDeviceProvider);
    final isConnected = connectionState == models.ConnectionState.connected;

    final deviceName = connectedDevice?.name ?? "";
    final deviceAddress = connectedDevice?.address ?? "";
    final info = getDeviceInfo(deviceName);
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceVariant = isDark ? DarkColors.bg2 : LightColors.bg2;
    final outlineColor = isDark ? DarkColors.border : LightColors.border;
    final accentColor = isDark ? DarkColors.accent : LightColors.primary;
    final onSurface = isDark ? DarkColors.text : LightColors.text;
    final onSurfaceVariant = isDark ? DarkColors.text2 : LightColors.text2;
    final greenColor = isDark ? DarkColors.green : LightColors.success;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      child: InkWell(
        onTap: () => _showDevicePicker(context, ref),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: surfaceVariant,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: outlineColor),
          ),
          child: Row(
            children: [
              // Connection Dot
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: isConnected ? greenColor : Colors.grey,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),

              // Device Icon Box
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: accentColor.withOpacity(0.2)),
                ),
                alignment: Alignment.center,
                child: Text(
                  deviceName.isNotEmpty ? info["icon"]! : "🔌",
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              const SizedBox(width: 10),

              // Device Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      deviceName.isNotEmpty ? deviceName : context.s('conn_no_device'),
                      style: TextStyle(
                        color: onSurface,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      deviceAddress.isNotEmpty 
                        ? "${info["os"]} · ${deviceAddress.length > 8 ? "${deviceAddress.substring(0, 8)}..." : deviceAddress}"
                        : context.s('conn_tap_to_connect'),
                      style: TextStyle(
                        color: onSurfaceVariant,
                        fontSize: 10,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),

              // Stats and Symbol
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isConnected) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: greenColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: greenColor.withOpacity(0.2)),
                      ),
                      child: const Text(
                        "12ms",
                        style: TextStyle(
                          color: Color(0xFF10B981),
                          fontSize: 10,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    info["symbol"]!,
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDevicePicker(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => const DevicePickerDialog(),
    );
  }
}
