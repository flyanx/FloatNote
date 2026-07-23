/**
 * 日期格式化工具
 */
import i18n from '../i18n/index.js'

export function formatRelativeDate(ts) {
  const d = new Date(ts)
  const now = new Date()
  const diff = Math.round((now - d) / 86400000)
  if (diff === 0) return i18n.global.t('date.today')
  if (diff === 1) return i18n.global.t('date.yesterday')
  return `${d.getMonth() + 1}/${d.getDate()}`
}

export function formatDateTime(ts) {
  if (!ts) return ''
  const d = new Date(ts)
  const pad = n => String(n).padStart(2, '0')
  return `${pad(d.getMonth() + 1)}-${pad(d.getDate())} ${pad(d.getHours())}:${pad(d.getMinutes())}`
}
