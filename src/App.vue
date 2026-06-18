<template>
  <div class="app-shell" :data-theme="theme" :data-accent="accent" :class="{ closing: isClosing, 'minimal-mode': minimalMode }">

    <!-- 自定义标题栏 / 拖拽区域 -->
    <div class="titlebar" @dblclick="toggleCompact">
      <div class="titlebar-brand" v-show="!minimalMode">
        <svg class="brand-icon" width="16" height="16" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
          <rect x="4" y="3" width="16" height="20" rx="3" fill="var(--accent)" opacity="0.2"/>
          <rect x="6" y="5" width="12" height="16" rx="2" fill="var(--accent)" opacity="0.35"/>
          <line x1="9" y1="10" x2="15" y2="10" stroke="var(--accent)" stroke-width="1.5" stroke-linecap="round"/>
          <line x1="9" y1="14" x2="13" y2="14" stroke="var(--accent)" stroke-width="1.5" stroke-linecap="round"/>
          <path d="M4 8h16" stroke="var(--accent)" stroke-width="1.5"/>
        </svg>
        <span class="brand-name">灵签</span>
        <span class="brand-en">FloatNote</span>
        <span class="brand-ver">V 1.2.0</span>
      </div>
      <!-- 极简模式下的记事本/待办切换（放在左侧品牌位置） -->
      <div class="titlebar-tab-switch" v-if="minimalMode">
        <button class="titlebar-tab-btn" :class="{ active: activeTab === 'note' }" @click="activeTab = 'note'" title="记事本">
          <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/>
          </svg>
        </button>
        <button class="titlebar-tab-btn" :class="{ active: activeTab === 'todo' }" @click="activeTab = 'todo'" title="待办">
          <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <polyline points="9 11 12 14 22 4"/><path d="M21 12v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11"/>
          </svg>
          <span class="todo-badge" v-if="pendingCount > 0">{{ pendingCount }}</span>
        </button>
      </div>
      <div class="titlebar-spacer"></div>
      <div class="titlebar-controls">
        <!-- 云同步 -->
        <div class="sync-btn-wrap">
          <button class="ctrl-btn sync-ctrl-btn" :class="{ active: showSyncPanel }" @click.stop="showSyncPanel = !showSyncPanel" title="云同步">
            <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <path d="M18 10h-1.26A8 8 0 1 0 9 20h9a5 5 0 0 0 0-10z"/>
            </svg>
            <span class="sync-dot" v-if="syncStatus === 'success'"></span>
            <span class="sync-dot error" v-if="syncStatus === 'error'"></span>
            <span class="sync-spin" v-if="syncStatus === 'syncing'">⟳</span>
          </button>
          <SyncPanel v-if="showSyncPanel" />
        </div>
        <!-- 主题切换 + 透明度（弹出面板） -->
        <div class="theme-btn-wrap">
          <button class="ctrl-btn" :class="{ active: showThemePicker }" @click.stop="showThemePicker = !showThemePicker" title="主题 / 透明度">
            <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <circle cx="12" cy="12" r="10"/><path d="M12 2a10 10 0 0 0 0 20"/><line x1="12" y1="2" x2="12" y2="22"/>
              <line x1="2" y1="12" x2="22" y2="12"/>
            </svg>
          </button>
          <transition name="color-pop">
            <div class="theme-picker-popup" v-if="showThemePicker" @click.stop>
              <div class="theme-grid">
                <button
                  v-for="t in themes"
                  :key="t.id"
                  class="theme-card"
                  :class="{ active: theme === t.id }"
                  @click="setTheme(t.id)"
                  :style="{ '--tc-bg': t.previewBg, '--tc-text': t.previewText, '--tc-accent': t.previewAccent }"
                >
                  <div class="theme-card-preview">
                    <span class="theme-card-label">Aa</span>
                  </div>
                  <span class="theme-card-name">{{ t.name }}</span>
                  <svg v-if="theme === t.id" class="theme-card-check" width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3">
                    <polyline points="20 6 9 17 4 12"/>
                  </svg>
                </button>
              </div>
              <!-- 透明度控制 -->
              <div class="theme-opacity-row">
                <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <circle cx="12" cy="12" r="9"/><path d="M12 3a9 9 0 0 1 0 18V3z"/>
                </svg>
                <input type="range" min="0.2" max="1" step="0.01" v-model.number="opacity" @input="applyOpacity" class="opacity-slider" />
                <span class="opacity-val">{{ Math.round(opacity * 100) }}%</span>
              </div>
            </div>
          </transition>
        </div>
        <!-- 置顶 -->
        <button class="ctrl-btn" :class="{ active: alwaysOnTop }" @click="toggleTop" title="窗口置顶">
          <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <circle cx="12" cy="5" r="3"/><line x1="12" y1="8" x2="12" y2="21"/>
            <polyline points="8 14 12 8 16 14"/>
          </svg>
        </button>
        <!-- 极简模式 -->
        <button class="ctrl-btn" :class="{ active: minimalMode }" @click="toggleMinimalMode" :title="minimalMode ? '经典模式' : '极简模式'">
          <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <rect x="3" y="3" width="18" height="18" rx="2"/>
            <line x1="3" y1="9" x2="21" y2="9"/>
          </svg>
        </button>
        <!-- 最小化 -->
        <button class="ctrl-btn" @click="minimize" title="最小化">
          <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <line x1="5" y1="12" x2="19" y2="12"/>
          </svg>
        </button>
        <!-- 最大化/还原 -->
        <button class="ctrl-btn" @click="toggleMaximize" title="最大化">
          <svg v-if="!isMaximized" width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <rect x="3" y="3" width="18" height="18" rx="2"/>
          </svg>
          <svg v-else width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <rect x="5" y="5" width="14" height="14" rx="2"/>
            <path d="M8 5V3h13v13h-2"/>
          </svg>
        </button>
        <!-- 关闭（收纳到托盘） -->
        <button class="ctrl-btn close-btn" @click="hideToTray" title="收纳到托盘">
          <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
            <line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/>
          </svg>
        </button>
      </div>
    </div>

    <!-- 透明度控制条（由弹出面板替代） -->
    <!-- 已移除旧的 opacity-bar -->

    <!-- Tab 切换 + 子 Tab（可隐藏） -->
    <div class="tab-bar" v-if="tabBarVisible && !minimalMode">
      <!-- 主 Tab：记事本 / 待办 -->
      <div class="main-tabs">
        <button class="main-tab" :class="{ active: activeTab === 'note' }" @click="activeTab = 'note'">
          <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/>
            <polyline points="14 2 14 8 20 8"/>
          </svg>
          记事本
        </button>
        <button class="main-tab" :class="{ active: activeTab === 'todo' }" @click="activeTab = 'todo'">
          <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <polyline points="9 11 12 14 22 4"/><path d="M21 12v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11"/>
          </svg>
          待办
          <span class="todo-badge" v-if="pendingCount > 0">{{ pendingCount }}</span>
        </button>
      </div>

      <!-- 分隔线 -->
      <div class="tab-divider"></div>

      <!-- 子 Tab：可点击标签 -->
      <div class="sub-tabs-bar" @contextmenu.prevent="openBarCtxMenu($event)">
        <div class="sub-tabs">
          <button
            v-for="item in currentSubTabs"
            :key="item.id"
            class="sub-tab"
            :class="{ active: activeSubTabId === item.id, locked: item.locked }"
            @click="switchSubTab(item.id)"
            @contextmenu.prevent.stop="openTabCtxMenu($event, item)"
            :style="{ '--tab-color': item.color || 'transparent' }"
          >
            <span class="sub-tab-name">
              <svg v-if="item.locked" class="lock-icon" width="9" height="9" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                <rect x="3" y="11" width="18" height="11" rx="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/>
              </svg>
              <span class="sub-tab-color-dot" v-if="item.color"></span>
              {{ item.name }}
            </span>
          </button>
        </div>
        <!-- 添加按钮 -->
        <button class="sub-add-btn" @click="addSubTab" title="新建">
          <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
            <line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/>
          </svg>
        </button>
      </div>

      <!-- 回收站按钮（tab 栏最右侧） -->
      <button class="trash-btn" @click.stop="toggleTrashPop($event)" title="回收站">
        <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <polyline points="3 6 5 6 21 6"/><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6"/><line x1="10" y1="11" x2="10" y2="17"/><line x1="14" y1="11" x2="14" y2="17"/>
        </svg>
      </button>

      <!-- 子 Tab 右键菜单 -->
      <transition name="ctx-menu">
        <div
          class="tab-ctx-menu"
          v-if="tabCtxMenu.visible"
          :style="{ left: tabCtxMenu.x + 'px', top: tabCtxMenu.y + 'px' }"
          @click.stop
        >
          <button class="ctx-menu-item" @click="renameTabCtx">
            <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/>
            </svg>
            重命名
          </button>
          <div class="ctx-menu-divider"></div>
          <div class="ctx-color-row">
            <span class="ctx-color-label">颜色</span>
            <div class="ctx-colors">
              <button
                v-for="c in tabColors"
                :key="c"
                class="ctx-color-btn"
                :class="{ active: (tabCtxMenu.item && tabCtxMenu.item.color === c) || (!tabCtxMenu.item?.color && c === '') }"
                :style="{ background: c || 'transparent', border: c ? '2px solid ' + c : '2px solid var(--border)' }"
                @click.stop="setTabColor(c)"
              >
                <svg v-if="tabCtxMenu.item?.color === c" width="8" height="8" viewBox="0 0 24 24" fill="none" stroke="#fff" stroke-width="3"><polyline points="20 6 9 17 4 12"/></svg>
                <svg v-else-if="!c && !tabCtxMenu.item?.color" width="8" height="8" viewBox="0 0 24 24" fill="none" stroke="var(--text-tertiary)" stroke-width="3"><polyline points="20 6 9 17 4 12"/></svg>
              </button>
            </div>
          </div>
          <div class="ctx-menu-divider"></div>
          <button class="ctx-menu-item" @click="toggleLockTab">
            <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <rect x="3" y="11" width="18" height="11" rx="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/>
            </svg>
            {{ tabCtxMenu.item?.locked ? '解锁标签页' : '锁定标签页' }}
          </button>
          <div class="ctx-menu-divider"></div>
          <!-- BUG3修复：删除移入二级确认，防止误删 -->
          <div v-if="!tabDeleteConfirm" class="ctx-menu-item danger-trigger" @click="tabDeleteConfirm = true" :class="{ disabled: tabCtxMenu.item?.locked || !canDeleteTab }">
            <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <polyline points="3 6 5 6 21 6"/><path d="M19 6v14a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2V6"/>
            </svg>
            删除标签页
          </div>
          <div v-else class="ctx-delete-confirm">
            <span class="ctx-confirm-tip">确认删除？</span>
            <div class="ctx-confirm-btns">
              <button class="ctx-confirm-cancel" @click="tabDeleteConfirm = false">取消</button>
              <button class="ctx-confirm-ok" @click="deleteTabCtx">删除</button>
            </div>
          </div>
        </div>
      </transition>

      <!-- 标签栏空位右键菜单 -->
      <transition name="ctx-menu">
        <div
          class="tab-ctx-menu"
          v-if="barCtxMenu.visible"
          :style="{ left: barCtxMenu.x + 'px', top: barCtxMenu.y + 'px' }"
          @click.stop
        >
          <button class="ctx-menu-item" @click="barCtxAdd">
            <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/>
            </svg>
            新建{{ activeTab === 'note' ? '记事本' : '待办页' }}
          </button>
        </div>
      </transition>
    </div>

    <!-- 回收站弹出（根级别，两种模式共用） -->
    <transition name="color-pop">
      <div class="trash-popup" v-if="showTrashPop" @click.stop :style="trashPopStyle">
          <div class="trash-popup-header">
            <span>回收站</span>
            <span class="trash-popup-sub">30天内可恢复</span>
          </div>
          <div class="trash-list" v-if="trashItems.length">
            <div v-for="(tr, idx) in trashItems" :key="tr.id + '-' + tr.deletedAt" class="trash-item">
              <div class="trash-item-info">
                <span>{{ tr.type === 'book' ? '📓' : tr.type === 'list' ? '📋' : tr.type === 'note' ? '📝' : '✅' }}</span>
                <span class="trash-item-name">{{ tr.name }}</span>
                <span class="trash-item-date">{{ formatDate(tr.deletedAt) }}</span>
              </div>
              <div class="trash-item-actions">
                <button class="trash-restore-btn" @click.stop="restoreTrash(idx)">恢复</button>
                <button class="trash-del-btn" @click.stop="deleteTrash(idx)">永久删除</button>
              </div>
            </div>
          </div>
          <div class="trash-empty" v-else>回收站是空的</div>
        </div>
      </transition>

    <!-- 标签栏隐藏时的紧凑工具栏 -->
    <div class="mini-tab-bar" v-if="!tabBarVisible && !minimalMode">
      <!-- 主模式切换 -->
      <button class="mini-mode-btn" :class="{ active: activeTab === 'note' }" @click="activeTab = 'note'" title="记事本">
        <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/>
        </svg>
      </button>
      <button class="mini-mode-btn" :class="{ active: activeTab === 'todo' }" @click="activeTab = 'todo'" title="待办">
        <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <polyline points="9 11 12 14 22 4"/><path d="M21 12v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11"/>
        </svg>
      </button>
      <!-- 分隔 -->
      <div class="mini-sep"></div>
      <!-- 子 Tab 下拉 -->
      <select class="mini-sub-select" @change="switchSubTab(Number($event.target.value))" :value="activeSubTabId">
        <option v-for="item in currentSubTabs" :key="item.id" :value="item.id">{{ item.name }}</option>
      </select>
      <!-- 新建 -->
      <button class="mini-icon-btn" @click="addSubTab" title="新建标签">
        <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
          <line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/>
        </svg>
      </button>
      <!-- 重命名 -->
      <button class="mini-icon-btn" @click="renameActiveTab" title="重命名当前标签">
        <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/>
        </svg>
      </button>
      <!-- 删除标签 -->
      <button class="mini-icon-btn mini-del-btn" @click="deleteActiveTab" title="删除当前标签">
        <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <polyline points="3 6 5 6 21 6"/><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6"/>
          <line x1="10" y1="11" x2="10" y2="17"/><line x1="14" y1="11" x2="14" y2="17"/>
        </svg>
      </button>
      <!-- 回收站 -->
      <button class="mini-icon-btn mini-trash-btn" @click.stop="toggleTrashPop($event)" title="回收站">
        <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <path d="M19 4l-2 16H7L5 4"/><line x1="10" y1="10" x2="10" y2="14"/><line x1="14" y1="10" x2="14" y2="14"/>
        </svg>
      </button>
    </div>

    <!-- 内容面板 -->
    <div class="content">
      <transition name="panel-fade" mode="out-in">
        <NotePanel v-if="activeTab === 'note'" key="note" ref="notePanelRef" />
        <TodoPanel v-else key="todo" ref="todoPanelRef" />
      </transition>
    </div>

    <!-- 自定义模态弹窗（替换原生 prompt/confirm） -->
    <transition name="modal-fade">
      <div class="modal-overlay" v-if="modal.show" @click.self="closeModal">
        <div class="modal-box" :class="'modal-' + modal.type">
          <div class="modal-header">
            <span class="modal-title">{{ modal.title }}</span>
          </div>
          <div class="modal-body">
            <p class="modal-message" v-if="modal.message">{{ modal.message }}</p>
            <input
              v-if="modal.type === 'prompt'"
              ref="modalInput"
              class="modal-input selectable"
              v-model="modal.inputValue"
              :placeholder="modal.placeholder"
              @keydown.enter="confirmModal"
              @keydown.escape="closeModal"
              maxlength="50"
            />
          </div>
          <div class="modal-footer">
            <button class="modal-btn modal-btn-cancel" @click="closeModal">取消</button>
            <button
              class="modal-btn modal-btn-confirm"
              :class="{ danger: modal.type === 'confirm' }"
              @click="confirmModal"
            >{{ modal.confirmText || '确定' }}</button>
          </div>
        </div>
      </div>
    </transition>


  </div>
