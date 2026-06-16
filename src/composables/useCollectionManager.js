import { ref } from 'vue'
import { readJSON, writeJSON } from '../utils/storage.js'
import { generateId } from '../utils/id.js'
import { addItemToTrash } from '../utils/trash.js'

/**
 * 泛型集合管理器（笔记本/待办列表）
 * @param {Object} options
 * @param {string} options.storageKey - localStorage 键名
 * @param {string} options.eventName - 自定义事件名
 * @param {string} options.defaultName - 新建时的默认名称模板，如 '记事本 {n}'
 * @param {string} options.itemType - 回收站类型标识
 * @param {string} options.itemsField - 子项字段名，如 'notes' 或 'todos'
 * @param {Array} options.initialItems - 新建集合时的初始子项
 */
export function useCollectionManager({
  storageKey,
  eventName,
  defaultName,
  itemType,
  itemsField = 'items',
  initialItems = []
} = {}) {
  const collections = ref(readJSON(storageKey, []))
  const activeId = ref(null)

  function save() {
    writeJSON(storageKey, collections.value)
  }

  function emitUpdate() {
    window.dispatchEvent(new CustomEvent(eventName))
  }

  function addCollection() {
    const item = {
      id: generateId(),
      name: defaultName.replace('{n}', collections.value.length + 1),
      [itemsField]: [...initialItems]
    }
    collections.value.push(item)
    activeId.value = item.id
    save()
    emitUpdate()
    return item
  }

  function switchCollection(id) {
    activeId.value = id
    localStorage.setItem(`sn-active-${itemType}`, id)
  }

  function deleteCollection(id) {
    if (collections.value.length <= 1) return
    const idx = collections.value.findIndex(c => c.id === id)
    const deleted = collections.value[idx]
    if (deleted) addItemToTrash(deleted, itemType)
    collections.value.splice(idx, 1)
    if (activeId.value === id) {
      activeId.value = collections.value[Math.max(0, idx - 1)]?.id || null
    }
    save()
    emitUpdate()
  }

  function renameCollection(id, newName) {
    const item = collections.value.find(c => c.id === id)
    if (item && newName.trim()) {
      item.name = newName.trim()
      save()
      emitUpdate()
    }
  }

  // 初始化 activeId
  const savedActive = localStorage.getItem(`sn-active-${itemType}`)
  if (savedActive) {
    activeId.value = Number(savedActive)
  } else if (collections.value.length > 0) {
    activeId.value = collections.value[0].id
  }

  return {
    collections,
    activeId,
    save,
    addCollection,
    switchCollection,
    deleteCollection,
    renameCollection
  }
}
