/// 回收站项数据模型
/// 与 PC 版 sn-trash / sn-item-trash JSON 格式兼容

class TrashItem {
  final int id;
  final String name;
  final String type; // 'book' | 'list' | 'note' | 'todo'
  final int deletedAt; // 时间戳 ms
  final Map<String, dynamic> data; // 原始项完整深拷贝
  final bool isItem; // 标记是否来自 item-trash

  const TrashItem({
    required this.id,
    required this.name,
    required this.type,
    required this.deletedAt,
    required this.data,
    this.isItem = false,
  });

  factory TrashItem.fromJson(Map<String, dynamic> json, {bool isItem = false}) {
    return TrashItem(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? 'book',
      deletedAt: json['deletedAt'] as int? ?? 0,
      data: (json['data'] as Map<String, dynamic>?) ?? {},
      isItem: isItem,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type,
        'deletedAt': deletedAt,
        'data': data,
      };

  /// 是否已过期（30天）
  bool get isExpired {
    final cutoff = DateTime.now().millisecondsSinceEpoch - 30 * 24 * 60 * 60 * 1000;
    return deletedAt < cutoff;
  }

  /// 类型图标 emoji
  String get typeEmoji {
    switch (type) {
      case 'book':
        return '📓';
      case 'list':
        return '📋';
      case 'note':
        return '📝';
      case 'todo':
        return '✅';
      default:
        return '📄';
    }
  }
}
