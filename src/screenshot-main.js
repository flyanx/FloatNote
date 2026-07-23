import { createApp } from 'vue'
import ScreenshotWindow from './ScreenshotWindow.vue'
import i18n from './i18n/index.js'

createApp(ScreenshotWindow).use(i18n).mount('#app')