</template>

<script setup>
import { ref, computed, onMounted, watch, nextTick } from 'vue'
import NotePanel from './components/NotePanel.vue'
import TodoPanel from './components/TodoPanel.vue'
import SyncPanel from './components/SyncPanel.vue'
import { syncState as syncStateRef } from './services/syncState.js'
import { initSyncState } from './services/syncState.js'

// 公共模块
import { readJSON, writeJSON } from './utils/storage.js'
import { addItemToTrash, ITEM_TRASH_KEY } from './utils/trash.js'
import { TAB_COLORS } from './utils/colors.js'
import { formatRelativeDate } from './utils/date.js'
import { generateId } from './utils/id.js'
import { useContextMenu } from './composables/useContextMenu.js'

// Tauri API — 统一使用 getCurrentWebviewWindow
import { getCurrentWebviewWindow } from '@tauri-apps/api/webviewWindow'
import { PhysicalPosition, PhysicalSize } from '@tauri-apps/api/dpi'
import { invoke } from '@tauri-apps/api/core'

const theme = ref('light')
const accent = ref('blue')
const activeTab = ref('note')
const alwaysOnTop = ref(false)
const isMaximized = ref(false)
const opacity = ref(1)
const showSyncPanel = ref(false)
const pendingCount = ref(0)
const isClosing = ref(false)
const tabBarVisible = ref(true)
const devMode = ref(localStorage.getItem('sn-dev-mode') === '1')
const minimalMode = ref(localStorage.getItem('sn-minimal-mode') === '1')

// 云同步状态
const syncStatus = computed(() => syncStateRef.status)


// 子组件 ref——直接调用方法，不走 CustomEvent，消灭竞态
const notePanelRef = ref(null)
const todoPanelRef = ref(null)

