/**
 * 云同步状态管理
 * 全局响应式状态，供 SyncPanel 和 App.vue 使用
 */
import { reactive } from 'vue'
import { invoke } from '@tauri-apps/api/core'

export const syncState = reactive({
  status: 'idle',       // 'idle' | 'syncing' | 'success' | 'error'
  lastSyncTime: null,    // 上次成功同步的时间戳 (ms)
  errorMessage: '',      // 错误信息
  configured: false      // Supabase 是否已配置
})

/**
 * 从 localStorage 读取 Supabase 配置（同步，仅作缓存）
 * @returns {{ url: string, key: string, configured: boolean }}
 */
export function getSupabaseConfig() {
  const url = localStorage.getItem('sn-supabase-url') || ''
  const key = localStorage.getItem('sn-supabase-key') || ''
  return { url, key, configured: !!(url && key) }
}

/**
 * 保存 Supabase 配置到 localStorage + 文件（双重持久化）
 */
export async function saveSupabaseConfig(url, key) {
  const trimmedUrl = url.trim().replace(/\/+$/, '')
  const trimmedKey = key.trim()

  // 1. 立即写入 localStorage
  localStorage.setItem('sn-supabase-url', trimmedUrl)
  localStorage.setItem('sn-supabase-key', trimmedKey)
  syncState.configured = !!(url && key)

  // 2. 异步写入文件（防止 WebView2 清理 localStorage 导致丢失）
  try {
    await invoke('save_config_to_file', {
      data: JSON.stringify({ url: trimmedUrl, key: trimmedKey })
    })
  } catch (e) {
    console.warn('文件持久化配置失败:', e?.message || e)
  }
}

/**
 * 初始化同步状态（异步：优先 localStorage，回退读取文件）
 */
export async function initSyncState() {
  const config = getSupabaseConfig()

  // localStorage 为空时，尝试从文件恢复
  if (!config.configured) {
    try {
      const data = await invoke('load_config_from_file')
      const fileConfig = JSON.parse(data)
      if (fileConfig.url && fileConfig.key) {
        localStorage.setItem('sn-supabase-url', fileConfig.url)
        localStorage.setItem('sn-supabase-key', fileConfig.key)
        syncState.configured = true
      }
    } catch (e) {
      console.warn('从文件加载配置失败:', e?.message || e)
    }
  } else {
    syncState.configured = true
    // localStorage 有数据时，同步到文件备份
    try {
      await invoke('save_config_to_file', {
        data: JSON.stringify({ url: config.url, key: config.key })
      })
    } catch (e) {
      console.warn('同步配置到文件失败:', e)
    }
  }

  // 恢复上次同步时间
  const lastTime = localStorage.getItem('sn-last-sync-time')
  if (lastTime) {
    syncState.lastSyncTime = parseInt(lastTime, 10)
  }
}
