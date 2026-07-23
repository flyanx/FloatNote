<template>
  <div v-if="loading" class="ss-loading">
    <span>{{ $t('screenshot.loading') }}</span>
  </div>
  <ScreenshotOverlay
    v-else-if="screenshotData"
    :data-url="screenshotData.dataUrl"
    :img-width="screenshotData.imgWidth"
    :img-height="screenshotData.imgHeight"
    @done="onDone"
    @cancel="onCancel"
  />
</template>

<script setup>
import { useI18n } from 'vue-i18n'
const { t } = useI18n()
import { ref, onMounted } from 'vue'
import { invoke } from '@tauri-apps/api/core'
import { getCurrentWebviewWindow } from '@tauri-apps/api/webviewWindow'
import ScreenshotOverlay from './components/ScreenshotOverlay.vue'

const loading = ref(true)
const screenshotData = ref(null)

onMounted(async () => {
  try {
    const data = await invoke('get_screenshot_data')
    screenshotData.value = data
  } catch (e) {
    console.error('获取截图数据失败:', e)
    await closeWindow()
  } finally {
    loading.value = false
  }
})

async function onDone() {
  await closeWindow()
}

async function onCancel() {
  try { await invoke('cancel_region_screenshot') } catch (_) {}
  await closeWindow()
}

async function closeWindow() {
  try {
    const win = getCurrentWebviewWindow()
    await win.close()
  } catch (e) {
    console.error('关闭截图窗口失败:', e)
  }
}
</script>

<style>
.ss-loading {
  position: fixed;
  inset: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  background: #000;
  color: white;
  font-size: 16px;
  z-index: 99999;
}
</style>