// 自定义模态弹窗
const modal = ref({
  show: false,
  type: 'prompt', // 'prompt' | 'confirm'
  title: '',
  message: '',
  inputValue: '',
  placeholder: '',
  confirmText: '确定',
  onConfirm: null,
  onCancel: null
})
const modalInput = ref(null)

function showModal(options) {
  modal.value = {
    show: true,
    type: options.type || 'prompt',
    title: options.title || '',
    message: options.message || '',
    inputValue: options.inputValue || '',
    placeholder: options.placeholder || '',
    confirmText: options.confirmText || '确定',
    onConfirm: options.onConfirm || null,
    onCancel: options.onCancel || null
  }
  if (options.type === 'prompt') {
    nextTick(() => {
      modalInput.value?.focus()
      modalInput.value?.select()
    })
  }
}

function closeModal() {
  if (modal.value.onCancel) modal.value.onCancel()
  modal.value.show = false
}

function confirmModal() {
  if (modal.value.onConfirm) modal.value.onConfirm(modal.value.inputValue)
  modal.value.show = false
}

// Tab 颜色（使用公共模块）
const tabColors = TAB_COLORS

// 回收站
const TRASH_KEY = 'sn-trash'
const showTrashPop = ref(false)
const trashPopStyle = ref({})
const trashItems = ref([])

function readTrash() {
  return readJSON(TRASH_KEY, [])
}

function saveTrash(items) {
  // 清理超过30天的记录
  const cutoff = Date.now() - 30 * 24 * 60 * 60 * 1000
  const filtered = items.filter(t => t.deletedAt > cutoff)
  writeJSON(TRASH_KEY, filtered)
}

function addToTrashLocal(item, type) {
  const trash = readTrash()
  trash.push({ id: item.id, name: item.name, type, deletedAt: Date.now(), data: JSON.parse(JSON.stringify(item)) })
  saveTrash(trash)
  refreshTrash()
}

function toggleTrashPop(e) {
  if (showTrashPop.value) {
    showTrashPop.value = false
    return
  }
  const btn = e.currentTarget
  const rect = btn.getBoundingClientRect()
  trashPopStyle.value = {
    top: (rect.bottom + 4) + 'px',
    right: (window.innerWidth - rect.right) + 'px'
  }
  showTrashPop.value = true
}

function refreshTrash() {
  const tabTrash = readTrash()
  // Also read item-level trash (notes, todos)
  const itemTrash = readJSON(ITEM_TRASH_KEY, [])
  // Merge and sort by deletedAt descending (newest first)
  trashItems.value = [...tabTrash, ...itemTrash.map(t => ({ ...t, _isItem: true }))]
    .sort((a, b) => (b.deletedAt || 0) - (a.deletedAt || 0))
}

function restoreTrash(idx) {
  const tr = trashItems.value[idx]
  if (!tr) return
  if (tr._isItem) {
    // Restore individual note/todo
    const itemTrash = readJSON(ITEM_TRASH_KEY, [])
    const realIdx = itemTrash.findIndex(t => t.id === tr.id && t.deletedAt === tr.deletedAt)
    if (realIdx < 0) return
    const restored = JSON.parse(JSON.stringify(tr.data))
    if (tr.type === 'note') {
      // Push to active notebook
      const notebooks = readJSON('sn-notebooks', [])
      const activeBookId = Number(localStorage.getItem('sn-active-book') || '0')
      const book = notebooks.find(b => b.id === activeBookId)
      if (book) {
        if (!book.notes) book.notes = []
        restored.id = Date.now()
        book.notes.unshift(restored)
        writeJSON('sn-notebooks', notebooks)
      }
    } else if (tr.type === 'todo') {
      const lists = readJSON('sn-todolists', [])
      const activeListId = Number(localStorage.getItem('sn-active-todolist') || '0')
      const list = lists.find(l => l.id === activeListId)
      if (list) {
        if (!list.todos) list.todos = []
        restored.id = Date.now()
        list.todos.unshift(restored)
        writeJSON('sn-todolists', lists)
      }
    }
    itemTrash.splice(realIdx, 1)
    writeJSON(ITEM_TRASH_KEY, itemTrash)
    refreshTrash()
    showTrashPop.value = false
    // Notify sub-components to reload
    if (tr.type === 'note') window.dispatchEvent(new CustomEvent('notebooks-updated'))
    else window.dispatchEvent(new CustomEvent('todolists-updated'))
    return
  }
  // Original tab trash restore
  // 关键修复：用 tr.type 判断恢复目标，而不是当前 activeTab
  const isBook = tr.type === 'book'
  const list = isBook ? notebookList.value : todolistList.value
  const storageKey = isBook ? NOTEBOOKS_KEY : TODOLISTS_KEY
  const restored = JSON.parse(tr.data)
  // Ensure no duplicate ids
  restored.id = Date.now() + Math.floor(Math.random() * 1000)
  if (restored.notes) restored.notes = []
  if (restored.todos) restored.todos = []
  list.push(restored)
  // 直接写入对应的 localStorage key，不走 saveTabData（它依赖 activeTab）
  const existing = readJSON(storageKey, [])
  existing.push({ ...restored })
  writeJSON(storageKey, existing)
  // Remove from trash
  const allTrash = readTrash()
  const trashIdx = allTrash.findIndex(t => t.id === tr.id && t.deletedAt === tr.deletedAt)
  if (trashIdx >= 0) allTrash.splice(trashIdx, 1)
  saveTrash(allTrash)
  refreshTrash()
  showTrashPop.value = false
  // 刷新侧栏列表
  refreshSubTabs()
  // 如果用户当前在对应的 tab 上，刷新子组件
  if (isBook && activeTab.value === 'note') {
    syncActiveSubTabId()
    setTimeout(() => { if (notePanelRef.value) notePanelRef.value.reload() }, 50)
  } else if (!isBook && activeTab.value !== 'note') {
    syncActiveSubTabId()
    setTimeout(() => { if (todoPanelRef.value) todoPanelRef.value.reload() }, 50)
  }
}

function deleteTrash(idx) {
  const tr = trashItems.value[idx]
  if (!tr) return
  if (tr._isItem) {
    const itemTrash = readJSON(ITEM_TRASH_KEY, [])
    const realIdx = itemTrash.findIndex(t => t.id === tr.id && t.deletedAt === tr.deletedAt)
    if (realIdx >= 0) itemTrash.splice(realIdx, 1)
    writeJSON(ITEM_TRASH_KEY, itemTrash)
    refreshTrash()
    return
  }
  const allTrash = readTrash()
  if (allTrash[idx]) allTrash.splice(idx, 1)
  saveTrash(allTrash)
  refreshTrash()
}

// formatDate 使用公共模块的 formatRelativeDate
const formatDate = formatRelativeDate

// Tab 右键菜单（使用公共模块 useContextMenu）
const { menu: tabCtxMenu, open: openTabCtxMenuRaw, close: closeTabCtxMenuRaw } = useContextMenu(120, 80)
const tabDeleteConfirm = ref(false)

// 标签栏空位右键菜单
const { menu: barCtxMenu, open: openBarCtxMenuRaw, close: closeBarCtxMenu } = useContextMenu(140, 40)

// 响应式子 Tab 数据
const notebookList = ref([])
const todolistList = ref([])

// 从 localStorage 读取子 tab 数据
const NOTEBOOKS_KEY = 'sn-notebooks'
const TODOLISTS_KEY = 'sn-todolists'

function readNotebooks() {
  return readJSON(NOTEBOOKS_KEY, [])
}
function readTodoLists() {
  return readJSON(TODOLISTS_KEY, [])
}

function refreshSubTabs() {
  notebookList.value = readNotebooks()
  todolistList.value = readTodoLists()
}

const currentSubTabs = computed(() => {
  if (activeTab.value === 'note') return notebookList.value
  return todolistList.value
})

// FIX: activeSubTabId 必须是 ref 才能响应点击更新
const activeSubTabId = ref(0)

function syncActiveSubTabId() {
  if (activeTab.value === 'note') {
    const saved = localStorage.getItem('sn-active-book')
    activeSubTabId.value = saved ? Number(saved) : (notebookList.value[0]?.id || 0)
  } else {
    const saved = localStorage.getItem('sn-active-todolist')
    activeSubTabId.value = saved ? Number(saved) : (todolistList.value[0]?.id || 0)
  }
}

function switchSubTab(id) {
  activeSubTabId.value = id
  if (activeTab.value === 'note') {
    localStorage.setItem('sn-active-book', id)
    if (notePanelRef.value) notePanelRef.value.switchToBook(id)
  } else {
    localStorage.setItem('sn-active-todolist', id)
    if (todoPanelRef.value) todoPanelRef.value.switchToList(id)
  }
}

function addSubTab() {
  if (activeTab.value === 'note') {
    if (notePanelRef.value) notePanelRef.value.addNotebook()
  } else {
    if (todoPanelRef.value) todoPanelRef.value.addTodoList()
  }
  // 延迟刷新子 Tab，等子组件写入 localStorage
  setTimeout(() => {
    refreshSubTabs()
  }, 50)
}

