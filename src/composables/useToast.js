import { ref } from 'vue'

/**
 * Toast 消息提示
 * @param {number} defaultDuration - 默认显示时长(ms)
 */
export function useToast(defaultDuration = 2000) {
  const toast = ref({ show: false, message: '', timer: null })

  function showToast(message, duration = defaultDuration) {
    toast.value.show = true
    toast.value.message = message
    clearTimeout(toast.value.timer)
    toast.value.timer = setTimeout(() => {
      toast.value.show = false
    }, duration)
  }

  function hideToast() {
    toast.value.show = false
    clearTimeout(toast.value.timer)
  }

  return { toast, showToast, hideToast }
}
