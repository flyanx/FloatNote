/**
 * 云同步核心服务
 * 负责数据收集、推送、拉取、本地备份/恢复
 * HTTP 请求通过 Rust 后端代理（绕过 WebView2 网络限制）
 */
import { save, open } from '@tauri-apps/plugin-dialog'
import { writeTextFile, readTextFile } from '@tauri-apps/plugin-fs'
import { invoke } from '@tauri-apps/api/core'
import { syncState, getSupabaseConfig } from './syncState.js'
import i18n from '../i18n/index.js'

// ===== localStorage 需要同步的所有键 =====
const SYNC_KEYS = [
  'sn-notebooks',
  'sn-todolists',
  'sn-trash',
  'sn-item-trash',
  'sn-theme',
  'sn-accent',
  'sn-opacity',
  'sn-sidebar-visible',
  'sn-tabbar-visible',
  'sn-screenshot-hotkey',
  'sn-dev-mode',
  'sn-minimal-mode',
  'sn-active-book',
  'sn-active-todolist',
]

// ===== Rust HTTP 代理封装 =====

/** 安全提取错误消息（兼容 Tauri 各种错误对象结构） */
function safeErrorMessage(e) {
  if (typeof e === 'string') return e
  if (e?.message) return e.message
  try { return String(e) } catch { return i18n.global.t('common.unknownError') }
}

/**
 * 通过 Rust 后端发起 HTTP 请求
 * @param {string} url - 请求 URL
 * @param {string} method - HTTP 方法
 * @param {string} apiKey - Supabase anon key
 * @param {object|null} bodyObj - 请求体对象（可选）
 * @returns {Promise<{ ok: boolean, status: number, body: any }>}
 */
async function httpReq(url, method, apiKey, bodyObj = null, prefer = null) {
  const body = bodyObj ? JSON.stringify(bodyObj) : null
  console.log(`[sync] ${method} ${url}`)
  try {
    const result = await invoke('supabase_request', {
      url,
      method,
      apiKey,
      body,
      prefer,
    })
    console.log(`[sync] ${method} ${url} => ok=${result.ok} status=${result.status}`)
    return result
  } catch (e) {
    const err = safeErrorMessage(e)
    console.error(`[sync] ${method} ${url} 调用失败:`, err)
    throw new Error(err)
  }
}

// ===== 数据收集与恢复 =====

/**
 * 从 localStorage 收集所有需同步的数据
 * @returns {object} payload 对象
 */
export function collectLocalData() {
  const payload = {
    _meta: {
      version: 1,
      appVersion: '1.1.0',
      exportedAt: Date.now(),
    },
    data: {}
  }

  for (const key of SYNC_KEYS) {
    const val = localStorage.getItem(key)
    if (val !== null) {
      payload.data[key] = val
    }
  }

  return payload
}

/**
 * 将远程/导入的 payload 写回 localStorage
 * @param {object} payload - collectLocalData 生成的对象
 * @returns {{ success: boolean, message: string }}
 */
export function applyRemoteData(payload) {
  if (!payload || !payload.data) {
    return { success: false, message: i18n.global.t('sync.invalidFormat') }
  }

  const data = payload.data
  let count = 0

  for (const key of SYNC_KEYS) {
    if (key in data) {
      localStorage.setItem(key, data[key])
      count++
    }
  }

  // 派发事件通知所有组件重新加载数据
  window.dispatchEvent(new CustomEvent('sync-data-applied', {
    detail: { timestamp: Date.now() }
  }))

  return { success: true, message: i18n.global.t('sync.restoredItems', { count }) }
}

// ===== Supabase 推送 =====

/**
 * 推送本地数据到 Supabase 云端
 * @returns {Promise<{ success: boolean, message: string }>}
 */
export async function pushToCloud() {
  const config = getSupabaseConfig()
  if (!config.configured) {
    return { success: false, message: i18n.global.t('sync.notConfigured') }
  }

  syncState.status = 'syncing'
  syncState.errorMessage = ''

  try {
    const payload = collectLocalData()
    // 使用 POST + upsert：若 id=main 行不存在则自动创建，存在则更新
    const apiURL = `${config.url}/rest/v1/app_data`

    const res = await httpReq(apiURL, 'POST', config.key, {
      id: 'main',
      payload: payload,
    }, 'resolution=merge-duplicates,return=minimal')

    if (!res.ok) {
      const errBody = typeof res.body === 'object' ? JSON.stringify(res.body) : res.body
      throw new Error(`HTTP ${res.status}: ${errBody}`)
    }

    syncState.status = 'success'
    syncState.lastSyncTime = Date.now()
    localStorage.setItem('sn-last-sync-time', String(syncState.lastSyncTime))

    return { success: true, message: i18n.global.t('sync.pushSuccess') }
  } catch (e) {
    syncState.status = 'error'
    syncState.errorMessage = safeErrorMessage(e)
    return { success: false, message: i18n.global.t('sync.pushFailed', { error: safeErrorMessage(e) }) }
  }
}

// ===== Supabase 拉取 =====

/**
 * 从 Supabase 云端拉取数据
 * @returns {Promise<{ success: boolean, message: string }>}
 */
