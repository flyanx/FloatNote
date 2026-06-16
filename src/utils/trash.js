/**
 * 回收站工具
 */
const ITEM_TRASH_KEY = 'sn-item-trash'

export function addItemToTrash(item, type) {
  let trash = []
  try { trash = JSON.parse(localStorage.getItem(ITEM_TRASH_KEY) || '[]') } catch {}
  trash.push({
    id: item.id,
    name: item.title || item.text || item.name || '无标题',
    type,
    deletedAt: Date.now(),
    data: JSON.parse(JSON.stringify(item))
  })
  // 清理 30 天前的记录
  const cutoff = Date.now() - 30 * 24 * 60 * 60 * 1000
  trash = trash.filter(t => t.deletedAt > cutoff)
  localStorage.setItem(ITEM_TRASH_KEY, JSON.stringify(trash))
}

export { ITEM_TRASH_KEY }
