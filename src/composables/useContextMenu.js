import { ref } from 'vue'

/**
 * 通用右键菜单管理
 * @param {number} widthHint - 菜单预估宽度，默认 150
 * @param {number} heightHint - 菜单预估高度，默认 200
 */
export function useContextMenu(widthHint = 150, heightHint = 200) {
  const menu = ref({ visible: false, x: 0, y: 0 })

  function open(e, extraData = {}) {
    menu.value = {
      visible: true,
      x: Math.min(e.clientX, window.innerWidth - widthHint),
      y: Math.min(e.clientY, window.innerHeight - heightHint),
      ...extraData
    }
  }

  function close() {
    menu.value.visible = false
  }

  function isOpen() {
    return menu.value.visible
  }

  return { menu, open, close, isOpen }
}
