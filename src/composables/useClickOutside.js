import { onMounted, onUnmounted } from 'vue'

/**
 * 点击外部关闭弹出面板
 * @param {import('vue').Ref<HTMLElement>} targetRef - 目标元素 ref
 * @param {Function} handler - 点击外部时的回调
 */
export function useClickOutside(targetRef, handler) {
  function onClick(e) {
    if (!targetRef.value) return
    if (targetRef.value.contains(e.target)) return
    handler(e)
  }

  onMounted(() => {
    document.addEventListener('click', onClick)
  })
  onUnmounted(() => {
    document.removeEventListener('click', onClick)
  })

  return onClick
}
