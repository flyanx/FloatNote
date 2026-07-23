<template>
  <div class="screenshot-overlay" @contextmenu.prevent @keydown.esc.prevent="cancel" tabindex="0" ref="overlayEl"
    @mousemove="onMouseMove" @mouseup="onMouseUp">
    <!-- 截图图片（底层） -->
    <img
      ref="imgEl"
      :src="dataUrl"
      class="screenshot-img"
      @load="onImageLoad"
      @mousedown.prevent="onMouseDown"
      @dblclick.prevent="onDblClick"
    />

    <!-- 选区边框 -->
    <div
      v-if="hasSelection"
      class="selection-box"
      :style="selectionStyle"
    >
    </div>

    <!-- 8个微调手柄 -->
    <template v-if="hasSelection && !isDragging">
      <div
        v-for="h in handleList"
        :key="h.id"
        class="sel-handle"
        :class="h.id"
        :style="handleStyle(h.id)"
        @mousedown.stop.prevent="onHandleDown($event, h.id)"
      />
    </template>

    <!-- 尺寸标签 -->
    <div v-if="hasSelection" class="size-label" :style="sizeLabelStyle">
      {{ selW }} × {{ selH }}
    </div>

    <!-- 操作栏 -->
    <div v-if="hasSelection && !isDragging && !isResizing && !isMoving" class="action-bar" :style="actionBarStyle">
      <button class="action-btn copy-btn" @click.stop="confirmCrop" :title="$t('screenshot.copyTitle')">
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <polyline points="20 6 9 17 4 12"/>
        </svg>
        {{ $t('screenshot.copy') }}
      </button>
      <button class="action-btn cancel-btn" @click.stop="cancel" :title="$t('screenshot.cancelTitle')">✕</button>
    </div>

    <!-- 提示 -->
    <div v-if="!hasSelection" class="hint-text">
      {{ $t('screenshot.hint') }}
    </div>
  </div>
</template>

<script setup>
import { useI18n } from 'vue-i18n'
const { t } = useI18n()
import { ref, computed, onMounted, onUnmounted, nextTick } from 'vue'
import { invoke } from '@tauri-apps/api/core'

const props = defineProps({
  dataUrl: { type: String, required: true },
  imgWidth: { type: Number, required: true },
  imgHeight: { type: Number, required: true },
})
const emit = defineEmits(['done', 'cancel'])

const overlayEl = ref(null)
const imgEl = ref(null)

// 选区状态（CSS 像素坐标）
const selStart = ref(null)
const selEnd = ref(null)
const isDragging = ref(false)    // 正在框选
const isResizing = ref(false)    // 正在拖拽手柄
const isMoving = ref(false)      // 正在移动选区
let resizeHandle = null          // 当前拖拽的手柄 id
let moveOrigin = null            // 移动选区时的起始点

// 手柄定义
const handleList = [
  { id: 'tl' }, { id: 't' }, { id: 'tr' },
  { id: 'l' },               { id: 'r' },
  { id: 'bl' }, { id: 'b' }, { id: 'br' },
]

// 图片显示信息
const displayInfo = ref({ width: 0, height: 0, offsetX: 0, offsetY: 0, scale: 1 })

// 计算属性
const hasSelection = computed(() => selStart.value && selEnd.value)

const selRect = computed(() => {
  if (!selStart.value || !selEnd.value) return null
  const x1 = Math.min(selStart.value.x, selEnd.value.x)
  const y1 = Math.min(selStart.value.y, selEnd.value.y)
  const x2 = Math.max(selStart.value.x, selEnd.value.x)
  const y2 = Math.max(selStart.value.y, selEnd.value.y)
  return { x: x1, y: y1, w: x2 - x1, h: y2 - y1 }
})

const selW = computed(() => {
  if (!selRect.value) return 0
  return Math.round(selRect.value.w * displayInfo.value.scale)
})

const selH = computed(() => {
  if (!selRect.value) return 0
  return Math.round(selRect.value.h * displayInfo.value.scale)
})

const selectionStyle = computed(() => {
  const r = selRect.value
  if (!r) return {}
  return {
    left: r.x + 'px',
    top: r.y + 'px',
    width: r.w + 'px',
    height: r.h + 'px',
  }
})

// 手柄位置计算
function handleStyle(id) {
  const r = selRect.value
  if (!r) return {}
  const S = 8 // 手柄尺寸
  let top, left
  if (id.includes('t')) top = r.y - S / 2
  else if (id.includes('b')) top = r.y + r.h - S / 2
  else top = r.y + r.h / 2 - S / 2  // 边中点

  if (id.includes('l')) left = r.x - S / 2
  else if (id.includes('r')) left = r.x + r.w - S / 2
  else left = r.x + r.w / 2 - S / 2  // 边中点

  return { top: top + 'px', left: left + 'px' }
}

