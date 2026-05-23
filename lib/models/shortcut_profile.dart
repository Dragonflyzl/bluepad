/// 软件面板配置模型
/// 用于分组管理不同应用/场景的快捷键
/// 注意：面板与系统无关，同一面板在不同系统下有各自的快捷键配置

class AppPanel {
  /// 面板唯一标识
  final String id;

  /// 面板名称
  final String name;

  /// 图标 Emoji 或字符
  final String icon;

  /// 面板描述
  final String description;

  const AppPanel({
    required this.id,
    required this.name,
    required this.icon,
    this.description = '',
  });

  /// 复制并更新字段
  AppPanel copyWith({
    String? id,
    String? name,
    String? icon,
    String? description,
  }) {
    return AppPanel(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      description: description ?? this.description,
    );
  }

  /// 从 JSON 反序列化
  factory AppPanel.fromJson(Map<String, dynamic> json) {
    return AppPanel(
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

  /// 获取默认面板列表
  /// 这些面板在 Windows 和 macOS 下都可用
  static List<AppPanel> getDefaults() {
    return const [
      AppPanel(
        id: 'global',
        name: '全局',
        icon: '🌐',
        description: '系统全局快捷键',
      ),
      AppPanel(
        id: 'vscode',
        name: 'VSCode',
        icon: '📝',
        description: 'Visual Studio Code',
      ),
      AppPanel(
        id: 'photoshop',
        name: 'Photoshop',
        icon: '🎨',
        description: 'Adobe Photoshop',
      ),
      AppPanel(
        id: 'browser',
        name: '浏览器',
        icon: '🌐',
        description: '网页浏览器',
      ),
      AppPanel(
        id: 'douyin',
        name: '抖音',
        icon: '🎵',
        description: '抖音短视频',
      ),
    ];
  }

  /// 检查是否为内置面板（不可删除）
  bool get isBuiltIn => ['global', 'douyin', 'vscode', 'photoshop', 'browser'].contains(id);

  @override
  String toString() {
    return 'AppPanel(id: $id, name: $name)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppPanel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// 兼容旧版本的别名
/// @deprecated 使用 AppPanel 代替
typedef ShortcutProfile = AppPanel;