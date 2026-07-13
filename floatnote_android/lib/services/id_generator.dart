/// ID 生成器
/// 兼容 PC 版 Date.now() * 1000 + counter 方案

class IdGenerator {
  static int _counter = 0;

  /// 生成唯一 ID，与 PC 版 generateId() 兼容
  /// PC 版: now * 1000 + _idCounter++
  /// Android 版: 同样逻辑，加随机偏移避免跨设备冲突
  static int generate() {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (_counter > 999) _counter = 0;
    // 加随机偏移 (0-99) 避免跨设备同时操作 ID 冲突
    final randomOffset = DateTime.now().microsecond % 100;
    return now * 1000 + _counter++ + randomOffset;
  }
}