// Tab 右键菜单
function openTabCtxMenu(e, item) {
  closeBarCtxMenu()
  openTabCtxMenuRaw(e, { item })
}

function closeTabCtxMenu() {
  closeTabCtxMenuRaw()
  tabDeleteConfirm.value = false
}

// 标签栏空位右键菜单
function openBarCtxMenu(e) {
  closeTabCtxMenu()
  openBarCtxMenuRaw(e)
}

function barCtxAdd() {
  closeBarCtxMenu()
  addSubTab()
}

const canDeleteTab = computed(() => {
  return currentSubTabs.value.length > 1
})

function renameTabCtx() {
  const item = tabCtxMenu.value.item
  closeTabCtxMenu()
  if (!item) return
  const realItem = getRealTabItem(item)
  if (!realItem) return
  const newName = prompt('重命名标签页：', realItem.name)
  if (newName && newName.trim()) {
    realItem.name = newName.trim()
    saveTabData()
    refreshSubTabs()
  }
}

// 重命名当前激活的 Tab（自定义弹窗）
function renameActiveTab() {
  const list = activeTab.value === 'note' ? notebookList.value : todolistList.value
  const activeId = Number(localStorage.getItem(activeTab.value === 'note' ? 'sn-active-book' : 'sn-active-todolist'))
  const item = list.find(t => t.id === activeId)
  if (!item) return
  showModal({
    type: 'prompt',
    title: '重命名标签页',
    placeholder: '输入新名称...',
    inputValue: item.name,
    confirmText: '保存',
    onConfirm: (val) => {
      if (val && val.trim()) {
        item.name = val.trim()
        saveTabData()
        refreshSubTabs()
      }
    }
  })
}

// 删除当前激活的 Tab（迷你模式专用，自定义确认弹窗）
function deleteActiveTab() {
  const list = activeTab.value === 'note' ? notebookList.value : todolistList.value
  const activeId = Number(localStorage.getItem(activeTab.value === 'note' ? 'sn-active-book' : 'sn-active-todolist'))
  const item = list.find(t => t.id === activeId)
  if (!item || item.locked) return
  if (list.length <= 1) return
  const name = item.name || '未命名'
  showModal({
    type: 'confirm',
    title: '删除标签页',
    message: `确定要删除「${name}」吗？`,
    confirmText: '删除',
    onConfirm: () => {
      addToTrashLocal(item, activeTab.value === 'note' ? 'book' : 'list')
      if (activeTab.value === 'note') {
        if (notePanelRef.value) notePanelRef.value.deleteNotebook(item.id)
      } else {
        if (todoPanelRef.value) todoPanelRef.value.deleteTodoList(item.id)
      }
      setTimeout(() => refreshSubTabs(), 50)
    }
  })
}

function deleteTabCtx() {
  const item = tabCtxMenu.value.item
  closeTabCtxMenu()
  if (!item || item.locked) return
  // 移入回收站而非直接删除
  addToTrashLocal(item, activeTab.value === 'note' ? 'book' : 'list')
  if (activeTab.value === 'note') {
    if (notePanelRef.value) notePanelRef.value.deleteNotebook(item.id)
  } else {
    if (todoPanelRef.value) todoPanelRef.value.deleteTodoList(item.id)
  }
}

// BUG7修复：通过id找到列表中真实对象，避免引用断裂导致错误覆盖
function getRealTabItem(item) {
  if (!item) return null
  const list = activeTab.value === 'note' ? notebookList.value : todolistList.value
  return list.find(t => t.id === item.id) || null
}

// Tab 锁定
function toggleLockTab() {
  const item = getRealTabItem(tabCtxMenu.value.item)
  if (!item) return
  item.locked = !item.locked
  saveTabData()
  closeTabCtxMenu()
}

// Tab 颜色
function setTabColor(color) {
  const item = getRealTabItem(tabCtxMenu.value.item)
  if (!item) return
  item.color = color || undefined
  saveTabData()
  // BUG1修复：颜色选择后关闭菜单，再次右键时重新打开可以继续切换
  closeTabCtxMenu()
}

// BUG3/BUG4 根因修复：saveTabData 必须合并现有完整数据，不能覆盖 NotePanel/TodoPanel 的 notes/todos
function saveTabData() {
  const key = activeTab.value === 'note' ? NOTEBOOKS_KEY : TODOLISTS_KEY
  const eventName = activeTab.value === 'note' ? 'notebooks-updated' : 'todolists-updated'
  
  // 读取 localStorage 中已有的完整数据（包含 notes/todos）
  const existing = readJSON(key, [])
  
  const tabList = activeTab.value === 'note' ? notebookList.value : todolistList.value
  
  // 合并：只更新 tab 元数据（name, color, locked），保留 notes/todos 等子数据
  tabList.forEach(tab => {
    const match = existing.find(d => d.id === tab.id)
    if (match) {
      match.name = tab.name
      match.color = tab.color
      match.locked = tab.locked
    } else {
      // 新创建的 tab，追加到列表
      existing.push({ ...tab })
    }
  })
  
  // 移除已在 tab 列表中不存在的项（被删除的）
  const tabIds = new Set(tabList.map(t => t.id))
  const filtered = existing.filter(d => tabIds.has(d.id))
  
  writeJSON(key, filtered)
}

// 主题切换
const showThemePicker = ref(false)
const themes = [
  { id: 'light', name: '明亮', desc: '干净白纸', previewBg: '#ffffff', previewText: '#1a1a1a', previewAccent: '#5b5ef4' },
  { id: 'dark', name: '暗黑', desc: '深夜模式', previewBg: '#24242a', previewText: '#f0f0f2', previewAccent: '#7c7ff5' },
  { id: 'sepia', name: '暖纸', desc: '米黄纸张', previewBg: '#f5eedd', previewText: '#4a3728', previewAccent: '#8b6914' },
  { id: 'mint', name: '薄荷', desc: '清爽护眼', previewBg: '#ebf7f1', previewText: '#1a3a2e', previewAccent: '#0d9488' },
  { id: 'sakura', name: '樱花', desc: '温柔不刺眼', previewBg: '#faecee', previewText: '#3d1a28', previewAccent: '#c7446a' },
  { id: 'haze', name: '雾蓝', desc: '晨雾轻柔', previewBg: '#edf0f5', previewText: '#2c3345', previewAccent: '#6b7db3' },
  { id: 'latte', name: '奶咖', desc: '奶泡柔和', previewBg: '#f5efe8', previewText: '#4a3528', previewAccent: '#b8845c' },
  { id: 'espresso', name: '暖咖', desc: '咖啡馆氛围', previewBg: '#2e231c', previewText: '#eeddcc', previewAccent: '#d4a574' },
]

function setTheme(name) {
  theme.value = name
  localStorage.setItem('sn-theme', name)
  showThemePicker.value = false
  // 透明度100%时覆盖背景色
  if (opacity.value >= 1) {
    nextTick(() => applyOpacity())
  }
}

// 窗口控制
async function toggleTop() {
  try {
    alwaysOnTop.value = !alwaysOnTop.value
    const win = getCurrentWebviewWindow()
    await win.setAlwaysOnTop(alwaysOnTop.value)
    // 置顶时隐藏任务栏图标，取消置顶时恢复
    await invoke('set_skip_taskbar', { skip: alwaysOnTop.value })
  } catch (e) {
    console.warn('toggleTop failed:', e)
    alwaysOnTop.value = !alwaysOnTop.value
  }
}

async function minimize() {
  try {
    const win = getCurrentWebviewWindow()
    await win.minimize()
  } catch (e) {
    console.warn('minimize failed:', e)
  }
}

async function hideToTray() {
  if (isClosing.value) return
  isClosing.value = true
  
  // 关闭前保存窗口状态
  await saveWindowState()
  
  // 先播放缩小动画（450ms）
  await new Promise(r => setTimeout(r, 500))
  
  try {
    const win = getCurrentWebviewWindow()
    await win.hide()
  } catch (e) {
    console.warn('hideToTray failed:', e)
  }

  // 恢复状态（下次打开时重置）
  await new Promise(r => setTimeout(r, 100))
  isClosing.value = false
}

async function toggleMaximize() {
  try {
    const win = getCurrentWebviewWindow()
    const max = await win.isMaximized()
    if (max) {
      await win.unmaximize()
      isMaximized.value = false
    } else {
      await win.maximize()
      isMaximized.value = true
    }
    // 最大化/还原后延迟保存（等窗口动画完成）
    setTimeout(() => saveWindowState(), 300)
  } catch (e) {
    console.warn('toggleMaximize failed:', e)
    isMaximized.value = !isMaximized.value
  }
}

