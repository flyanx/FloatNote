/// 文本工具
/// 提取预览文本（去除 HTML/Markdown 标签）

class TextUtils {
  /// 从内容提取预览文本，去除 HTML 标签和 Markdown 符号
  static String getPreview(String content, {int maxLen = 60}) {
    if (content.isEmpty) return '无内容';
    // 去除 HTML 标签
    var text = content.replaceAll(RegExp(r'<[^>]*>'), '');
    // 去除常见 Markdown 符号
    text = text.replaceAll(RegExp(r'[#*_~`>\[\]()!|]'), '');
    // 合并空白
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (text.isEmpty) return '无内容';
    if (text.length > maxLen) {
      return '${text.substring(0, maxLen)}…';
    }
    return text;
  }
}