const sizeLabelStyle = computed(() => {
  const r = selRect.value
  if (!r) return {}
  return {
    left: r.x + 'px',
    top: Math.max(0, r.y - 28) + 'px',
  }
})

const actionBarStyle = computed(() => {
  const r = selRect.value
  if (!r) return {}
  const top = r.y + r.h + 8
  return {
    left: Math.max(0, r.x + r.w - 120) + 'px',
    top: Math.min(top, window.innerHeight - 44) + 'px',
  }
})

function onImageLoad() {
  const img = imgEl.value
  if (!img) return

  const natW = props.imgWidth
  const natH = props.imgHeight
  const contW = window.innerWidth
  const contH = window.innerHeight

  // 图片需要覆盖整个窗口，使用 cover 模式的等比缩放
  const scaleW = contW / natW
  const scaleH = contH / natH
  const scale = Math.max(scaleW, scaleH)
  const dispW = natW * scale
  const dispH = natH * scale
  const offX = (contW - dispW) / 2
  const offY = (contH - dispH) / 2

  displayInfo.value = {
    width: dispW,
    height: dispH,
    offsetX: offX,
    offsetY: offY,
    scale: natW / dispW,
  }

  nextTick(() => overlayEl.value?.focus())
}

function clampPos(e) {
  const info = displayInfo.value
  const x = Math.max(info.offsetX, Math.min(e.clientX, info.offsetX + info.width))
  const y = Math.max(info.offsetY, Math.min(e.clientY, info.offsetY + info.height))
  return { x, y }
}

// 判断点是否在选区内
function isInsideSelection(pos) {
  const r = selRect.value
  if (!r) return false
  return pos.x >= r.x && pos.x <= r.x + r.w && pos.y >= r.y && pos.y <= r.y + r.h
}

function onMouseDown(e) {
  if (e.button !== 0) return
  const pos = clampPos(e)

  // 已有选区：点击选区内 → 移动选区；点击选区外 → 不做任何事
  if (hasSelection.value && selRect.value && selRect.value.w >= 5 && selRect.value.h >= 5) {
    if (isInsideSelection(pos)) {
      isMoving.value = true
      moveOrigin = { x: pos.x - selRect.value.x, y: pos.y - selRect.value.y }
    }
    return
  }

  // 无选区：开始框选
  selStart.value = pos
  selEnd.value = pos
  isDragging.value = true
}

function onMouseMove(e) {
  const pos = clampPos(e)

  // 框选中
  if (isDragging.value) {
    selEnd.value = pos
    return
  }

  // 拖拽手柄调整选区
  if (isResizing.value && resizeHandle) {
    applyResize(pos)
    return
  }

  // 移动选区
  if (isMoving.value && moveOrigin) {
    const r = selRect.value
    if (!r) return
    const info = displayInfo.value
    const newX = Math.max(info.offsetX, Math.min(pos.x - moveOrigin.x, info.offsetX + info.width - r.w))
    const newY = Math.max(info.offsetY, Math.min(pos.y - moveOrigin.y, info.offsetY + info.height - r.h))
    selStart.value = { x: newX, y: newY }
    selEnd.value = { x: newX + r.w, y: newY + r.h }
    return
  }
}

function onMouseUp(e) {
  if (isDragging.value) {
    isDragging.value = false
    selEnd.value = clampPos(e)
    // 选区太小则清除
    if (selRect.value && selRect.value.w < 5 && selRect.value.h < 5) {
      selStart.value = null
      selEnd.value = null
    }
  }
  if (isResizing.value) {
    isResizing.value = false
    resizeHandle = null
  }
  if (isMoving.value) {
    isMoving.value = false
    moveOrigin = null
  }
}

// 手柄拖拽开始
function onHandleDown(e, handleId) {
  isResizing.value = true
  resizeHandle = handleId
  // 保存固定角/边的坐标
  const r = selRect.value
  if (!r) return
  _resizeFixed = {
    // 对于每个手柄，记录固定不动的对角点
    left: r.x,
    top: r.y,
    right: r.x + r.w,
    bottom: r.y + r.h,
  }
}

let _resizeFixed = null

function applyResize(pos) {
  if (!_resizeFixed) return
  const f = _resizeFixed
  const info = displayInfo.value

  let newLeft = f.left
  let newTop = f.top
  let newRight = f.right
  let newBottom = f.bottom

  // 根据手柄位置调整对应边
  if (resizeHandle.includes('l')) newLeft = pos.x
  if (resizeHandle.includes('r')) newRight = pos.x
  if (resizeHandle.includes('t')) newTop = pos.y
  if (resizeHandle.includes('b')) newBottom = pos.y

  // 只调整手柄涉及的维度（边中点只调一个维度）
  if (resizeHandle === 'l' || resizeHandle === 'r') {
    newTop = f.top
    newBottom = f.bottom
  }
  if (resizeHandle === 't' || resizeHandle === 'b') {
    newLeft = f.left
    newRight = f.right
  }

  // 确保最小尺寸
  if (newRight - newLeft < 5) {
    if (resizeHandle.includes('l')) newLeft = newRight - 5
    else newRight = newLeft + 5
  }
  if (newBottom - newTop < 5) {
    if (resizeHandle.includes('t')) newTop = newBottom - 5
    else newBottom = newTop + 5
  }

  selStart.value = { x: newLeft, y: newTop }
  selEnd.value = { x: newRight, y: newBottom }
}

