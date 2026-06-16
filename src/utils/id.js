/**
 * ID 生成工具
 */
let _idCounter = 0

export function generateId() {
  // 使用 Date.now() + 递增计数器避免同一毫秒内的冲突
  const now = Date.now()
  if (_idCounter > 999) _idCounter = 0
  return now * 1000 + _idCounter++
}
