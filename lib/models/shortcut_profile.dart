/// 快捷键配置文件数据模型
/// 对应 Android: data class ShortcutProfile
/// 用于分组管理不同应用/场景的快捷键

class ShortcutProfile {
  /// 配置文件唯一标识
  final String id;

  /// 配置文件名称
  final String name;

  /// 图标 Emoji 或字符
  final String icon;

  /// 配置文件描述
  final String description;

  const ShortcutProfile({
    required this.id,
    required this.name,
    required this.icon,
    this.description = '',
  });

  /// 复制并更新字段
  ShortcutProfile copyWith({
    String? id,
    String? name,
    String? icon,
    String? description,
  }) {
    return ShortcutProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      description: description ?? this.description,
    );
  }

  /// 从 JSON 反序列化
  factory ShortcutProfile.fromJson(Map<String, dynamic> json) {
    return ShortcutProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String,
      description: json['description'] as String? ?? '',
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'description': description,
    };
  }

  /// 获取默认配置文件列表
  static List<ShortcutProfile> getDefaults() {
    return const [
      ShortcutProfile(
        id: 'global',
        name: '全局',
        icon: '🌐',
        description: '全局通用快捷键',
      ),
      ShortcutProfile(
        id: 'vscode',
        name: 'VSCode',
        icon: '📝',
        description: 'Visual Studio Code',
      ),
      ShortcutProfile(
        id: 'ps',
        name: 'Photoshop',
        icon: '🎨',
        description: 'Adobe Photoshop',
      ),
      ShortcutProfile(
        id: 'browser',
        name: '浏览器',
        icon: '🌍',
        description: '网页浏览器',
      ),
    ];
  }

  /// 检查是否为内置配置（不可删除）
  bool get isBuiltIn => ['global', 'vscode', 'ps', 'browser'].contains(id);

  @override
  String toString() {
    return 'ShortcutProfile(id: $id, name: $name)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ShortcutProfile && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
