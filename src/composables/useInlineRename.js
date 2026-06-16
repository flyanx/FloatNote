import { ref, nextTick } from 'vue'

/**
 * 内联重命名
 * @param {Function} saveFn - 保存回调 (item, newText)
 * @param {string} selector - 重命名输入框选择器
 */
export function useInlineRename(saveFn, selector = '.rename-inline-input') {
  const renamingId = ref(null)
  const renameText = ref('')

  function startRename(item) {
    renamingId.value = item.id
    renameText.value = item.text || item.name || item.title || ''
    nextTick(() => {
      const inputs = document.querySelectorAll(selector)
      if (inputs.length) {
        const last = inputs[inputs.length - 1]
        last.focus()
        last.select()
      }
    })
  }

  function finishRename(item) {
    const trimmed = renameText.value.trim()
    if (trimmed) {
      if (saveFn) saveFn(item, trimmed)
    }
    renamingId.value = null
    renameText.value = ''
  }

  function cancelRename() {
    renamingId.value = null
    renameText.value = ''
  }

  return { renamingId, renameText, startRename, finishRename, cancelRename }
}
