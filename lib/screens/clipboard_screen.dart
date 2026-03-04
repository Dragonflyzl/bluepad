import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/clipboard_item.dart';
import '../providers/bluetooth_provider.dart';
import '../providers/clipboard_provider.dart';
import '../theme/app_colors.dart';
import '../utils/l10n_utils.dart';

/// 剪贴板历史记录屏幕
/// 对应 Android: ClipboardScreen.kt
class ClipboardScreen extends ConsumerStatefulWidget {
  const ClipboardScreen({super.key});

  @override
  ConsumerState<ClipboardScreen> createState() => _ClipboardScreenState();
}

class _ClipboardScreenState extends ConsumerState<ClipboardScreen> {
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(clipboardActionsProvider).checkClipboard();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(clipboardHistoryProvider);
    final autoSync = ref.watch(clipboardAutoSyncProvider);
    const sensitiveDetection = false; 
    
    final filteredHistory = history.where((item) => 
      item.content.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceVariant = isDark ? DarkColors.bg3 : LightColors.bg3;
    final onSurfaceVariant = isDark ? DarkColors.text2 : LightColors.text2;
    final outlineColor = isDark ? DarkColors.border : LightColors.border;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Column(
        children: [
          // Search and Controls
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _searchQuery = v),
                      style: TextStyle(color: isDark ? DarkColors.text : LightColors.text, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: context.s('cb_search_placeholder'),
                        hintStyle: TextStyle(color: onSurfaceVariant, fontSize: 14),
                        prefixIcon: Icon(Icons.search, color: onSurfaceVariant),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    _showClearConfirmDialog(context, ref);
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: outlineColor),
                    ),
                    child: Icon(Icons.delete_sweep, color: (isDark ? DarkColors.red : LightColors.error).withOpacity(0.7)),
                  ),
                ),
              ],
            ),
          ),

          // Quick Settings Row
          Row(
            children: [
              _QuickSettingChip(
                label: context.s('cb_auto_sync'),
                isActive: autoSync,
                onTap: () => ref.read(clipboardAutoSyncProvider.notifier).toggle(),
              ),
              const SizedBox(width: 8),
              _QuickSettingChip(
                label: context.s('cb_sensitive_filter'),
                isActive: sensitiveDetection,
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 8),

          // History List
          Expanded(
            child: filteredHistory.isEmpty
                ? _buildEmptyState(onSurfaceVariant)
                : ListView.separated(
                    padding: const EdgeInsets.only(bottom: 16),
                    itemCount: filteredHistory.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      return _ClipboardItemCard(item: filteredHistory[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showClearConfirmDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Clear History"),
        content: const Text("Are you sure you want to clear all clipboard history?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              ref.read(clipboardHistoryProvider.notifier).clearAll();
              Navigator.pop(context);
            }, 
            child: const Text("Clear", style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(Color color) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.assignment, size: 64, color: color.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(context.s('cb_empty_history'), style: TextStyle(color: color)),
        ],
      ),
    );
  }
}

class _QuickSettingChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _QuickSettingChip({required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = isDark ? DarkColors.accent : LightColors.primary;
    final surfaceVariant = isDark ? DarkColors.bg3 : LightColors.bg3;
    final onSurfaceVariant = isDark ? DarkColors.text2 : LightColors.text2;

    final bgColor = isActive ? accentColor.withOpacity(0.1) : surfaceVariant;
    final borderColor = isActive ? accentColor : (isDark ? DarkColors.border : LightColors.border);
    final textColor = isActive ? accentColor : onSurfaceVariant;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 14,
              color: textColor,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(color: textColor, fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClipboardItemCard extends ConsumerWidget {
  final ClipboardItem item;
  const _ClipboardItemCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? DarkColors.bg2 : LightColors.bg2;
    final onSurface = isDark ? DarkColors.text : LightColors.text;
    final onSurfaceVariant = isDark ? DarkColors.text2 : LightColors.text2;
    final outlineColor = isDark ? DarkColors.border : LightColors.border;
    final accentColor = isDark ? DarkColors.accent : LightColors.primary;

    final timeStr = DateFormat('HH:mm:ss').format(DateTime.fromMillisecondsSinceEpoch(item.timestamp));

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: outlineColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(_getTypeIcon(item.contentType), size: 14, color: accentColor),
                  const SizedBox(width: 6),
                  Text(
                    _getTypeLabel(context, item.contentType),
                    style: TextStyle(color: onSurfaceVariant, fontSize: 10),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    timeStr,
                    style: TextStyle(color: onSurfaceVariant.withOpacity(0.7), fontSize: 10, fontFamily: 'monospace'),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  if (item.id != null) {
                    ref.read(clipboardHistoryProvider.notifier).deleteItem(item.id!);
                  }
                },
                child: Icon(Icons.close, size: 14, color: onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            item.content,
            style: TextStyle(
              color: onSurface,
              fontSize: 13,
              fontFamily: item.contentType == ClipboardContentType.code ? 'monospace' : null,
            ),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  "${item.charCount} characters",
                  style: TextStyle(color: onSurfaceVariant, fontSize: 10),
                ),
              ),
              _ActionBtn(
                icon: Icons.copy,
                label: context.s('cb_action_copy'),
                onTap: () {
                  ref.read(clipboardActionsProvider).copyToClipboard(item.content);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Copied to device")),
                  );
                },
              ),
              const SizedBox(width: 8),
              _ActionBtn(
                icon: Icons.input,
                label: context.s('cb_action_send'),
                color: accentColor,
                onTap: () {
                  if (item.content.runes.any((r) => r > 127)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(context.s('cb_toast_no_chinese'))),
                    );
                  }
                  ref.read(bluetoothActionsProvider).typeString(item.content);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getTypeIcon(ClipboardContentType type) {
    switch (type) {
      case ClipboardContentType.url: return Icons.link;
      case ClipboardContentType.code: return Icons.code;
      default: return Icons.text_fields;
    }
  }

  String _getTypeLabel(BuildContext context, ClipboardContentType type) {
    switch (type) {
      case ClipboardContentType.url: return context.s('cb_type_link');
      case ClipboardContentType.code: return context.s('cb_type_code');
      default: return context.s('cb_type_text');
    }
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _ActionBtn({required this.icon, required this.label, this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurfaceVariant = isDark ? DarkColors.text2 : LightColors.text2;
    final outlineColor = isDark ? DarkColors.border : LightColors.border;
    final surfaceVariant = isDark ? DarkColors.bg3 : LightColors.bg3;

    final finalColor = color ?? onSurfaceVariant;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: surfaceVariant,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: outlineColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: finalColor),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(color: finalColor, fontSize: 10, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
