/// 日期格式化工具
/// 与 PC 版 date.js 完全一致的逻辑

import 'package:intl/intl.dart';

class AppDateUtils {
  /// 相对日期（今天/昨天/M/D）
  static String formatRelativeDate(int ts) {
    final d = DateTime.fromMillisecondsSinceEpoch(ts);
    final now = DateTime.now();
    final diff = (now.difference(d).inMilliseconds / 86400000).round();
    if (diff == 0) return '今天';
    if (diff == 1) return '昨天';
    return '${d.month}/${d.day}';
  }

  /// 格式化同步时间 MM-DD HH:mm
  static String formatDateTime(int? ts) {
    if (ts == null || ts == 0) return '';
    final d = DateTime.fromMillisecondsSinceEpoch(ts);
    return DateFormat('MM-dd HH:mm').format(d);
  }

  /// 格式化到期日
  static String formatDueDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final target = DateTime(date.year, date.month, date.day);
      final diff = target.difference(today).inDays;
      if (diff == 0) return '今天';
      if (diff == 1) return '明天';
      if (diff == -1) return '昨天';
      if (diff < -1) return '已过期${-diff}天';
      if (diff <= 7) return '${diff}天后';
      return '${date.month}/${date.day}';
    } catch (_) {
      return dateStr;
    }
  }

  /// 判断到期日是否过期
  static bool isOverdue(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return false;
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final target = DateTime(date.year, date.month, date.day);
      return target.isBefore(today);
    } catch (_) {
      return false;
    }
  }

  /// 当前日期转 YYYY-MM-DD 字符串
  static String toDateString(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }
}
