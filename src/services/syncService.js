/**
 * 云同步核心服务
 * 负责数据收集、推送、拉取、本地备份/恢复
 * HTTP 请求通过 Rust 后端代理（绕过 WebView2 网络限制）
 */
import { save, open } from '@tauri-apps/plugin-dialog'
import { writeTextFile, readTextFile } from '@tauri-apps/plugin-fs'
import { invoke } from '@tauri-apps/api/core'
import { syncState, getSupabaseConfig } from './syncState.js'

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
  const result = await invoke('supabase_request', {
    url,
    method,
    apiKey,
    body,
    prefer,
  })
  return result
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
    return { success: false, message: '数据格式无效：缺少 data 字段' }
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

  return { success: true, message: `已恢复 ${count} 项数据` }
}

// ===== Supabase 推送 =====

/**
 * 推送本地数据到 Supabase 云端
 * @returns {Promise<{ success: boolean, message: string }>}
 */
export async function pushToCloud() {
  const config = getSupabaseConfig()
  if (!config.configured) {
    return { success: false, message: '请先配置 Supabase URL 和 API Key' }
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

    return { success: true, message: '推送成功' }
  } catch (e) {
    syncState.status = 'error'
    syncState.errorMessage = e.message
    return { success: false, message: `推送失败: ${e.message}` }
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
    return { success: false, message: '请先配置 Supabase URL 和 API Key' }
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
      return { success: false, message: '云端暂无数据，请先点击「推送到云端」' }
    }

    const { payload, updated_at } = rows[0]
    if (!payload || !payload.data) {
      syncState.status = 'idle'
      return { success: false, message: '云端数据格式无效' }
    }

    const result = applyRemoteData(payload)
    if (!result.success) return result

    syncState.status = 'success'
    syncState.lastSyncTime = Date.now()
    localStorage.setItem('sn-last-sync-time', String(syncState.lastSyncTime))

    const serverTime = updated_at ? new Date(updated_at).toLocaleString('zh-CN') : '未知'
    return { success: true, message: `拉取成功 (云端时间: ${serverTime})` }
  } catch (e) {
    syncState.status = 'error'
    syncState.errorMessage = e.message
    return { success: false, message: `拉取失败: ${e.message}` }
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
      title: '导出备份文件',
      defaultPath: defaultName,
      filters: [{ name: 'JSON 文件', extensions: ['json'] }],
    })

    if (!filePath) {
      return { success: false, message: '已取消' }
    }

    await writeTextFile(filePath, jsonStr)
    return { success: true, message: `已导出到: ${filePath}` }
  } catch (e) {
    return { success: false, message: `导出失败: ${e.message}` }
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
      title: '选择备份文件',
      filters: [{ name: 'JSON 文件', extensions: ['json'] }],
      multiple: false,
    })

    if (!filePath) {
      return { success: false, message: '已取消' }
    }

    const content = await readTextFile(filePath)
    let payload
    try {
      payload = JSON.parse(content)
    } catch {
      return { success: false, message: '文件格式错误：不是有效的 JSON' }
    }

    // 校验数据格式
    if (!payload.data) {
      return { success: false, message: '数据格式无效：缺少 data 字段\n这不是 FloatNote 的备份文件' }
    }

    // 确认覆盖
    const confirmed = window.confirm(
      '导入将覆盖当前所有本地数据！\n\n' +
      `备份时间: ${payload._meta?.exportedAt ? new Date(payload._meta.exportedAt).toLocaleString('zh-CN') : '未知'}\n` +
      `数据项数: ${Object.keys(payload.data).length} 项\n\n` +
      '确定要继续吗？'
    )

    if (!confirmed) {
      return { success: false, message: '已取消' }
    }

    const result = applyRemoteData(payload)
    return result
  } catch (e) {
    return { success: false, message: `导入失败: ${e.message}` }
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
    return { success: false, message: '请先填写 URL 和 API Key' }
  }

  const testURL = `${config.url}/rest/v1/app_data?id=eq.main&select=id,updated_at`

  try {
    const res = await httpReq(testURL, 'GET', config.key)

    if (!res.ok) {
      const errBody = typeof res.body === 'object' ? JSON.stringify(res.body) : res.body
      if (res.status === 404 || (typeof errBody === 'string' && (errBody.includes('relation') || errBody.includes('does not exist')))) {
        return { success: false, message: '连接成功，但 app_data 表不存在。\n请在 Supabase SQL Editor 中执行建表 SQL。' }
      }
      if (res.status === 401 || res.status === 403) {
        return { success: false, message: 'API Key 无效或权限不足。\n请检查 Key 是否正确，或尝试重新生成。' }
      }
      return { success: false, message: `HTTP ${res.status}: ${errBody}` }
    }

    const rows = Array.isArray(res.body) ? res.body : []

    if (rows.length === 0) {
      return { success: true, message: '连接正常！尚未推送过数据，点击「推送到云端」即可自动创建。' }
    }

    const updated = rows[0].updated_at
      ? new Date(rows[0].updated_at).toLocaleString('zh-CN')
      : '无'
    return { success: true, message: `连接正常！上次更新: ${updated}` }
  } catch (e) {
    return { success: false, message: `连接失败: ${e.message}` }
  }
}
