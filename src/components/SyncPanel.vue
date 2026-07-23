<template>
  <div class="sync-panel" @click.stop>
    <!-- 标题 -->
    <div class="sync-header">
      <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <path d="M18 10h-1.26A8 8 0 1 0 9 20h9a5 5 0 0 0 0-10z"/>
      </svg>
      <span>{{ $t('sync.title') }}</span>
      <span class="sync-time" v-if="syncState.lastSyncTime">
        {{ formatDateTime(syncState.lastSyncTime) }}
      </span>
    </div>

    <!-- 操作按钮 -->
    <div class="sync-actions">
      <button
        class="sync-btn push-btn"
        :disabled="syncState.status === 'syncing' || !syncState.configured"
        @click="doPush"
      >
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <line x1="12" y1="19" x2="12" y2="5"/><polyline points="5 12 12 5 19 12"/>
        </svg>
        {{ $t('sync.pushToCloud') }}
      </button>
      <button
        class="sync-btn pull-btn"
        :disabled="syncState.status === 'syncing' || !syncState.configured"
        @click="doPull"
      >
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <line x1="12" y1="5" x2="12" y2="19"/><polyline points="19 12 12 19 5 12"/>
        </svg>
        {{ $t('sync.pullFromCloud') }}
      </button>
    </div>

    <!-- 状态消息 -->
    <div class="sync-msg" v-if="msg" :class="msgType">
      {{ msg }}
      <button v-if="msgType === 'error' && lastAction" class="retry-btn" @click="doRetry">{{ $t('sync.retry') }}</button>
    </div>

    <!-- 分隔线 -->
    <div class="sync-divider">{{ $t('sync.localBackup') }}</div>

    <!-- 本地备份按钮 -->
    <div class="sync-actions">
      <button class="sync-btn" @click="doExport">
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/>
          <polyline points="7 10 12 15 17 10"/><line x1="12" y1="15" x2="12" y2="3"/>
        </svg>
        {{ $t('sync.exportJson') }}
      </button>
      <button class="sync-btn" @click="doImport">
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/>
          <polyline points="17 8 12 3 7 8"/><line x1="12" y1="3" x2="12" y2="15"/>
        </svg>
        {{ $t('sync.importJson') }}
      </button>
    </div>

    <!-- 分隔线 -->
    <div class="sync-divider">
      {{ $t('sync.supabaseSettings') }}
      <a v-if="dashboardUrl" :href="dashboardUrl" target="_blank" class="supabase-link" :title="$t('sync.openDashboard')" @click.stop>
        <svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
          <path d="M18 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h6"/>
          <polyline points="15 3 21 3 21 9"/>
          <line x1="10" y1="14" x2="21" y2="3"/>
        </svg>
      </a>
    </div>

    <!-- Supabase 配置 -->
    <div class="sync-config">
      <div class="config-field">
        <label>URL</label>
        <input
          type="text"
          v-model="configUrl"
          placeholder="https://xxxx.supabase.co"
          class="config-input"
        />
      </div>
      <div class="config-field">
        <label>API Key</label>
        <input
          type="password"
          v-model="configKey"
          placeholder="eyJhbGciOi..."
          class="config-input"
        />
      </div>
      <button class="sync-btn config-save-btn" @click="doSaveConfig">
        {{ $t('sync.saveConfig') }}
      </button>
      <button class="sync-btn config-test-btn" @click="doTest" :disabled="syncState.status === 'syncing'">
        {{ $t('sync.testConnection') }}
      </button>
    </div>
  </div>
</template>

<script setup>
import { useI18n } from 'vue-i18n'
const { t } = useI18n()
import { ref, computed, onMounted } from 'vue'
import { syncState, getSupabaseConfig, saveSupabaseConfig, initSyncState } from '../services/syncState.js'
import { pushToCloud, pullFromCloud, exportToJsonFile, importFromJsonFile, testConnection } from '../services/syncService.js'
import { formatDateTime } from '../utils/date.js'

const configUrl = ref('')
const configKey = ref('')
const msg = ref('')
const msgType = ref('') // 'success' | 'error' | 'info'
const lastAction = ref('') // 'push' | 'pull' | 'test'

const dashboardUrl = computed(() => {
  const m = configUrl.value.match(/https:\/\/([^.]+)\.supabase\.co/)
  return m ? `https://supabase.com/dashboard/project/${m[1]}` : null
})

onMounted(async () => {
  await initSyncState()
  const config = getSupabaseConfig()
  configUrl.value = config.url
  configKey.value = config.key
})

function showMsg(text, type = 'info', duration = 4000) {
  msg.value = text
  msgType.value = type
  if (duration > 0) {
    setTimeout(() => { msg.value = '' }, duration)
  }
}

async function doPush() {
  lastAction.value = 'push'
  showMsg(t('sync.pushing'), 'info', 0)
  const result = await pushToCloud()
  showMsg(result.message, result.success ? 'success' : 'error')
}

async function doPull() {
  lastAction.value = 'pull'
  showMsg(t('sync.pulling'), 'info', 0)
  const result = await pullFromCloud()
  showMsg(result.message, result.success ? 'success' : 'error')
}