async function applyOpacity() {
  // Tauri v2 没有 JS setOpacity API，通过 CSS 控制透明度
  // 窗口已设置 transparent:true，CSS opacity 直接生效
  const appShell = document.querySelector('.app-shell')
  if (appShell) {
    appShell.style.opacity = opacity.value
  }
  // BUG6修复：透明度100%时覆盖背景色的透明通道，实现完全不透明
  if (opacity.value >= 1) {
    const darkThemes = ['dark', 'espresso']
    const isDark = darkThemes.includes(theme.value)
    const bgColors = {
      light: 'rgb(255, 255, 255)',
      dark: 'rgb(28, 28, 32)',
      sepia: 'rgb(250, 245, 235)',
      mint: 'rgb(240, 250, 246)',
      sakura: 'rgb(253, 243, 246)',
      haze: 'rgb(242, 244, 248)',
      latte: 'rgb(250, 246, 242)',
      espresso: 'rgb(38, 28, 22)',
    }
    if (appShell) appShell.style.background = bgColors[theme.value] || (isDark ? 'rgb(28, 28, 32)' : 'rgb(255, 255, 255)')
  } else {
    // 有透明度时，移除内联背景覆盖，恢复 CSS 变量
    if (appShell) appShell.style.background = ''
  }
  localStorage.setItem('sn-opacity', opacity.value)
}

function toggleCompact() {
  // 双击标题栏预留
}

// 极简模式切换
function toggleMinimalMode() {
  minimalMode.value = !minimalMode.value
  localStorage.setItem('sn-minimal-mode', minimalMode.value ? '1' : '0')
  // 极简模式 = 隐藏标题栏，关闭极简模式 = 显示标题栏
  tabBarVisible.value = !minimalMode.value
  localStorage.setItem('sn-tabbar-visible', tabBarVisible.value ? '1' : '0')
  // 通知 NotePanel 极简模式状态
  window.dispatchEvent(new CustomEvent('minimal-mode-change', { detail: minimalMode.value }))
}

function updatePendingCount(n) {
  pendingCount.value = n
}

// 窗口位置/大小持久化
const WIN_STATE_KEY = 'sn-window-state'
let winStateSaveTimer = null

async function saveWindowState() {
  try {
    const win = getCurrentWebviewWindow()
    // 最大化时不保存（尺寸无意义）
    if (await win.isMaximized()) return
    // 最小化时不保存（位置可能为负）
    if (await win.isMinimized()) return
    const [pos, size] = await Promise.all([win.outerPosition(), win.outerSize()])
    const state = { x: pos.x, y: pos.y, width: size.width, height: size.height }
    writeJSON(WIN_STATE_KEY, state)
  } catch {}
}

function debouncedSaveWindowState() {
  if (winStateSaveTimer) clearTimeout(winStateSaveTimer)
  winStateSaveTimer = setTimeout(saveWindowState, 400)
}

async function restoreWindowState() {
  try {
    const state = readJSON(WIN_STATE_KEY, null)
    if (!state || !state.width || !state.height) return
    const win = getCurrentWebviewWindow()
    // 先设位置，再设尺寸
    if (typeof state.x === 'number' && typeof state.y === 'number' && state.x > -1000 && state.y > -1000) {
      await win.setPosition(new PhysicalPosition(state.x, state.y))
    }
    await win.setSize(new PhysicalSize(state.width, state.height))
  } catch {
    // 恢复失败就用默认值
  }
}

onMounted(async () => {
  const savedTheme = localStorage.getItem('sn-theme')
  if (savedTheme) theme.value = savedTheme

  const savedAccent = localStorage.getItem('sn-accent')
  if (savedAccent) accent.value = savedAccent

  const savedOpacity = localStorage.getItem('sn-opacity')
  if (savedOpacity) {
    opacity.value = parseFloat(savedOpacity)
    await applyOpacity()
  }

  // 恢复窗口位置和大小
  await restoreWindowState()

  // 窗口移动/缩放时保存状态
  const appWin = getCurrentWebviewWindow()
  appWin.onResized(() => debouncedSaveWindowState())
  appWin.onMoved(() => debouncedSaveWindowState())

  const savedTabBar = localStorage.getItem('sn-tabbar-visible')
  if (savedTabBar !== null) tabBarVisible.value = savedTabBar !== '0'

  // 持久化标签栏显隐状态
  watch(tabBarVisible, (val) => {
    localStorage.setItem('sn-tabbar-visible', val ? '1' : '0')
  })

  // FIX: 监听主 Tab 切换和列表变化，同步 activeSubTabId
  watch(activeTab, syncActiveSubTabId)
  watch(notebookList, syncActiveSubTabId, { deep: true })
  watch(todolistList, syncActiveSubTabId, { deep: true })

  // 初始化子 Tab 列表
  refreshSubTabs()
  syncActiveSubTabId()

  // 初始化回收站
  refreshTrash()

  // 监听待办数量更新
  window.addEventListener('todo-pending-update', (e) => {
    pendingCount.value = e.detail
  })

  // 监听子组件数据更新，刷新子 Tab
  window.addEventListener('notebooks-updated', () => { refreshSubTabs(); syncActiveSubTabId() })
  window.addEventListener('todolists-updated', () => { refreshSubTabs(); syncActiveSubTabId() })

  // 初始分发极简模式状态
  if (minimalMode.value) {
    window.dispatchEvent(new CustomEvent('minimal-mode-change', { detail: true }))
  }

  // 初始化云同步状态
  await initSyncState()

  // 监听云同步数据恢复事件，刷新子组件
  window.addEventListener('sync-data-applied', () => {
    // 重新加载主题/设置
    const savedTheme = localStorage.getItem('sn-theme')
    if (savedTheme) theme.value = savedTheme
    const savedAccent = localStorage.getItem('sn-accent')
    if (savedAccent) accent.value = savedAccent
    const savedOp = localStorage.getItem('sn-opacity')
    if (savedOp) { opacity.value = parseFloat(savedOp); applyOpacity() }
    // 刷新侧栏列表
    refreshSubTabs()
    syncActiveSubTabId()
    // 通知子面板重新加载数据
    if (notePanelRef.value) notePanelRef.value.reload()
    if (todoPanelRef.value) todoPanelRef.value.reload()
  })

  // 点击外部关闭弹出面板
  document.addEventListener('click', (e) => {
    closeTabCtxMenu()
    closeBarCtxMenu()
    if (showThemePicker.value) {
      const wrap = document.querySelector('.theme-btn-wrap')
      if (wrap && !wrap.contains(e.target)) {
        showThemePicker.value = false
      }
    }
    if (showSyncPanel.value) {
      const wrap = document.querySelector('.sync-btn-wrap')
      if (wrap && !wrap.contains(e.target)) {
        showSyncPanel.value = false
      }
    }
    if (showTrashPop.value) {
      const pop = document.querySelector('.trash-popup')
      if (pop && !pop.contains(e.target)) {
        showTrashPop.value = false
      }
    }
  })
})
</script>

<style scoped>
.app-shell {
  display: flex;
  flex-direction: column;
  height: 100vh;
  background: var(--bg-app);
  border-radius: var(--radius);
  overflow: hidden;
  box-shadow: var(--shadow-app), 0 0 0 0.5px var(--border);
  border: none;
  backdrop-filter: blur(20px) saturate(180%);
  -webkit-backdrop-filter: blur(20px) saturate(180%);
  transition: background var(--transition), box-shadow var(--transition);
}

/* 关闭 → 托盘缩小动画 */
.app-shell.closing {
  animation: shrinkToTray 0.45s cubic-bezier(0.4, 0, 0.2, 1) forwards;
  pointer-events: none;
}

@keyframes shrinkToTray {
  0%   { transform: scale(1) translate(0, 0); opacity: 1; }
  50%  { transform: scale(0.5) translate(60%, 40%); opacity: 0.5; }
  100% { transform: scale(0.1) translate(300%, 200%); opacity: 0; }
}


.titlebar {
  display: flex;
  align-items: center;
  height: 36px;
  padding: 0 10px;
  flex-shrink: 0;
  -webkit-app-region: drag;
  background: var(--bg-surface);
  border-bottom: 0.5px solid var(--border);
  container-type: inline-size;
  container-name: titlebar;
}

.titlebar-spacer {
  flex: 1;
  height: 100%;
  -webkit-app-region: drag;
}

.titlebar-brand {
  display: flex;
  align-items: center;
  gap: 5px;
  height: 100%;
  padding-left: 8px;
  -webkit-app-region: drag;
  flex-shrink: 1;
  min-width: 0;
  overflow: hidden;
}

.brand-icon {
  flex-shrink: 0;
  display: block;
}

.brand-name {
  font-size: 12px;
  font-weight: 600;
  color: var(--text-primary);
  letter-spacing: 0.03em;
}

.brand-en {
  font-size: 10px;
  font-weight: 400;
  color: var(--text-tertiary);
  letter-spacing: 0.04em;
  transition: opacity var(--transition), max-width var(--transition);
}

.brand-ver {
  font-size: 9px;
  font-weight: 400;
  color: var(--text-tertiary);
  opacity: 0.6;
  margin-left: 2px;
  transition: opacity var(--transition), max-width var(--transition);
}