function onDblClick(e) {
  if (hasSelection.value && selRect.value && selRect.value.w >= 5 && selRect.value.h >= 5) {
    confirmCrop()
  }
}

async function confirmCrop() {
  const r = selRect.value
  if (!r) return

  const scale = displayInfo.value.scale
  const px = Math.round((r.x - displayInfo.value.offsetX) * scale)
  const py = Math.round((r.y - displayInfo.value.offsetY) * scale)
  const pw = Math.round(r.w * scale)
  const ph = Math.round(r.h * scale)

  try {
    await invoke('finish_region_screenshot', {
      x: px, y: py, width: pw, height: ph
    })
    emit('done')
  } catch (e) {
    console.error('截图裁剪失败:', e)
    emit('cancel')
  }
}

async function cancel() {
  try {
    await invoke('cancel_region_screenshot')
  } catch (_) {}
  emit('cancel')
}

function onKeydown(e) {
  if (e.key === 'Escape') {
    cancel()
  } else if (e.key === 'Enter' && hasSelection.value) {
    confirmCrop()
  }
}

onMounted(() => {
  window.addEventListener('keydown', onKeydown)
})

onUnmounted(() => {
  window.removeEventListener('keydown', onKeydown)
})
</script>

<style scoped>
.screenshot-overlay {
  position: fixed;
  inset: 0;
  z-index: 99999;
  background: #000;
  cursor: crosshair;
  outline: none;
  user-select: none;
  animation: overlayFadeIn 0.15s ease;
}

@keyframes overlayFadeIn {
  from { opacity: 0; }
  to { opacity: 1; }
}

.screenshot-img {
  width: 100%;
  height: 100%;
  object-fit: contain;
  display: block;
}

.selection-box {
  position: fixed;
  border: 2px solid #4a9eff;
  box-shadow: 0 0 0 9999px rgba(0, 0, 0, 0.45);
  pointer-events: none;
  z-index: 2;
}

.sel-handle {
  position: fixed;
  width: 8px;
  height: 8px;
  background: white;
  border: 2px solid #4a9eff;
  border-radius: 1px;
  z-index: 5;
  box-shadow: 0 1px 3px rgba(0,0,0,0.3);
}
.sel-handle.tl, .sel-handle.br { cursor: nwse-resize; }
.sel-handle.tr, .sel-handle.bl { cursor: nesw-resize; }
.sel-handle.t, .sel-handle.b { cursor: ns-resize; }
.sel-handle.l, .sel-handle.r { cursor: ew-resize; }

.size-label {
  position: fixed;
  background: #4a9eff;
  color: white;
  padding: 2px 10px;
  border-radius: 4px;
  font-size: 12px;
  font-weight: 500;
  z-index: 3;
  pointer-events: none;
  white-space: nowrap;
  line-height: 1.6;
  animation: sizeLabelIn 0.15s ease;
}
@keyframes sizeLabelIn {
  from { opacity: 0; transform: scale(0.8); }
  to { opacity: 1; transform: scale(1); }
}

.action-bar {
  position: fixed;
  display: flex;
  gap: 4px;
  z-index: 4;
  animation: actionBarIn 0.2s cubic-bezier(0.34, 1.56, 0.64, 1);
}
@keyframes actionBarIn {
  from { opacity: 0; transform: translateY(4px); }
  to { opacity: 1; transform: translateY(0); }
}

.action-btn {
  padding: 4px 14px;
  border: none;
  border-radius: 6px;
  font-size: 12px;
  cursor: pointer;
  display: flex;
  align-items: center;
  gap: 4px;
  font-weight: 500;
  transition: all 0.15s;
}

.copy-btn {
  background: #4a9eff;
  color: white;
}
.copy-btn:hover { background: #3580e0; transform: translateY(-1px); box-shadow: 0 2px 8px rgba(74,158,255,0.4); }
.copy-btn:active { transform: scale(0.95); }

.cancel-btn {
  background: rgba(255, 255, 255, 0.9);
  color: #666;
}
.cancel-btn:hover { background: #ff4d4f; color: white; transform: translateY(-1px); }
.cancel-btn:active { transform: scale(0.95); }

.hint-text {
  position: fixed;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  color: white;
  font-size: 16px;
  font-weight: 500;
  text-shadow: 0 1px 4px rgba(0, 0, 0, 0.6);
  pointer-events: none;
  z-index: 1;
}
</style>
