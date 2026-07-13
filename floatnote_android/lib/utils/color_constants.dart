/// 颜色常量
/// 与 PC 版 colors.js 完全一致

class ColorConstants {
  /// 笔记颜色（8 色）
  static const List<String> noteColors = [
    '#5b5ef4', '#22c55e', '#f59e0b', '#e8453c',
    '#8b5cf6', '#ec4899', '#06b6d4', '#f97316',
  ];

  /// 标签页颜色（含无颜色选项）
  static const List<String> tabColors = [
    '', '#5b5ef4', '#22c55e', '#f59e0b', '#e8453c',
    '#8b5cf6', '#ec4899', '#06b6d4', '#f97316',
  ];

  /// 优先级配置
  static const List<Map<String, String>> priorities = [
    {'val': 'high', 'label': '高', 'color': '#e8453c'},
    {'val': 'mid', 'label': '中', 'color': '#f59e0b'},
    {'val': 'low', 'label': '低', 'color': '#22c55e'},
  ];
}
