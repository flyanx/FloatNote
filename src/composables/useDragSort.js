import { ref } from 'vue'

/**
 * 长按拖拽排序
 * @param {import('vue').Ref<Array>} listRef - 列表数据 ref
 * @param {Function} onReorder - 排序完成回调 (list, fromIndex, toIndex)
 * @param {number} threshold - 长按触发阈值(ms)，默认 300
 */
export function useDragSort(listRef, onReorder, threshold = 300) {
  const dragItemId = ref(null)
  const dragOverId = ref(null)
  let _dragStartY = 0
  let _dragTimer = null

  function onDragStart(e, item) {
    if (e.button !== 0) return
    _dragStartY = e.clientY
    _dragTimer = setTimeout(() => {
      dragItemId.value = item.id
      document.addEventListener('pointermove', onDragMove)
      document.addEventListener('pointerup', onDragEnd)
    }, threshold)
    document.addEventListener('pointerup', cancelDrag)
    document.addEventListener('pointercancel', cancelDrag)
  }

  function onDragMove(e) {
    // 找到鼠标下方的元素
    const el = document.elementFromPoint(e.clientX, e.clientY)
    if (el) {
      const card = el.closest('[data-drag-id]')
      dragOverId.value = card ? Number(card.dataset.dragId) : null
    }
  }

  function onDragEnd(e) {
    document.removeEventListener('pointermove', onDragMove)
    document.removeEventListener('pointerup', onDragEnd)
    document.removeEventListener('pointerup', cancelDrag)
    document.removeEventListener('pointercancel', cancelDrag)

    if (dragItemId.value !== null && dragOverId.value !== null && dragItemId.value !== dragOverId.value) {
      const list = listRef.value
      const fromIdx = list.findIndex(i => i.id === dragItemId.value)
      const toIdx = list.findIndex(i => i.id === dragOverId.value)
      if (fromIdx !== -1 && toIdx !== -1) {
        const [moved] = list.splice(fromIdx, 1)
        list.splice(toIdx, 0, moved)
        if (onReorder) onReorder(list, fromIdx, toIdx)
      }
    }

    dragItemId.value = null
    dragOverId.value = null
    clearTimeout(_dragTimer)
  }

  function cancelDrag() {
    clearTimeout(_dragTimer)
    document.removeEventListener('pointerup', cancelDrag)
    document.removeEventListener('pointercancel', cancelDrag)
  }

  return { dragItemId, dragOverId, onDragStart }
}
