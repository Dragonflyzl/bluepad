/// 剪贴板历史记录项数据模型
/// 对应 Android 中的 ClipboardItem Entity
/// 使用简单的不可变类实现

/// 剪贴板内容类型枚举
/// 对应 Kotlin: enum class ClipboardContentType
enum ClipboardContentType {
  text,   // 纯文本
  url,    // URL 链接
  code,   // 代码片段
  email,  // 邮箱地址
  phone,  // 电话号码
  image,  // 图片
}

/// 剪贴板历史记录项
/// 对应 Kotlin data class ClipboardItem
class ClipboardItem {
  /// 数据库主键，自增
  final int? id;

  /// 剪贴板内容文本
  final String content;

  /// 内容类型
  final ClipboardContentType contentType;

  /// 创建时间戳（毫秒）
  final int timestamp;

  /// 内容预览（用于列表显示）
  final String preview;

  /// 字符数量
  final int charCount;

  /// 来源应用/方式
  final String source;

  /// 是否收藏
  final bool isFavorite;

  const ClipboardItem({
    this.id,
    required this.content,
    this.contentType = ClipboardContentType.text,
    required this.timestamp,
    required this.preview,
    this.charCount = 0,
    this.source = 'manual',
    this.isFavorite = false,
  });

  /// 数据库表名常量
  static const String tableName = 'clipboard_history';

  /// 创建表 SQL
  static const String createTableSql = '''
    CREATE TABLE $tableName (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      content TEXT NOT NULL,
      contentType TEXT NOT NULL DEFAULT 'text',
      timestamp INTEGER NOT NULL,
      preview TEXT NOT NULL,
      charCount INTEGER NOT NULL DEFAULT 0,
      source TEXT NOT NULL DEFAULT 'manual',
      isFavorite INTEGER NOT NULL DEFAULT 0
    )
  ''';

  /// 从数据库 Map 转换（用于 sqflite）
  factory ClipboardItem.fromMap(Map<String, dynamic> map) {
    return ClipboardItem(
      id: map['id'] as int?,
      content: map['content'] as String,
      contentType: ClipboardContentType.values.firstWhere(
        (e) => e.name == map['contentType'],
        orElse: () => ClipboardContentType.text,
      ),
      timestamp: map['timestamp'] as int,
      preview: map['preview'] as String,
      charCount: map['charCount'] as int? ?? 0,
      source: map['source'] as String? ?? 'manual',
      isFavorite: (map['isFavorite'] as int? ?? 0) == 1,
    );
  }

  /// 转换为数据库 Map（用于 sqflite）
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'contentType': contentType.name,
      'timestamp': timestamp,
      'preview': preview,
      'charCount': charCount,
      'source': source,
      'isFavorite': isFavorite ? 1 : 0,
    };
  }

  /// 复制并更新字段
  ClipboardItem copyWith({
    int? id,
    String? content,
    ClipboardContentType? contentType,
    int? timestamp,
    String? preview,
    int? charCount,
    String? source,
    bool? isFavorite,
  }) {
    return ClipboardItem(
      id: id ?? this.id,
      content: content ?? this.content,
      contentType: contentType ?? this.contentType,
      timestamp: timestamp ?? this.timestamp,
      preview: preview ?? this.preview,
      charCount: charCount ?? this.charCount,
      source: source ?? this.source,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  /// 从 JSON 反序列化
  factory ClipboardItem.fromJson(Map<String, dynamic> json) {
    return ClipboardItem(
      id: json['id'] as int?,
      content: json['content'] as String,
      contentType: ClipboardContentType.values.firstWhere(
        (e) => e.name == json['contentType'],
        orElse: () => ClipboardContentType.text,
      ),
      timestamp: json['timestamp'] as int,
      preview: json['preview'] as String,
      charCount: json['charCount'] as int? ?? 0,
      source: json['source'] as String? ?? 'manual',
      isFavorite: json['isFavorite'] as bool? ?? false,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'contentType': contentType.name,
      'timestamp': timestamp,
      'preview': preview,
      'charCount': charCount,
      'source': source,
      'isFavorite': isFavorite,
    };
  }

  /// 获取格式化的时间字符串
  String get formattedTime {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// 获取格式化日期字符串
  String get formattedDate {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${dateTime.month}/${dateTime.day}';
  }

  @override
  String toString() {
    return 'ClipboardItem(id: $id, preview: $preview, type: $contentType)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ClipboardItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