async function doExport() {
  const result = await exportToJsonFile()
  if (result.message !== t('common.cancelShort')) {
    showMsg(result.message, result.success ? 'success' : 'error')
  }
}

async function doImport() {
  const result = await importFromJsonFile()
  if (result.message !== t('common.cancelShort')) {
    showMsg(result.message, result.success ? 'success' : 'error')
  }
}

async function doSaveConfig() {
  if (!configUrl.value || !configKey.value) {
    showMsg(t('sync.fillUrlAndKey'), 'error')
    return
  }
  await saveSupabaseConfig(configUrl.value, configKey.value)
  showMsg(t('sync.configSaved'), 'success')
}

async function doTest() {
  lastAction.value = 'test'
  // 先保存当前输入的配置
  if (configUrl.value && configKey.value) {
    await saveSupabaseConfig(configUrl.value, configKey.value)
  }
  showMsg(t('sync.testing'), 'info', 0)
  const result = await testConnection()
  showMsg(result.message, result.success ? 'success' : 'error', 6000)
}

async function doRetry() {
  if (lastAction.value === 'push') return doPush()
  if (lastAction.value === 'pull') return doPull()
  if (lastAction.value === 'test') return doTest()
}
</script>

<style scoped>
.sync-panel {
  position: absolute;
  top: calc(100% + 6px);
  right: 0;
  z-index: 200;
  background: var(--bg-surface);
  border: 0.5px solid var(--border);
  border-radius: 12px;
  padding: 12px 14px;
  box-shadow: 0 8px 32px rgba(0,0,0,0.22);
  width: 260px;
  animation: fadeIn 0.12s ease;
  color: var(--text);
}

.sync-header {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 13px;
  font-weight: 600;
  margin-bottom: 10px;
}

.sync-time {
  margin-left: auto;
  font-size: 11px;
  font-weight: 400;
  color: var(--text-secondary, #999);
}

.sync-actions {
  display: flex;
  gap: 8px;
  margin-bottom: 6px;
}

.sync-btn {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 4px;
  padding: 7px 8px;
  border: 0.5px solid var(--border);
  border-radius: 8px;
  background: var(--bg-input, var(--bg-surface));
  color: var(--text);
  font-size: 12px;
  cursor: pointer;
  transition: all 0.15s;
}
.sync-btn:hover:not(:disabled) {
  background: var(--bg-hover, rgba(0,0,0,0.06));
}
.sync-btn:disabled {
  opacity: 0.45;
  cursor: not-allowed;
}

.push-btn:hover:not(:disabled) {
  border-color: #22c55e;
  color: #22c55e;
}
.pull-btn:hover:not(:disabled) {
  border-color: #4a9eff;
  color: #4a9eff;
}

.sync-msg {
  font-size: 11px;
  padding: 4px 8px;
  border-radius: 6px;
  margin-bottom: 6px;
  word-break: break-all;
}
.sync-msg.success { background: rgba(34,197,94,0.12); color: #22c55e; }
.sync-msg.error  { background: rgba(232,69,60,0.12); color: #e8453c; display: flex; align-items: center; justify-content: space-between; gap: 8px; }
.sync-msg.info   { background: rgba(74,158,255,0.1); color: #4a9eff; }

.retry-btn {
  flex-shrink: 0;
  padding: 2px 10px;
  border: 0.5px solid currentColor;
  background: transparent;
  border-radius: 4px;
  color: inherit;
  font-size: 11px;
  cursor: pointer;
  transition: all 0.15s;
}
.retry-btn:hover {
  background: currentColor;
  color: #fff;
}

.sync-divider {
  font-size: 11px;
  color: var(--text-secondary, #999);
  margin: 10px 0 8px;
  padding-top: 8px;
  border-top: 0.5px solid var(--border);
  display: flex;
  align-items: center;
  gap: 6px;
}

.supabase-link {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 18px;
  height: 18px;
  border-radius: 4px;
  color: var(--text-secondary, #999);
  text-decoration: none;
  transition: all 0.15s;
  flex-shrink: 0;
}
.supabase-link:hover {
  color: #3ecf8e;
  background: rgba(62, 207, 142, 0.12);
}

.sync-config {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.config-field {
  display: flex;
  flex-direction: column;
  gap: 3px;
}

.config-field label {
  font-size: 11px;
  color: var(--text-secondary, #999);
}

.config-input {
  width: 100%;
  padding: 6px 8px;
  border: 0.5px solid var(--border);
  border-radius: 6px;
  background: var(--bg-input, var(--bg-surface));
  color: var(--text);
  font-size: 12px;
  outline: none;
  box-sizing: border-box;
}
.config-input:focus {
  border-color: var(--accent, #4a9eff);
}
.config-input::placeholder {
  color: var(--text-secondary, #999);
  opacity: 0.6;
}

.config-save-btn {
  margin-top: 2px;
  justify-content: center;
}
.config-test-btn {
  margin-top: 2px;
  justify-content: center;
}

@keyframes fadeIn {
  from { opacity: 0; transform: translateY(-4px); }
  to   { opacity: 1; transform: translateY(0); }
}
</style>