.titlebar-controls {
  display: flex;
  gap: 2px;
  -webkit-app-region: no-drag;
  flex-shrink: 0;
}

/* 极简模式标题栏切换按钮 */
.titlebar-tab-switch {
  display: flex;
  gap: 2px;
  -webkit-app-region: no-drag;
}

.titlebar-tab-btn {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 4px;
  padding: 4px 6px;
  border: none;
  background: transparent;
  border-radius: 5px;
  font-size: 11px;
  font-weight: 500;
  color: var(--text-tertiary);
  cursor: pointer;
  font-family: var(--font);
  white-space: nowrap;
  transition: all var(--transition);
  flex-shrink: 0;
  min-width: 0;
}

.titlebar-tab-btn:hover {
  background: var(--bg-hover);
  color: var(--text-primary);
}

.titlebar-tab-btn.active {
  background: var(--accent-light);
  color: var(--accent-text);
  font-weight: 600;
}

/* 极简模式下隐藏品牌副文本，节省空间 */
.app-shell.minimal-mode .brand-en,
.app-shell.minimal-mode .brand-ver {
  display: none;
}

/* 极简模式标题栏左侧切换按钮 */
.app-shell.minimal-mode .titlebar-tab-switch {
  padding-left: 8px;
  -webkit-app-region: no-drag;
}

/* 经典模式下窗口缩窄时渐进式隐藏品牌元素（保留图标和中文名） */
@container titlebar (max-width: 380px) {
  .titlebar-brand .brand-ver { opacity: 0; max-width: 0; overflow: hidden; margin: 0; padding: 0; }
}
@container titlebar (max-width: 330px) {
  .titlebar-brand .brand-en { opacity: 0; max-width: 0; overflow: hidden; margin: 0; padding: 0; }
}

.ctrl-btn {
  width: 28px;
  height: 28px;
  border: none;
  background: transparent;
  border-radius: 7px;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  color: var(--text-secondary);
  transition: all var(--transition);
  position: relative;
  overflow: hidden;
}

.ctrl-btn:hover {
  background: var(--bg-hover);
  color: var(--text-primary);
  box-shadow: var(--shadow-sm);
}

.ctrl-btn.active {
  color: var(--accent);
  background: var(--accent-light);
  box-shadow: var(--shadow-glow);
}

.ctrl-btn.close-btn:hover {
  background: var(--danger-light);
  color: var(--danger);
  box-shadow: 0 2px 8px rgba(232, 69, 60, 0.2);
}

/* 透明度弹出面板 */
.sync-btn-wrap {
  position: relative;
  display: flex;
  align-items: center;
}
.sync-ctrl-btn {
  position: relative;
}
.sync-dot {
  position: absolute;
  top: 1px;
  right: 1px;
  width: 6px;
  height: 6px;
  border-radius: 50%;
  background: #22c55e;
}
.sync-dot.error {
  background: #e8453c;
}
.sync-spin {
  position: absolute;
  top: -1px;
  right: -1px;
  font-size: 10px;
  animation: spin 0.8s linear infinite;
}
@keyframes spin {
  from { transform: rotate(0deg); }
  to   { transform: rotate(360deg); }
}

.opacity-btn-wrap {
  position: relative;
  display: flex;
  align-items: center;
}

.opacity-popup {
  position: absolute;
  top: calc(100% + 6px);
  left: 0;
  z-index: 200;
  background: var(--bg-surface);
  border: 0.5px solid var(--border);
  border-radius: 10px;
  padding: 8px 12px;
  display: flex;
  align-items: center;
  gap: 8px;
  box-shadow: 0 8px 28px rgba(0,0,0,0.18);
  min-width: 140px;
  animation: fadeIn 0.12s ease;
}

.opacity-pop-label {
  font-size: 11px;
  color: var(--text-secondary);
  font-weight: 500;
  white-space: nowrap;
}

.opacity-popup .opacity-slider {
  flex: 1;
  height: 3px;
  -webkit-appearance: none;
  appearance: none;
  background: var(--border-strong);
  border-radius: 2px;
  outline: none;
  cursor: pointer;
}

.opacity-popup .opacity-slider::-webkit-slider-thumb {
  -webkit-appearance: none;
  width: 14px;
  height: 14px;
  background: var(--accent);
  border-radius: 50%;
  cursor: pointer;
  box-shadow: 0 1px 4px rgba(0,0,0,0.2);
  transition: transform var(--transition-fast);
}

.opacity-popup .opacity-slider::-webkit-slider-thumb:hover {
  transform: scale(1.2);
}

.opacity-popup .opacity-val {
  font-size: 11px;
  color: var(--text-tertiary);
  width: 32px;
  text-align: right;
  flex-shrink: 0;
}

/* ========== Tab Bar ========== */
.tab-bar {
  display: flex;
  align-items: center;
  padding: 0 10px;
  border-bottom: 0.5px solid var(--border);
  flex-shrink: 0;
  background: var(--bg-surface);
  position: relative;
  gap: 0;
  height: 38px;
  transition: background var(--transition);
}

.main-tabs {
  display: flex;
  gap: 2px;
  flex-shrink: 0;
}

.main-tab {
  display: flex;
  align-items: center;
  gap: 5px;
  padding: 6px 14px;
  border: none;
  background: transparent;
  border-radius: var(--radius-sm);
  font-size: 12px;
  font-weight: 600;
  color: var(--text-secondary);
  cursor: pointer;
  transition: all var(--transition);
  position: relative;
  font-family: var(--font);
  white-space: nowrap;
}

.main-tab::after {
  content: '';
  position: absolute;
  bottom: -1px;
  left: 50%;
  width: 0;
  height: 2px;
  background: var(--accent);
  border-radius: 2px;
  transition: all 0.25s cubic-bezier(0.16, 1, 0.3, 1);
  transform: translateX(-50%);
}

.main-tab:hover {
  background: var(--bg-hover);
  color: var(--text-primary);
}

.main-tab.active {
  background: var(--accent-light);
  color: var(--accent-text);
}

.main-tab.active::after {
  width: 70%;
}

.todo-badge {
  background: var(--accent);
  color: #fff;
  font-size: 10px;
  font-weight: 600;
  border-radius: 10px;
  padding: 0 5px;
  min-width: 16px;
  text-align: center;
  line-height: 15px;
  box-shadow: 0 1px 4px var(--accent-glow);
  animation: pulseGlow 2s ease-in-out infinite;
}

.tab-divider {
  width: 1px;
  height: 18px;
  background: var(--border);
  margin: 0 6px;
  flex-shrink: 0;
}

.sub-tabs {
  display: flex;
  flex: 1;
  gap: 2px;
  overflow-x: auto;
  min-width: 0;
}

/* 隐藏 sub-tabs 滚动条 */
.sub-tabs::-webkit-scrollbar { height: 0; }

/* ========== 子 Tab 标签栏 ========== */
.sub-tabs-bar {
  display: flex;
  flex: 1;
  align-items: center;
  gap: 2px;
  min-width: 0;
}

.sub-tabs {
  display: flex;
  flex: 1;
  gap: 2px;
  overflow-x: auto;
  min-width: 0;
}

/* 隐藏 sub-tabs 滚动条 */
.sub-tabs::-webkit-scrollbar { height: 0; }

.sub-tab {
  display: flex;
  align-items: center;
  padding: 5px 12px;
  border: none;
  background: transparent;
  border-radius: var(--radius-sm);
  font-size: 11px;
  font-weight: 500;
  color: var(--text-tertiary);
  cursor: pointer;
  transition: all var(--transition);
  font-family: var(--font);
  white-space: nowrap;
  flex-shrink: 0;
  position: relative;
}

.sub-tab:hover {
  background: var(--bg-hover);
  color: var(--text-primary);
}

.sub-tab.active {
  background: var(--bg-active);
  color: var(--text-primary);
  font-weight: 600;
  box-shadow: inset 0 -2px 0 var(--accent);
}

.sub-tab.locked {
  opacity: 0.85;
}

.sub-tab-name {
  overflow: hidden;
  text-overflow: ellipsis;
  max-width: 72px;
  display: flex;
  align-items: center;
  gap: 4px;
}

.lock-icon {
  flex-shrink: 0;
  opacity: 0.7;
}

.sub-tab-color-dot {
  width: 7px;
  height: 7px;
  border-radius: 50%;
  background: var(--tab-color);
  flex-shrink: 0;
  box-shadow: 0 0 0 1px rgba(255,255,255,0.3);
}

.sub-add-btn {
  width: 24px;
  height: 24px;
  border: none;
  background: transparent;
  border-radius: 5px;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  color: var(--text-tertiary);
  transition: all var(--transition);
  flex-shrink: 0;
}

.sub-add-btn:hover {
  background: var(--accent-light);
  color: var(--accent);
}

/* ========== 紧凑 Tab 栏（tab-bar 隐藏时） ========== */
.mini-tab-bar {
  display: flex;
  align-items: center;
  padding: 0 8px;
  height: 30px;
  border-bottom: 0.5px solid var(--border);
  flex-shrink: 0;
  background: var(--bg-surface);
  gap: 4px;
  -webkit-app-region: no-drag;
}