export async function pullFromCloud() {
  const config = getSupabaseConfig()
  if (!config.configured) {
    return { success: false, message: i18n.global.t('sync.notConfigured') }
  }

  syncState.status = 'syncing'
  syncState.errorMessage = ''

  try {
    const apiURL = `${config.url}/rest/v1/app_data?id=eq.main&select=payload,updated_at`
    const res = await httpReq(apiURL, 'GET', config.key)

    if (!res.ok) {
      const errBody = typeof res.body === 'object' ? JSON.stringify(res.body) : res.body
      throw new Error(`HTTP ${res.status}: ${errBody}`)
    }

    const rows = Array.isArray(res.body) ? res.body : []
    if (rows.length === 0) {
      syncState.status = 'idle'
      return { success: false, message: i18n.global.t('sync.noCloudData') }
    }

    const { payload, updated_at } = rows[0]
    if (!payload || !payload.data) {
      syncState.status = 'idle'
      return { success: false, message: i18n.global.t('sync.invalidCloudFormat') }
    }

    const result = applyRemoteData(payload)
    if (!result.success) return result

    syncState.status = 'success'
    syncState.lastSyncTime = Date.now()
    localStorage.setItem('sn-last-sync-time', String(syncState.lastSyncTime))

    const serverTime = updated_at ? new Date(updated_at).toLocaleString('zh-CN') : i18n.global.t('sync.unknownTime')
    return { success: true, message: i18n.global.t('sync.pullSuccess', { time: serverTime }) }
  } catch (e) {
    syncState.status = 'error'
    syncState.errorMessage = safeErrorMessage(e)
    return { success: false, message: i18n.global.t('sync.pullFailed', { error: safeErrorMessage(e) }) }
  }
}

// ===== 本地备份导出 =====

/**
 * 导出所有数据为 JSON 文件
 * @returns {Promise<{ success: boolean, message: string }>}
 */
export async function exportToJsonFile() {
  try {
    const payload = collectLocalData()
    const jsonStr = JSON.stringify(payload, null, 2)

    const now = new Date()
    const dateStr = `${now.getFullYear()}${String(now.getMonth()+1).padStart(2,'0')}${String(now.getDate()).padStart(2,'0')}_${String(now.getHours()).padStart(2,'0')}${String(now.getMinutes()).padStart(2,'0')}`
    const defaultName = `floatnote-backup-${dateStr}.json`

    const filePath = await save({
      title: i18n.global.t('sync.exportTitle'),
      defaultPath: defaultName,
      filters: [{ name: i18n.global.t('sync.jsonFilter'), extensions: ['json'] }],
    })

    if (!filePath) {
      return { success: false, message: i18n.global.t('common.cancelShort') }
    }

    await writeTextFile(filePath, jsonStr)
    return { success: true, message: i18n.global.t('sync.exportedTo', { path: filePath }) }
  } catch (e) {
    return { success: false, message: i18n.global.t('sync.exportFailed', { error: safeErrorMessage(e) }) }
  }
}

// ===== 本地备份导入 =====

/**
 * 从 JSON 文件导入数据
 * @returns {Promise<{ success: boolean, message: string }>}
 */
export async function importFromJsonFile() {
  try {
    const filePath = await open({
      title: i18n.global.t('sync.importTitle'),
      filters: [{ name: i18n.global.t('sync.jsonFilter'), extensions: ['json'] }],
      multiple: false,
    })

    if (!filePath) {
      return { success: false, message: i18n.global.t('common.cancelShort') }
    }

    const content = await readTextFile(filePath)
    let payload
    try {
      payload = JSON.parse(content)
    } catch {
      return { success: false, message: i18n.global.t('sync.invalidJson') }
    }

    // 校验数据格式
    if (!payload.data) {
      return { success: false, message: i18n.global.t('sync.invalidFormatNotBackup') }
    }

    // 确认覆盖
    const backupTime = payload._meta?.exportedAt ? new Date(payload._meta.exportedAt).toLocaleString('zh-CN') : i18n.global.t('sync.unknownTime')
    const dataCount = Object.keys(payload.data).length
    const confirmed = window.confirm(
      i18n.global.t('sync.importConfirmTitle', { time: backupTime, count: dataCount })
    )

    if (!confirmed) {
      return { success: false, message: i18n.global.t('common.cancelShort') }
    }

    const result = applyRemoteData(payload)
    return result
  } catch (e) {
    return { success: false, message: i18n.global.t('sync.importFailed', { error: safeErrorMessage(e) }) }
  }
}

// ===== 测试连接 =====

/**
 * 测试 Supabase 连接是否正常
 * @returns {Promise<{ success: boolean, message: string }>}
 */
export async function testConnection() {
  const config = getSupabaseConfig()
  if (!config.configured) {
    return { success: false, message: i18n.global.t('sync.notConfiguredShort') }
  }

  const testURL = `${config.url}/rest/v1/app_data?id=eq.main&select=id,updated_at`

  try {
    const res = await httpReq(testURL, 'GET', config.key)

    if (!res.ok) {
      const errBody = typeof res.body === 'object' ? JSON.stringify(res.body) : res.body
      if (res.status === 404 || (typeof errBody === 'string' && (errBody.includes('relation') || errBody.includes('does not exist')))) {
        return { success: false, message: i18n.global.t('sync.tableNotExist') }
      }
      if (res.status === 401 || res.status === 403) {
        return { success: false, message: i18n.global.t('sync.apiKeyInvalid') }
      }
      return { success: false, message: `HTTP ${res.status}: ${errBody}` }
    }

    const rows = Array.isArray(res.body) ? res.body : []

    if (rows.length === 0) {
      return { success: true, message: i18n.global.t('sync.connectionOk') }
    }

    const updated = rows[0].updated_at
      ? new Date(rows[0].updated_at).toLocaleString('zh-CN')
      : i18n.global.t('sync.noTime')
    return { success: true, message: i18n.global.t('sync.connectionOkWithTime', { time: updated }) }
  } catch (e) {
    return { success: false, message: i18n.global.t('sync.connectionFailed', { error: safeErrorMessage(e) }) }
  }
}