.mini-mode-btn {
  display: flex;
  align-items: center;
  gap: 3px;
  padding: 2px 8px;
  border: none;
  background: transparent;
  border-radius: 4px;
  font-size: 11px;
  font-weight: 500;
  color: var(--text-secondary);
  cursor: pointer;
  font-family: var(--font);
  white-space: nowrap;
  transition: all var(--transition);
}

.mini-mode-btn:hover { background: var(--bg-hover); color: var(--text-primary); }
.mini-mode-btn.active { background: var(--accent-light); color: var(--accent-text); }

.mini-sep {
  width: 1px;
  height: 16px;
  background: var(--border);
  flex-shrink: 0;
}

.mini-sub-select {
  flex: 1;
  min-width: 0;
  height: 24px;
  border: 0.5px solid var(--border);
  border-radius: 5px;
  background: var(--bg-input);
  color: var(--text-primary);
  font-size: 11px;
  font-family: var(--font);
  padding: 0 4px;
  cursor: pointer;
  outline: none;
  -webkit-appearance: none;
  appearance: none;
  transition: border-color var(--transition);
}

.mini-sub-select:hover { border-color: var(--accent); }
.mini-sub-select:focus { border-color: var(--accent); box-shadow: 0 0 0 1.5px var(--accent-light); }

/* 迷你模式通用图标按钮 */
.mini-icon-btn {
  width: 22px;
  height: 22px;
  border: none;
  background: transparent;
  border-radius: 5px;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  color: var(--text-tertiary);
  transition: all var(--transition);
  flex-shrink: 0;
  padding: 0;
}

.mini-icon-btn:hover {
  background: var(--bg-hover);
  color: var(--text-primary);
}

.mini-del-btn:hover {
  background: var(--danger-light);
  color: var(--danger);
}

.mini-trash-btn:hover {
  background: var(--danger-light);
  color: var(--danger);
}

/* 回收站按钮：tab 栏最右侧 */
.trash-btn {
  width: 28px;
  height: 28px;
  border: none;
  background: transparent;
  border-radius: var(--radius-xs);
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  color: var(--text-tertiary);
  transition: all var(--transition);
  flex-shrink: 0;
  margin-left: 6px;
}
.trash-btn:hover {
  background: var(--danger-light);
  color: var(--danger);
}

/* 回收站弹出 */
.trash-popup {
  position: fixed;
  z-index: 200;
  background: var(--bg-surface);
  border: 0.5px solid var(--border);
  border-radius: 10px;
  padding: 8px;
  box-shadow: 0 8px 28px rgba(0,0,0,0.18);
  min-width: 240px;
  max-height: 240px;
  overflow-y: auto;
  animation: fadeIn 0.12s ease;
}

.trash-popup-header {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 0 4px 6px;
  font-size: 12px;
  font-weight: 600;
  color: var(--text-primary);
  border-bottom: 0.5px solid var(--border);
}

.trash-popup-sub {
  font-size: 10px;
  font-weight: 400;
  color: var(--text-tertiary);
}

.trash-list {
  display: flex;
  flex-direction: column;
  gap: 3px;
  padding-top: 4px;
}

.trash-item {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 6px 4px;
  border-radius: 6px;
  transition: background var(--transition);
  gap: 8px;
}

.trash-item:hover { background: var(--bg-hover); }

.trash-item-info {
  display: flex;
  align-items: center;
  gap: 5px;
  font-size: 11px;
  color: var(--text-primary);
  min-width: 0;
  flex: 1;
}

.trash-item-name {
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  max-width: 80px;
}

.trash-item-date {
  font-size: 10px;
  color: var(--text-tertiary);
  flex-shrink: 0;
}

.trash-item-actions {
  display: flex;
  gap: 3px;
  flex-shrink: 0;
}

.trash-restore-btn, .trash-del-btn {
  font-size: 10px;
  padding: 2px 8px;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  font-family: var(--font);
  transition: all var(--transition);
}

.trash-restore-btn {
  background: var(--accent-light);
  color: var(--accent-text);
}

.trash-restore-btn:hover { opacity: 0.8; }

.trash-del-btn {
  background: transparent;
  color: var(--text-tertiary);
}

.trash-del-btn:hover { background: var(--danger-light); color: var(--danger); }

.trash-empty {
  padding: 16px 0;
  text-align: center;
  font-size: 12px;
  color: var(--text-tertiary);
}

/* Tab 右键菜单 */
.tab-ctx-menu {
  position: fixed;
  z-index: 500;
  background: var(--bg-surface);
  border: 0.5px solid var(--border);
  border-radius: 8px;
  padding: 4px;
  box-shadow: 0 6px 24px rgba(0,0,0,0.2);
  min-width: 110px;
  animation: fadeIn 0.1s ease;
}

.ctx-menu-item {
  display: flex;
  align-items: center;
  gap: 8px;
  width: 100%;
  padding: 6px 10px;
  border: none;
  background: transparent;
  border-radius: 5px;
  cursor: pointer;
  font-size: 12px;
  color: var(--text-primary);
  font-family: var(--font);
  transition: background var(--transition);
}

.ctx-menu-item:hover { background: var(--bg-hover); }
.ctx-menu-item.danger { color: var(--danger); }
.ctx-menu-item.danger:hover { background: var(--danger-light); }
.ctx-menu-item.danger.disabled,
.ctx-menu-item:disabled {
  opacity: 0.35;
  cursor: default;
}
.ctx-menu-item.danger.disabled:hover,
.ctx-menu-item:disabled:hover {
  background: transparent;
}

/* BUG3修复：删除触发器样式（非按钮，点击展开确认） */
.ctx-menu-item.danger-trigger {
  display: flex;
  align-items: center;
  gap: 8px;
  width: 100%;
  padding: 6px 10px;
  border: none;
  background: transparent;
  border-radius: 5px;
  cursor: pointer;
  font-size: 12px;
  color: var(--danger);
  font-family: var(--font);
  transition: background var(--transition);
}
.ctx-menu-item.danger-trigger:hover {
  background: var(--danger-light);
}
.ctx-menu-item.danger-trigger.disabled {
  opacity: 0.35;
  cursor: default;
  pointer-events: none;
}

/* 二级删除确认区域 */
.ctx-delete-confirm {
  padding: 6px 8px;
  display: flex;
  flex-direction: column;
  gap: 6px;
}
.ctx-confirm-tip {
  font-size: 11px;
  color: var(--danger);
  font-weight: 500;
  text-align: center;
}
.ctx-confirm-btns {
  display: flex;
  gap: 4px;
}
.ctx-confirm-cancel {
  flex: 1;
  padding: 4px 0;
  border: 0.5px solid var(--border);
  background: transparent;
  border-radius: 4px;
  cursor: pointer;
  font-size: 11px;
  color: var(--text-secondary);
  font-family: var(--font);
  transition: all var(--transition);
}
.ctx-confirm-cancel:hover {
  background: var(--bg-hover);
}
.ctx-confirm-ok {
  flex: 1;
  padding: 4px 0;
  border: none;
  background: var(--danger);
  border-radius: 4px;
  cursor: pointer;
  font-size: 11px;
  color: #fff;
  font-family: var(--font);
  font-weight: 500;
  transition: all var(--transition);
}
.ctx-confirm-ok:hover {
  opacity: 0.85;
}

.ctx-menu-divider {
  height: 1px;
  background: var(--border);
  margin: 3px 4px;
}

/* 颜色选择行 */
.ctx-color-row {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 4px 10px;
}

.ctx-color-label {
  font-size: 11px;
  color: var(--text-tertiary);
  flex-shrink: 0;
}

.ctx-colors {
  display: flex;
  gap: 4px;
  flex-wrap: wrap;
}

.ctx-color-btn {
  width: 18px;
  height: 18px;
  border-radius: 50%;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.15s;
  padding: 0;
  flex-shrink: 0;
}

.ctx-color-btn:hover {
  transform: scale(1.25);
}

.ctx-color-btn.active {
  box-shadow: 0 0 0 1.5px var(--text-primary);
}

.content {
  flex: 1;
  overflow: hidden;
  display: flex;
  flex-direction: column;
  background: var(--bg-app);
  position: relative;
}

/* 面板切换动画 */
.panel-fade-enter-active {
  transition: opacity 0.2s ease, transform 0.25s cubic-bezier(0.16, 1, 0.3, 1);
}
.panel-fade-leave-active {
  transition: opacity 0.15s ease, transform 0.15s ease;
  position: absolute;
  inset: 0;
}
.panel-fade-enter-from {
  opacity: 0;
  transform: translateX(16px);
}
.panel-fade-leave-to {
  opacity: 0;
  transform: translateX(-8px);
}

/* ===== 自定义模态弹窗（替换原生 prompt/confirm） ===== */
.modal-overlay {
  position: fixed;
  inset: 0;
  z-index: 1000;
  background: rgba(0,0,0,0.35);
  backdrop-filter: blur(4px);
  -webkit-backdrop-filter: blur(4px);
  display: flex;
  align-items: center;
  justify-content: center;
}

.modal-box {
  background: var(--bg-surface);
  border: 0.5px solid var(--border);
  border-radius: 14px;
  padding: 18px 20px;
  box-shadow: 0 16px 48px rgba(0,0,0,0.25);
  min-width: 280px;
  max-width: 340px;
  width: 90%;
  animation: modalIn 0.2s cubic-bezier(0.16, 1, 0.3, 1);
}

@keyframes modalIn {
  from { opacity: 0; transform: scale(0.92) translateY(10px); }
  to { opacity: 1; transform: scale(1) translateY(0); }
}

.modal-header {
  margin-bottom: 12px;
}

.modal-title {
  font-size: 14px;
  font-weight: 600;
  color: var(--text-primary);
}

.modal-body {
  margin-bottom: 16px;
}

.modal-message {
  font-size: 13px;
  color: var(--text-secondary);
  line-height: 1.5;
}

.modal-input {
  width: 100%;
  border: 0.5px solid var(--border);
  border-radius: 8px;
  padding: 9px 12px;
  font-size: 13px;
  background: var(--bg-input);
  color: var(--text-primary);
  outline: none;
  font-family: var(--font);
  transition: border-color 0.15s;
  margin-top: 8px;
}

.modal-input:focus {
  border-color: var(--accent);
  box-shadow: 0 0 0 2px var(--accent-light);
}

.modal-input::placeholder {
  color: var(--text-placeholder);
}

.modal-footer {
  display: flex;
  justify-content: flex-end;
  gap: 8px;
}

.modal-btn {
  padding: 7px 16px;
  border-radius: 8px;
  font-size: 12px;
  font-weight: 500;
  cursor: pointer;
  font-family: var(--font);
  transition: all 0.15s;
  border: none;
}

.modal-btn-cancel {
  background: var(--bg-hover);
  color: var(--text-secondary);
}

.modal-btn-cancel:hover {
  background: var(--bg-active);
  color: var(--text-primary);
}

.modal-btn-confirm {
  background: var(--accent);
  color: #fff;
}

.modal-btn-confirm:hover {
  opacity: 0.88;
  transform: translateY(-1px);
}

.modal-btn-confirm.danger {
  background: var(--danger);
}

.modal-btn-confirm.danger:hover {
  opacity: 0.88;
}

/* 弹窗过渡 */
.modal-fade-enter-active { transition: all 0.2s ease; }
.modal-fade-leave-active { transition: all 0.15s ease; }
.modal-fade-enter-from { opacity: 0; }
.modal-fade-enter-from .modal-box { transform: scale(0.92) translateY(10px); }
.modal-fade-leave-to { opacity: 0; }
.modal-fade-leave-to .modal-box { transform: scale(0.95); }

/* 面板切换过渡 */
.panel-fade-enter-active {
  transition: opacity 0.2s ease, transform 0.2s cubic-bezier(0.16, 1, 0.3, 1);
}
.panel-fade-leave-active {
  transition: opacity 0.12s ease;
}
.panel-fade-enter-from {
  opacity: 0;
  transform: translateY(6px);
}
.panel-fade-leave-to {
  opacity: 0;
}

/* 按钮微交互增强 */
.ctrl-btn {
  transition: all var(--transition-fast);
}
.ctrl-btn:active {
  transform: scale(0.88);
}
.ctrl-btn:hover {
  transform: scale(1.05);
}
.ctrl-btn.close-btn:hover {
  transform: scale(1.08);
}

/* 主 Tab 按钮动画 */
.main-tab {
  transition: all var(--transition);
  position: relative;
}
.main-tab:active {
  transform: scale(0.95);
}

/* 子 Tab 动画 */
.sub-tab {
  transition: all var(--transition-fast);
}
.sub-tab:active {
  transform: scale(0.96);
}
.sub-add-btn {
  transition: all var(--transition-fast);
}
.sub-add-btn:hover {
  transform: rotate(90deg) scale(1.1);
}
.sub-add-btn:active {
  transform: rotate(90deg) scale(0.9);
}

/* 回收站按钮动画 */
.trash-btn {
  transition: all var(--transition-fast);
}
.trash-btn:hover {
  transform: scale(1.1);
}
.trash-btn:active {
  transform: scale(0.9);
}

/* 极简模式切换按钮动画 */
.ctrl-btn.active {
  animation: modeSwitch 0.3s cubic-bezier(0.34, 1.56, 0.64, 1);
}
@keyframes modeSwitch {
  0% { transform: scale(1); }
  50% { transform: scale(1.15); }
  100% { transform: scale(1); }
}

/* ========== 主题选择弹出面板 ========== */
.theme-btn-wrap {
  position: relative;
  display: flex;
  align-items: center;
}

.theme-picker-popup {
  position: absolute;
  top: calc(100% + 6px);
  right: -30px;
  z-index: 200;
  background: var(--bg-surface);
  border: 0.5px solid var(--border);
  border-radius: 10px;
  padding: 8px;
  box-shadow: 0 8px 28px rgba(0,0,0,0.2), 0 0 0 1px var(--border);
  min-width: 0;
  animation: themeIn 0.15s cubic-bezier(0.16, 1, 0.3, 1);
  backdrop-filter: blur(20px) saturate(180%);
  -webkit-backdrop-filter: blur(20px) saturate(180%);
}

@keyframes themeIn {
  from { opacity: 0; transform: translateY(-6px) scale(0.95); }
  to { opacity: 1; transform: translateY(0) scale(1); }
}

.theme-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 5px;
}

.theme-card {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 4px;
  padding: 6px 4px 5px;
  border: 1.5px solid transparent;
  border-radius: 8px;
  background: var(--bg-hover);
  cursor: pointer;
  transition: all 0.18s cubic-bezier(0.16, 1, 0.3, 1);
  position: relative;
  font-family: var(--font);
}

.theme-card:hover {
  background: var(--bg-active);
  border-color: var(--border);
  transform: translateY(-1px);
  box-shadow: var(--shadow-sm);
}

.theme-card.active {
  border-color: var(--accent);
  background: var(--accent-light);
  box-shadow: var(--shadow-glow);
}

.theme-card-preview {
  width: 24px;
  height: 24px;
  border-radius: 50%;
  background: var(--tc-bg);
  display: flex;
  align-items: center;
  justify-content: center;
  position: relative;
  box-shadow: 0 1px 4px rgba(0,0,0,0.1), inset 0 1px 0 rgba(255,255,255,0.35);
  transition: all 0.2s cubic-bezier(0.16, 1, 0.3, 1);
}

.theme-card:hover .theme-card-preview {
  transform: scale(1.1);
  box-shadow: 0 2px 10px rgba(0,0,0,0.15), inset 0 1px 0 rgba(255,255,255,0.35);
}

.theme-card.active .theme-card-preview {
  box-shadow: 0 0 0 2px var(--accent-glow), 0 1px 4px rgba(0,0,0,0.1), inset 0 1px 0 rgba(255,255,255,0.35);
  transform: scale(1.05);
}

.theme-card-label {
  font-size: 10px;
  font-weight: 700;
  color: var(--tc-text);
  letter-spacing: -0.02em;
  opacity: 0.7;
}

.theme-card-name {
  font-size: 10px;
  font-weight: 600;
  color: var(--text-primary);
  white-space: nowrap;
}

.theme-card-check {
  position: absolute;
  top: 3px;
  right: 3px;
  color: var(--accent);
  opacity: 0.9;
}

/* ===== 主题弹窗内透明度控制行 ===== */
.theme-opacity-row {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-top: 10px;
  padding: 6px 4px 2px;
  border-top: 0.5px solid var(--border);
  color: var(--text-secondary);
}

.theme-opacity-row .opacity-slider {
  flex: 1;
  height: 4px;
  -webkit-appearance: none;
  appearance: none;
  background: var(--border-strong);
  border-radius: 2px;
  outline: none;
  cursor: pointer;
}

.theme-opacity-row .opacity-slider::-webkit-slider-thumb {
  -webkit-appearance: none;
  width: 14px;
  height: 14px;
  background: var(--accent);
  border: 2px solid white;
  border-radius: 50%;
  cursor: pointer;
  box-shadow: 0 1px 4px rgba(0,0,0,0.2);
}

.theme-opacity-row .opacity-val {
  font-size: 11px;
  color: var(--text-tertiary);
  min-width: 34px;
  text-align: right;
}

/* color-pop 过渡复用 */
.color-pop-enter-active {
  transition: opacity 0.15s ease, transform 0.18s cubic-bezier(0.16, 1, 0.3, 1);
}
.color-pop-leave-active {
  transition: opacity 0.1s ease, transform 0.1s ease;
}
.color-pop-enter-from {
  opacity: 0;
  transform: translateY(-6px) scale(0.96);
}
.color-pop-leave-to {
  opacity: 0;
  transform: translateY(-4px) scale(0.97);
}
</style>
