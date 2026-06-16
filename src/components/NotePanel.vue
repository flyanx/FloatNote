<template>
  <div class="note-panel">
    <!-- 笔记列表侧栏 -->
    <div class="note-sidebar" v-show="sidebarVisible">
      <div class="sidebar-header">
        <button class="add-note-btn" @click="addNote" title="新建笔记">
          <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
            <line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/>
          </svg>
          <span>新建</span>
        </button>
      </div>

      <div class="note-list">
        <div
          v-for="(note, idx) in notes"
          :key="note.id"          class="note-item"
          :class="{ active: activeNoteId === note.id, pinned: note.pinned }"
          @click="selectNote(note.id)"
          @contextmenu.prevent="openNoteCtxMenu($event, note)"
          :style="{ borderLeftColor: note.pinned ? 'var(--accent)' : (note.color || 'transparent'), borderLeftWidth: note.pinned ? '3px' : '3px', borderLeftStyle: 'solid' }"
        >
          <div class="note-item-content">
            <div class="note-item-title">
              <svg v-if="note.pinned" class="note-pin-icon" width="10" height="10" viewBox="0 0 24 24" fill="var(--accent)" stroke="var(--accent)" stroke-width="1.5">
                <path d="M15 4.5l-1.5 4.5 3.5 2-2 4.5H9l-2-4.5 3.5-2L9 4.5"/>
                <line x1="12" y1="13.5" x2="12" y2="20"/>
                <line x1="10" y1="20" x2="14" y2="20"/>
              </svg>
              {{ note.title || '无标题' }}
            </div>
            <div class="note-item-preview">{{ getPreview(note.content) }}</div>
          </div>
          <button class="note-del-btn" @click.stop="deleteNote(note.id)" title="删除">
            <svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/>
            </svg>
          </button>
        </div>
      </div>

      <!-- 笔记右键菜单 -->
      <transition name="ctx-menu">
        <div class="note-ctx-menu" v-if="noteCtxMenu.visible" :style="{ left: noteCtxMenu.x + 'px', top: noteCtxMenu.y + 'px' }" @click.stop>
          <!-- 置顶 -->
          <button class="ctx-menu-item pin-item" @click="pinNoteToTop" :class="{ pinned: isNotePinned(noteCtxMenu.note) }">
            <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <line x1="12" y1="17" x2="12" y2="22"/>
              <path d="M5 17h14v-1.76a2 2 0 0 0-1.11-1.79l-1.78-.9A2 2 0 0 1 15 10.76V6h1a2 2 0 0 0 0-4H8a2 2 0 0 0 0 4h1v4.76a2 2 0 0 1-1.11 1.79l-1.78.9A2 2 0 0 0 5 15.24V17z"/>
            </svg>
            {{ isNotePinned(noteCtxMenu.note) ? '取消置顶' : '置顶笔记' }}
          </button>
          <div class="ctx-menu-divider"></div>
          <!-- 上移 / 下移（美化版） -->
          <div class="ctx-move-row">
            <button class="ctx-move-btn" @click="moveNoteUp" :disabled="!canMoveNoteUp" title="上移">
              <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2">
                <polyline points="18 15 12 9 6 15"/>
              </svg>
            </button>
            <span class="ctx-move-label">排序</span>
            <button class="ctx-move-btn" @click="moveNoteDown" :disabled="!canMoveNoteDown" title="下移">
              <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2">
                <polyline points="6 9 12 15 18 9"/>
              </svg>
            </button>
          </div>
          <div class="ctx-menu-divider"></div>
          <!-- 笔记颜色快速设置（两行 4+4） -->
          <div class="ctx-color-row-v2">
            <button
              v-for="c in noteColors.slice(0,4)"
              :key="c"
              class="ctx-color-chip"
              :class="{ active: noteCtxMenu.note?.color === c }"
              :style="{ '--chip-color': c }"
              @click.stop="setNoteColorFromCtx(c)"
            >
              <span class="chip-dot"></span>
              <svg v-if="noteCtxMenu.note?.color === c" class="chip-check" width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="#fff" stroke-width="3"><polyline points="20 6 9 17 4 12"/></svg>
            </button>
          </div>
          <div class="ctx-color-row-v2">
            <button
              v-for="c in noteColors.slice(4,8)"
              :key="c"
              class="ctx-color-chip"
              :class="{ active: noteCtxMenu.note?.color === c }"
              :style="{ '--chip-color': c }"
              @click.stop="setNoteColorFromCtx(c)"
            >
              <span class="chip-dot"></span>
              <svg v-if="noteCtxMenu.note?.color === c" class="chip-check" width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="#fff" stroke-width="3"><polyline points="20 6 9 17 4 12"/></svg>
            </button>
          </div>
        </div>
      </transition>
    </div>

    <!-- 编辑区 -->
    <div
      class="note-editor"
      :class="{ 'drag-over': isDragOver }"
      @dragover.prevent="onDragOver"
      @dragleave="onDragLeave"
      @drop.prevent="onDrop"
      v-if="activeNote"
    >
      <div class="editor-header">
        <input
          class="note-title-input selectable"
          v-model="activeNote.title"
          placeholder="标题..."
          @input="debounceSave"
          maxlength="50"
        />
        <div class="editor-actions">
          <button class="action-btn" :class="{ active: richMode }" @click="toggleRichMode" title="富文本模式">
            <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/>
              <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/>
            </svg>
          </button>
          <button class="action-btn" :class="{ active: markdownMode }" @click="toggleMarkdownMode" title="Markdown 模式">
            <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <path d="M4 7v10"/><path d="M8 7v10"/><path d="M4 12h4"/><path d="M14 7l3 10 3-10"/>
            </svg>
          </button>
          <div class="screenshot-btn-wrap" @click.stop>
            <button class="action-btn" :class="{ active: showScreenshotMenu }" @click.stop="showScreenshotMenu = !showScreenshotMenu" title="截图">
              <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M23 19a2 2 0 0 1-2 2H3a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h4l2-3h6l2 3h4a2 2 0 0 1 2 2z"/>
                <circle cx="12" cy="13" r="4"/>
              </svg>
            </button>
            <transition name="color-pop">
              <div class="screenshot-dropdown" v-if="showScreenshotMenu" @click.stop>
                <button class="ss-menu-item" @click="startScreenshot('direct')">
                  <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <rect x="3" y="3" width="18" height="18" rx="2"/>
                    <circle cx="12" cy="12" r="3"/>
                  </svg>
                  直接截图
                </button>
                <button class="ss-menu-item" @click="startScreenshot('hide')">
                  <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94"/>
                    <line x1="1" y1="1" x2="23" y2="23"/>
                  </svg>
                  隐藏后截图
                </button>
                <div class="ss-divider"></div>
                <div class="ss-hotkey-row">
                  <span class="ss-hotkey-label">快捷键</span>
                  <input
                    class="ss-hotkey-input"
                    :value="screenshotHotkey"
                    @keydown.prevent="captureHotkey"
                    @blur="saveHotkey"
                    placeholder="点击输入快捷键..."
                    readonly
                  />
                </div>
              </div>
            </transition>
          </div>
          <button class="action-btn" @click="importMarkdown" title="导入 Markdown">
            <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/>
              <polyline points="7 10 12 15 17 10"/><line x1="12" y1="15" x2="12" y2="3"/>
            </svg>
          </button>
          <button class="action-btn" @click="exportMarkdown" title="导出 Markdown">
            <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/>
              <polyline points="17 8 12 3 7 8"/><line x1="12" y1="3" x2="12" y2="15"/>
            </svg>
          </button>
        </div>
      </div>

    <!-- 富文本工具栏 -->
    <div class="editor-toolbar" v-if="richMode && !minimalMode">
      <button class="tb-btn" @click="execCmd('bold')" title="加粗 (Ctrl+B)"><b>B</b></button>
      <button class="tb-btn" @click="execCmd('italic')" title="斜体 (Ctrl+I)"><i>I</i></button>
      <button class="tb-btn" @click="execCmd('underline')" title="下划线 (Ctrl+U)"><u>U</u></button>
      <button class="tb-btn" @click="execCmd('strikeThrough')" title="删除线"><s>S</s></button>
      <span class="tb-sep"></span>
      <div class="tb-list-dropdown" @click.stop>
        <button class="tb-btn" :class="{ active: listType }" @click="showListDropdown = !showListDropdown" title="列表">
          <svg v-if="listType === 'ol'" width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <line x1="10" y1="6" x2="21" y2="6"/><line x1="10" y1="12" x2="21" y2="12"/><line x1="10" y1="18" x2="21" y2="18"/>
            <text x="3" y="8" font-size="7" fill="currentColor" stroke="none" font-family="sans-serif">1</text>
            <text x="3" y="14" font-size="7" fill="currentColor" stroke="none" font-family="sans-serif">2</text>
            <text x="3" y="20" font-size="7" fill="currentColor" stroke="none" font-family="sans-serif">3</text>
          </svg>
          <svg v-else width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <line x1="9" y1="6" x2="20" y2="6"/><line x1="9" y1="12" x2="20" y2="12"/><line x1="9" y1="18" x2="20" y2="18"/>
            <circle cx="4.5" cy="6" r="1.5" fill="currentColor"/><circle cx="4.5" cy="12" r="1.5" fill="currentColor"/><circle cx="4.5" cy="18" r="1.5" fill="currentColor"/>
          </svg>
          <svg class="tb-dropdown-arrow" width="8" height="8" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
            <polyline points="6 9 12 15 18 9"/>
          </svg>
        </button>
        <transition name="color-pop">
          <div class="tb-list-dropdown-menu" v-if="showListDropdown">
            <button class="tb-dropdown-item" :class="{ active: listType === 'ul' }" @click="execCmd('insertUnorderedList'); listType = listType === 'ul' ? null : 'ul'; showListDropdown = false">
              <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <line x1="9" y1="6" x2="20" y2="6"/><line x1="9" y1="12" x2="20" y2="12"/><line x1="9" y1="18" x2="20" y2="18"/>
                <circle cx="4.5" cy="6" r="1.5" fill="currentColor"/><circle cx="4.5" cy="12" r="1.5" fill="currentColor"/><circle cx="4.5" cy="18" r="1.5" fill="currentColor"/>
              </svg>
              无序列表
            </button>
            <button class="tb-dropdown-item" :class="{ active: listType === 'ol' }" @click="execCmd('insertOrderedList'); listType = listType === 'ol' ? null : 'ol'; showListDropdown = false">
              <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <line x1="10" y1="6" x2="21" y2="6"/><line x1="10" y1="12" x2="21" y2="12"/><line x1="10" y1="18" x2="21" y2="18"/>
                <text x="3" y="8" font-size="7" fill="currentColor" stroke="none" font-family="sans-serif">1</text>
                <text x="3" y="14" font-size="7" fill="currentColor" stroke="none" font-family="sans-serif">2</text>
                <text x="3" y="20" font-size="7" fill="currentColor" stroke="none" font-family="sans-serif">3</text>
              </svg>
              有序列表
            </button>
          </div>
        </transition>
      </div>
      <span class="tb-sep"></span>
      <button class="tb-btn" @click="insertLink" title="插入链接">🔗</button>
      <label class="tb-btn tb-color-btn" title="字体颜色">
        <input type="color" class="tb-color" @change="execCmd('foreColor', $event.target.value)" />
        <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <path d="M12 2L2 22h20L12 2z"/>
          <line x1="7" y1="16" x2="17" y2="16"/>
        </svg>
      </label>
      <button class="tb-btn" @click="insertImageToEditor" title="插入图片">🖼️</button>
      <button class="tb-btn" @click="insertTable" title="插入表格">
        <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <rect x="3" y="3" width="18" height="18" rx="2"/>
          <line x1="3" y1="9" x2="21" y2="9"/>
          <line x1="3" y1="15" x2="21" y2="15"/>
          <line x1="9" y1="3" x2="9" y2="21"/>
          <line x1="15" y1="3" x2="15" y2="21"/>
        </svg>
      </button>
    </div>

    <!-- 富文本编辑区 -->
    <div
      v-if="richMode"
      ref="editableDiv"
      class="note-content-editable selectable"
      contenteditable="true"
      @input="onRichInput"
      @paste="onPaste"
      @keydown.ctrl.b.prevent="execCmd('bold')"
      @keydown.ctrl.i.prevent="execCmd('italic')"
      @keydown.ctrl.u.prevent="execCmd('underline')"
    ></div>

    <!-- Markdown 模式 -->
    <div v-else class="markdown-wrap">
      <div class="md-tab-bar">
        <button class="md-tab" :class="{ active: !markdownPreview }" @click="markdownPreview = false">编辑</button>
        <button class="md-tab" :class="{ active: markdownPreview }" @click="markdownPreview = true">预览</button>
      </div>
      <div class="md-body">
        <textarea
          ref="noteEditorEl"
          v-show="!markdownPreview"
          class="note-textarea selectable md-editor"
          v-model="activeNote.content"
          placeholder="支持 Markdown 语法..."
          @input="debounceSave"
          spellcheck="false"
        ></textarea>
        <div v-if="markdownPreview" class="md-preview selectable" v-html="markdownHtml"></div>
      </div>
      <div class="md-hint" v-if="!markdownPreview">
        图片语法: ![描述](url "=宽度px 对齐") 例: ![图](img.png "=300 center")
      </div>
    </div>

      <div class="editor-footer">
        <span class="char-count">{{ charCount }} 字</span>
        <span class="save-status" :class="saveStatus">{{ saveStatusText }}</span>
      </div>

      <!-- 拖拽图片提示遮罩 -->
      <transition name="drag-hint">
        <div class="drag-overlay" v-if="isDragOver">
          <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
            <rect x="3" y="3" width="18" height="18" rx="2"/>
            <circle cx="8.5" cy="8.5" r="1.5"/>
            <polyline points="21 15 16 10 5 21"/>
          </svg>
          <span>松开即可插入图片</span>
        </div>
      </transition>
    </div>

    <div class="note-empty" v-else>
      <svg width="36" height="36" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" style="opacity:0.25">
        <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/>
        <polyline points="14 2 14 8 20 8"/>
      </svg>
      <p>点击左侧 + 新建笔记</p>
    </div>

    <!-- 隐藏的文件选择器 -->
    <input
      ref="fileInput"
      type="file"
      accept="image/*"
      style="display:none"
      @change="handleImageSelect"
    />

    <!-- 隐藏的 Markdown 导入选择器 -->
    <input
      ref="mdFileInput"
      type="file"
      accept=".md,.markdown,text/markdown"
      style="display:none"
      @change="handleMdImport"
    />

    <!-- 图片预览 -->
    <div class="img-preview-mask" v-if="previewImg" @click="previewImg = null">
      <img :src="previewImg" class="img-preview-full" />
    </div>

    <!-- Toast 提示 -->
    <transition name="toast-fade">
      <div class="panel-toast" v-if="toast.show">{{ toast.message }}</div>
    </transition>

    <!-- 截图覆盖层 -->
    <ScreenshotOverlay
      v-if="screenshotOverlay.show"
      :data-url="screenshotOverlay.dataUrl"
      :img-width="screenshotOverlay.imgWidth"
      :img-height="screenshotOverlay.imgHeight"
      @done="onScreenshotDone"
      @cancel="onScreenshotCancel"
    />

    <!-- 富文本图片工具条 -->
    <div class="img-resize-toolbar" v-if="selectedImg" :style="imgToolbarStyle">
      <div class="img-align-btns">
        <button class="img-align-btn" @click="setImageAlign('left')" title="左对齐">
          <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <line x1="3" y1="6" x2="21" y2="6"/><rect x="3" y="10" width="12" height="8" rx="1"/>
          </svg>
        </button>
        <button class="img-align-btn" @click="setImageAlign('center')" title="居中">
          <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <line x1="3" y1="6" x2="21" y2="6"/><rect x="6" y="10" width="12" height="8" rx="1"/>
          </svg>
        </button>
        <button class="img-align-btn" @click="setImageAlign('right')" title="右对齐">
          <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <line x1="3" y1="6" x2="21" y2="6"/><rect x="9" y="10" width="12" height="8" rx="1"/>
          </svg>
        </button>
      </div>
      <span class="img-size-info">{{ selectedImgWidth }}×{{ selectedImgHeight }}</span>
    </div>

    <!-- 侧边栏浮动切换按钮：粘在左侧边缘，不占布局空间 -->
    <div class="sidebar-toggle-float" @click="sidebarVisible = !sidebarVisible" :title="sidebarVisible ? '隐藏侧栏' : '显示侧栏'">
      <svg v-if="sidebarVisible" width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <polyline points="15 6 9 12 15 18"/>
      </svg>
      <svg v-else width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <polyline points="9 6 15 12 9 18"/>
      </svg>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted, watch, nextTick } from 'vue'
import { marked } from 'marked'
import ScreenshotOverlay from './ScreenshotOverlay.vue'
import { getCurrentWebviewWindow } from '@tauri-apps/api/webviewWindow'
import { invoke } from '@tauri-apps/api/core'
import { readJSON, writeJSON } from '../utils/storage.js'
import { addItemToTrash } from '../utils/trash.js'
import { NOTE_COLORS } from '../utils/colors.js'
import { generateId } from '../utils/id.js'
import { useToast } from '../composables/useToast.js'
import { useContextMenu } from '../composables/useContextMenu.js'

const NOTES_KEY = 'sn-notebooks'

const notebooks = ref([])
const activeBookId = ref(null)
const saveStatus = ref('saved')
const previewImg = ref(null)
const fileInput = ref(null)
const mdFileInput = ref(null)
const richMode = ref(true)
const markdownMode = ref(false)
const markdownPreview = ref(false)
const editableDiv = ref(null)
const noteEditorEl = ref(null)
const showColorPicker = ref(false)
const sidebarVisible = ref(localStorage.getItem('sn-sidebar-visible') !== '0')
const showBookMenu = ref(false)
const editingBookId = ref(null)
const isDragOver = ref(false)
const noteColors = NOTE_COLORS

// 截图相关
const showScreenshotMenu = ref(false)
const screenshotHotkey = ref(localStorage.getItem('sn-screenshot-hotkey') || 'CommandOrControl+Shift+A')
const screenshotOverlay = ref({ show: false, dataUrl: '', imgWidth: 0, imgHeight: 0 })
let _lastScreenshotMode = 'direct' // 用于快捷键触发

// 图片工具条
const selectedImg = ref(null)
const imgToolbarStyle = ref({})
const selectedImgWidth = ref(0)
const selectedImgHeight = ref(0)

// 笔记右键菜单
const { menu: noteCtxMenu, open: openNoteCtxMenuBase, close: closeNoteCtxMenuBase } = useContextMenu()
const noteDeleteConfirm = ref(false)
const { toast, showToast } = useToast()
let saveTimer = null

const activeBook = computed(() => notebooks.value.find(b => b.id === activeBookId.value) || null)
const notes = computed(() => activeBook.value?.notes || [])
const activeNoteId = ref(null)
const activeNote = computed(() => notes.value.find(n => n.id === activeNoteId.value) || null)
const charCount = computed(() => activeNote.value ? (activeNote.value.content || '').length : 0)

const saveStatusText = computed(() => saveStatus.value === 'saving' ? '保存中...' : '已保存')
const markdownHtml = computed(() => {
  if (!activeNote.value || !activeNote.value.content) return ''
  try {
    // 自定义 renderer 支持图片扩展语法: ![alt](url "=WIDTH ALIGN")
    const renderer = new marked.Renderer()
    const origImage = renderer.image.bind(renderer)
    renderer.image = function(token) {
      // marked v18+ 传 token 对象 { href, title, text }
      const href = token.href || ''
      const title = token.title || ''
      const text = token.text || ''
      let width = '', align = ''
      const sizeMatch = title.match(/=(\d+)/)
      const alignMatch = title.match(/\b(left|center|right)\b/)
      if (sizeMatch) width = sizeMatch[1]
      if (alignMatch) align = alignMatch[1]
      let style = 'max-width:100%;border-radius:6px;margin:4px 0;'
      if (width) style += `width:${width}px;`
      if (align === 'center') style += 'display:block;margin-left:auto;margin-right:auto;'
      else if (align === 'right') style += 'display:block;margin-left:auto;margin-right:0;'
      else style += 'display:block;'
      return `<img src="${href}" alt="${text}" style="${style}" />`
    }
    return marked.parse(activeNote.value.content || '', { breaks: true, gfm: true, renderer })
  } catch {
    return activeNote.value.content
  }
})

// 笔记本管理
function addNotebook() {
  const book = { id: Date.now(), name: `记事本 ${notebooks.value.length + 1}`, notes: [] }
  notebooks.value.push(book)
  activeBookId.value = book.id
  showBookMenu.value = false
  saveData()
  window.dispatchEvent(new CustomEvent('notebooks-updated'))
}

function switchBook(id) {
  activeBookId.value = id
  showBookMenu.value = false
  activeNoteId.value = notes.value.length ? notes.value[0].id : null
  localStorage.setItem('sn-active-book', id)
}

function deleteBook(id) {
  if (notebooks.value.length <= 1) return
  const idx = notebooks.value.findIndex(b => b.id === id)
  notebooks.value.splice(idx, 1)
  if (activeBookId.value === id) {
    activeBookId.value = notebooks.value[Math.max(0, idx - 1)]?.id || null
    activeNoteId.value = notes.value.length ? notes.value[0].id : null
  }
  showBookMenu.value = false
  saveData()
  window.dispatchEvent(new CustomEvent('notebooks-updated'))
}

function startRenameBook(id) {
  editingBookId.value = id
  showBookMenu.value = false
  nextTick(() => {
    const input = document.querySelector('.book-rename-input')
    if (input) { input.focus(); input.select() }
  })
}

function finishRenameBook(book) {
  if (!book.name.trim()) book.name = '未命名'
  editingBookId.value = null
  saveData()
}

// 模式互斥：只有富文本和 Markdown 两种模式
let _richClicks = []
function toggleRichMode() {
  richMode.value = true
  markdownMode.value = false
  markdownPreview.value = false
  // 5连击解锁隐藏按钮
  const now = Date.now()
  _richClicks = _richClicks.filter(t => now - t < 2000)
  _richClicks.push(now)
  if (_richClicks.length >= 5) {
    _richClicks = []
    window.dispatchEvent(new CustomEvent('dev-unlock'))
  }
}

function toggleMarkdownMode() {
  markdownMode.value = true
  richMode.value = false
  markdownPreview.value = false
}

// 富文本 HTML 内容的独立存储（防止切换到 Markdown 时丢失）
function saveRichContent() {
  if (activeNote.value && editableDiv.value) {
    activeNote.value._richContent = editableDiv.value.innerHTML
  }
}

function restoreRichContent() {
  if (activeNote.value && editableDiv.value) {
    const html = activeNote.value._richContent || activeNote.value.content || ''
    editableDiv.value.innerHTML = html
  }
}

function getPreview(content) {
  if (!content) return '无内容'
  // 去除 HTML 标签后截取预览
  const plain = content.replace(/<[^>]+>/g, ' ').replace(/\s+/g, ' ').trim()
  return plain.slice(0, 30) || '无内容'
}

// --- 富文本编辑功能 ---
function execCmd(command, value = null) {
  document.execCommand(command, false, value)
  editableDiv.value?.focus()
}

function insertLink() {
  const url = prompt('输入链接 URL:')
  if (url) {
    document.execCommand('createLink', false, url)
    editableDiv.value?.focus()
  }
}

function onRichInput() {
  if (!activeNote.value || !editableDiv.value) return
  activeNote.value.content = editableDiv.value.innerHTML
  activeNote.value._richContent = editableDiv.value.innerHTML
  debounceSave()
}

// 记住富文本光标位置（打开文件选择器后焦点会丢失）
let savedRange = null
function saveCaretPosition() {
  const sel = window.getSelection()
  if (sel && sel.rangeCount > 0 && editableDiv.value?.contains(sel.getRangeAt(0).startContainer)) {
    savedRange = sel.getRangeAt(0).cloneRange()
  }
}
function restoreCaretPosition() {
  if (!savedRange || !editableDiv.value) return
  editableDiv.value.focus()
  const sel = window.getSelection()
  if (sel) {
    sel.removeAllRanges()
    sel.addRange(savedRange)
  }
  savedRange = null
}

function insertImageToEditor() {
  saveCaretPosition()
  const input = document.createElement('input')
  input.type = 'file'
  input.accept = 'image/*'
  input.onchange = (e) => {
    const file = e.target.files?.[0]
    if (!file) return
    const reader = new FileReader()
    reader.onload = (ev) => {
      restoreCaretPosition()
      const imgHtml = `<img src="${ev.target.result}" style="max-width:100%;border-radius:6px;margin:4px 0;display:block;" />`
      document.execCommand('insertHTML', false, imgHtml)
      if (activeNote.value) {
        activeNote.value.content = editableDiv.value?.innerHTML || ''
        activeNote.value._richContent = editableDiv.value?.innerHTML || ''
        debounceSave()
      }
    }
    reader.readAsDataURL(file)
  }
  input.click()
}

// 粘贴处理——支持从剪贴板粘贴截图
function onPaste(e) {
  const items = e.clipboardData?.items
  if (!items) return
  for (const item of items) {
    if (item.type.startsWith('image/')) {
      e.preventDefault()
      const blob = item.getAsFile()
      if (!blob) return
      const reader = new FileReader()
      reader.onload = (ev) => {
        const imgHtml = `<img src="${ev.target.result}" style="max-width:100%;border-radius:6px;margin:4px 0;display:block;" />`
        document.execCommand('insertHTML', false, imgHtml)
        if (activeNote.value) {
          activeNote.value.content = editableDiv.value?.innerHTML || ''
          activeNote.value._richContent = editableDiv.value?.innerHTML || ''
          debounceSave()
        }
      }
      reader.readAsDataURL(blob)
      return
    }
  }
}

function insertTable() {
  // 插入 3x3 表格
  const rows = 3, cols = 3
  let html = '<table style="border-collapse:collapse;width:100%;margin:8px 0;">'
  for (let r = 0; r < rows; r++) {
    html += '<tr>'
    for (let c = 0; c < cols; c++) {
      const tag = r === 0 ? 'th' : 'td'
      html += `<${tag} style="border:1px solid var(--border-strong);padding:6px 10px;font-size:12px;${r === 0 ? 'background:var(--bg-surface);font-weight:600;' : ''}">${r === 0 ? '标题' : ''}</${tag}>`
    }
    html += '</tr>'
  }
  html += '</table><p><br/></p>'
  document.execCommand('insertHTML', false, html)
  if (activeNote.value) {
    activeNote.value.content = editableDiv.value?.innerHTML || ''
    debounceSave()
  }
  editableDiv.value?.focus()
}
// --- 富文本功能结束 ---

const pinnedCount = computed(() => notes.value.filter(n => n.pinned).length)

// 笔记右键菜单 - 置顶
function openNoteCtxMenu(e, note) {
  openNoteCtxMenuBase(e, { note })
  noteDeleteConfirm.value = false
}

function isNotePinned(note) {
  if (!note) return false
  return !!note.pinned
}

const canMoveNoteUp = computed(() => {
  const note = noteCtxMenu.value.note
  if (!note || !activeBook.value) return false
  const idx = activeBook.value.notes.findIndex(n => n.id === note.id)
  if (idx <= 0) return false
  // 非置顶笔记不能越过置顶边界上移
  const pn = pinnedCount.value
  if (!note.pinned && idx === pn) return false
  return true
})

const canMoveNoteDown = computed(() => {
  const note = noteCtxMenu.value.note
  if (!note || !activeBook.value) return false
  const idx = activeBook.value.notes.findIndex(n => n.id === note.id)
  if (idx < 0 || idx >= activeBook.value.notes.length - 1) return false
  // 置顶笔记不能越过边界下移到非置顶区
  const pn = pinnedCount.value
  if (note.pinned && idx === pn - 1 && pn > 0) return false
  return true
})

function moveNoteUp() {
  const note = noteCtxMenu.value.note
  if (!note || !activeBook.value) return
  const idx = activeBook.value.notes.findIndex(n => n.id === note.id)
  if (idx <= 0) return
  // 非置顶笔记不能越过边界上移到置顶区
  const pn = pinnedCount.value
  if (!note.pinned && idx === pn) return
  activeBook.value.notes.splice(idx, 1)
  activeBook.value.notes.splice(idx - 1, 0, note)
  saveData()
  closeNoteCtxMenuBase()
}

function moveNoteDown() {
  const note = noteCtxMenu.value.note
  if (!note || !activeBook.value) return
  const idx = activeBook.value.notes.findIndex(n => n.id === note.id)
  if (idx < 0 || idx >= activeBook.value.notes.length - 1) return
  // 置顶笔记不能越过边界下移到非置顶区
  const pn = pinnedCount.value
  if (note.pinned && idx === pn - 1 && pn > 0) return
  activeBook.value.notes.splice(idx, 1)
  activeBook.value.notes.splice(idx + 1, 0, note)
  saveData()
  closeNoteCtxMenuBase()
}

function setNoteColorFromCtx(color) {
  const note = noteCtxMenu.value.note
  if (!note || !activeBook.value) return
  const realNote = activeBook.value.notes.find(n => n.id === note.id)
  if (realNote) {
    realNote.color = color
    saveData()
  }
  closeNoteCtxMenuBase()
}

function deleteNoteFromCtx() {
  const note = noteCtxMenu.value.note
  closeNoteCtxMenuBase()
  noteDeleteConfirm.value = false
  if (!note) return
  deleteNote(note.id)
}

function pinNoteToTop() {
  const note = noteCtxMenu.value.note
  closeNoteCtxMenuBase()
  if (!note || !activeBook.value) return
  const idx = activeBook.value.notes.findIndex(n => n.id === note.id)
  if (idx < 0) return
  if (note.pinned) {
    // 取消置顶
    note.pinned = false
  } else {
    // 置顶
    note.pinned = true
    if (idx > 0) {
      activeBook.value.notes.splice(idx, 1)
      activeBook.value.notes.unshift(note)
    }
  }
  saveData()
  activeNoteId.value = note.id
}

function closeNoteCtxMenu() {
  closeNoteCtxMenuBase()
  noteDeleteConfirm.value = false
}

function addNote() {
  if (!activeBook.value) return
  const color = NOTE_COLORS[Math.floor(Math.random() * NOTE_COLORS.length)]
  const note = { id: generateId(), title: '', content: '', images: [], color, createdAt: Date.now() }
  activeBook.value.notes.unshift(note)
  activeNoteId.value = note.id
  saveData()
}

function setNoteColor(color) {
  if (!activeNote.value) return
  activeNote.value.color = color
  showColorPicker.value = false
  saveData()
}

function selectNote(id) {
  activeNoteId.value = id
}

function deleteNote(id) {
  if (!activeBook.value) return
  if (activeBook.value.notes.length === 1) {
    activeBook.value.notes[0] = { ...activeBook.value.notes[0], title: '', content: '', images: [] }
    saveData()
    return
  }
  const idx = activeBook.value.notes.findIndex(n => n.id === id)
  if (idx < 0) return
  const deleted = activeBook.value.notes[idx]
  addItemToTrash(deleted, 'note')
  activeBook.value.notes.splice(idx, 1)
  if (activeNoteId.value === id) {
    activeNoteId.value = activeBook.value.notes[Math.max(0, idx - 1)]?.id || null
  }
  saveData()
}

function insertImage() {
  if (richMode.value) {
    // 富文本模式：在光标位置插入图片
    insertImageToEditor()
  } else {
    // Markdown 模式：使用传统 images[] 附件方式
    fileInput.value?.click()
  }
}

// ===== 截图功能 =====
let _savedWindowSize = null  // 保存窗口原始尺寸
let _savedWindowPos = null   // 保存窗口原始位置

async function startScreenshot(mode) {
  showScreenshotMenu.value = false
  _lastScreenshotMode = mode
  const win = getCurrentWebviewWindow()

  // 立即开始截图（异步不等待）
  const capturePromise = invoke('capture_screen').catch(e => {
    throw new Error('截图失败: ' + e)
  })

  // 同时保存窗口状态（并行）
  let hidePromise = null
  if (mode === 'hide') {
    hidePromise = (async () => {
      try {
        await win.hide()
        await new Promise(r => setTimeout(r, 250))  // DWM 刷新等待
      } catch (e) {
        console.warn('隐藏窗口失败:', e)
      }
    })()
  }

  // 保存当前窗口位置和尺寸（并行）
  try {
    const [pos, size] = await Promise.all([win.outerPosition(), win.outerSize()])
    _savedWindowPos = pos
    _savedWindowSize = size
  } catch {
    _savedWindowPos = null
    _savedWindowSize = null
  }

  // 等待 hide 完成（如果是 hide 模式）
  if (hidePromise) await hidePromise

  // 等待截图完成
  try {
    await capturePromise
  } catch (e) {
    console.error('截图失败:', e)
    showToast(e.message)
    if (mode === 'hide') {
      try { await win.show(); await win.setFocus() } catch {}
    }
    return
  }

  // 获取截图数据
  let screenshotData
  try {
    screenshotData = await invoke('get_screenshot_data')
  } catch (e) {
    console.error('获取截图数据失败:', e)
    showToast('获取截图数据失败: ' + e)
    if (mode === 'hide') {
      try { await win.show(); await win.setFocus() } catch {}
    }
    return
  }

  // 最大化主窗口（覆盖整个屏幕）
  try {
    if (mode === 'hide') {
      await win.show()
    }
    await win.setAlwaysOnTop(true)
    await win.maximize()
    await win.setFocus()
  } catch (e) {
    console.error('最大化窗口失败:', e)
  }

  // 显示截图覆盖层
  screenshotOverlay.value = {
    show: true,
    dataUrl: screenshotData.dataUrl,
    imgWidth: screenshotData.imgWidth,
    imgHeight: screenshotData.imgHeight,
  }
}

async function onScreenshotDone() {
  // 关闭覆盖层
  screenshotOverlay.value = { show: false, dataUrl: '', imgWidth: 0, imgHeight: 0 }
  // 恢复窗口
  await restoreWindowAfterScreenshot()
}

async function onScreenshotCancel() {
  // 关闭覆盖层
  screenshotOverlay.value = { show: false, dataUrl: '', imgWidth: 0, imgHeight: 0 }
  // 恢复窗口
  await restoreWindowAfterScreenshot()
}

async function restoreWindowAfterScreenshot() {
  const win = getCurrentWebviewWindow()
  try {
    await win.unmaximize()
    await win.setAlwaysOnTop(false)
    // 恢复原始尺寸和位置
    if (_savedWindowSize) {
      await win.setSize(_savedWindowSize)
    }
    if (_savedWindowPos) {
      await win.setPosition(_savedWindowPos)
    }
    await win.setFocus()
  } catch (e) {
    console.warn('恢复窗口失败:', e)
  }
  _savedWindowSize = null
  _savedWindowPos = null
}

// 快捷键捕获
function captureHotkey(e) {
  const parts = []
  if (e.ctrlKey || e.metaKey) parts.push('CommandOrControl')
  if (e.shiftKey) parts.push('Shift')
  if (e.altKey) parts.push('Alt')
  const key = e.key
  if (!['Control', 'Shift', 'Alt', 'Meta'].includes(key)) {
    parts.push(key.length === 1 ? key.toUpperCase() : key)
  }
  if (parts.length >= 2) {
    screenshotHotkey.value = parts.join('+')
  }
}

function saveHotkey() {
  const hk = screenshotHotkey.value
  if (hk) {
    localStorage.setItem('sn-screenshot-hotkey', hk)
    registerScreenshotHotkey()
  }
}

async function registerScreenshotHotkey() {
  try {
    const { register, unregister } = await import('@tauri-apps/plugin-global-shortcut')
    const hk = screenshotHotkey.value
    if (!hk) return
    // 先注销旧的
    try { await unregister(hk) } catch {}
    await register(hk, () => {
      startScreenshot(_lastScreenshotMode)
    })
  } catch (e) {
    console.warn('快捷键注册失败:', e)
  }
}

// ===== 富文本图片缩放对齐 =====
function selectImage(imgEl) {
  // 清除之前的选中样式
  if (selectedImg.value && selectedImg.value !== imgEl) {
    selectedImg.value.style.outline = ''
    selectedImg.value.style.outlineOffset = ''
    removeResizeHandles()
  }
  selectedImg.value = imgEl
  imgEl.style.outline = '2px solid #4a9eff'
  imgEl.style.outlineOffset = '2px'
  selectedImgWidth.value = imgEl.offsetWidth
  selectedImgHeight.value = imgEl.offsetHeight

  // 添加缩放手柄
  addResizeHandles(imgEl)

  // 计算工具条位置（统一使用 .note-editor 作为定位参考）
  const rect = imgEl.getBoundingClientRect()
  const editorEl = document.querySelector('.note-editor')
  if (editorEl) {
    const editorRect = editorEl.getBoundingClientRect()
    imgToolbarStyle.value = {
      top: (rect.bottom - editorRect.top + 6) + 'px',
      left: Math.max(0, rect.left - editorRect.left) + 'px'
    }
  }
}

function removeResizeHandles() {
  document.querySelectorAll('body > .img-resize-handle').forEach(h => h.remove())
}

function addResizeHandles(imgEl) {
  removeResizeHandles()
  const corners = ['tl', 'tr', 'bl', 'br']
  corners.forEach(corner => {
    const handle = document.createElement('div')
    handle.className = `img-resize-handle ${corner}`
    // 全部内联样式（scoped CSS 不作用于动态添加到 body 的元素）
    handle.style.cssText = `
      position: fixed;
      z-index: 10001;
      width: 10px;
      height: 10px;
      background: #4a9eff;
      border: 2px solid white;
      border-radius: 2px;
      box-shadow: 0 1px 3px rgba(0,0,0,0.3);
      cursor: ${corner === 'tl' || corner === 'br' ? 'nwse-resize' : 'nesw-resize'};
    `
    updateHandlePos(handle, imgEl, corner)
    handle.addEventListener('mousedown', (e) => startImageResize(e, corner))
    document.body.appendChild(handle)
  })
}

// 根据图片视口位置更新手柄坐标
function updateHandlePos(handle, imgEl, corner) {
  const rect = imgEl.getBoundingClientRect()
  let top, left
  if (corner.includes('t')) top = rect.top - 5
  else top = rect.bottom - 5
  if (corner.includes('l')) left = rect.left - 5
  else left = rect.right - 5
  handle.style.top = top + 'px'
  handle.style.left = left + 'px'
}

function deselectImage() {
  if (selectedImg.value) {
    selectedImg.value.style.outline = ''
    selectedImg.value.style.outlineOffset = ''
    removeResizeHandles()
    selectedImg.value = null
  }
}

function setImageAlign(align) {
  if (!selectedImg.value) return
  const img = selectedImg.value
  img.style.display = 'block'
  img.style.marginLeft = '0'
  img.style.marginRight = '0'
  if (align === 'center') {
    img.style.marginLeft = 'auto'
    img.style.marginRight = 'auto'
  } else if (align === 'right') {
    img.style.marginLeft = 'auto'
    img.style.marginRight = '0'
  }
  // 同步到笔记内容
  syncRichContent()
}

function syncRichContent() {
  if (activeNote.value && editableDiv.value) {
    activeNote.value.content = editableDiv.value.innerHTML
    activeNote.value._richContent = editableDiv.value.innerHTML
    debounceSave()
  }
}

// 图片拖拽缩放
function startImageResize(e, corner) {
  e.preventDefault()
  e.stopPropagation()
  if (!selectedImg.value) return
  const img = selectedImg.value
  const startX = e.clientX
  const startY = e.clientY
  const origW = img.offsetWidth
  const origH = img.offsetHeight
  const ratio = origW / origH
  const maxW = (editableDiv.value?.offsetWidth || 600) - 20

  const onMove = (me) => {
    let dx = me.clientX - startX
    let dy = me.clientY - startY
    // 取绝对值较大的方向
    const delta = Math.abs(dx) > Math.abs(dy) ? dx : dy
    let newW = origW + (corner.includes('r') ? delta : -delta)
    newW = Math.max(50, Math.min(newW, maxW))
    const newH = Math.round(newW / ratio)
    img.style.width = newW + 'px'
    img.style.height = newH + 'px'
    selectedImgWidth.value = newW
    selectedImgHeight.value = newH
    // 更新工具条和手柄位置
    const rect = img.getBoundingClientRect()
    const editorEl = document.querySelector('.note-editor')
    if (editorEl) {
      const editorRect = editorEl.getBoundingClientRect()
      imgToolbarStyle.value = {
        top: (rect.bottom - editorRect.top + 6) + 'px',
        left: Math.max(0, rect.left - editorRect.left) + 'px'
      }
    }
    // 更新四角手柄位置（fixed 定位，基于视口）
    document.querySelectorAll('body > .img-resize-handle').forEach(h => {
      const cls = h.className
      let newTop, newLeft
      if (cls.includes('tl') || cls.includes('tr')) newTop = rect.top - 5
      else newTop = rect.bottom - 5
      if (cls.includes('tl') || cls.includes('bl')) newLeft = rect.left - 5
      else newLeft = rect.right - 5
      h.style.top = newTop + 'px'
      h.style.left = newLeft + 'px'
    })
  }
  const onUp = () => {
    document.removeEventListener('mousemove', onMove)
    document.removeEventListener('mouseup', onUp)
    syncRichContent()
  }
  document.addEventListener('mousemove', onMove)
  document.addEventListener('mouseup', onUp)
}

function handleImageSelect(e) {
  const file = e.target.files?.[0]
  if (!file || !activeNote.value) return
  const reader = new FileReader()
  reader.onload = (ev) => {
    if (!activeNote.value.images) activeNote.value.images = []
    activeNote.value.images.push(ev.target.result)
    debounceSave()
  }
  reader.readAsDataURL(file)
  e.target.value = '' // 重置，允许重复选同一文件
}

function removeImage(idx) {
  activeNote.value.images.splice(idx, 1)
  debounceSave()
}

// 拖拽图片进编辑区
function onDragOver(e) {
  const hasImage = [...(e.dataTransfer.items || [])].some(item => item.type.startsWith('image/'))
  if (hasImage) isDragOver.value = true
}

function onDragLeave(e) {
  if (!e.currentTarget.contains(e.relatedTarget)) {
    isDragOver.value = false
  }
}

function onDrop(e) {
  isDragOver.value = false
  if (!activeNote.value) return
  const files = [...(e.dataTransfer.files || [])].filter(f => f.type.startsWith('image/'))
  if (!files.length) return

  if (richMode.value && editableDiv.value) {
    // 富文本模式：将图片插入到编辑器光标处
    // 先把焦点给编辑区（拖拽后焦点可能丢失）
    editableDiv.value.focus()
    files.forEach(file => {
      const reader = new FileReader()
      reader.onload = (ev) => {
        const imgHtml = `<img src="${ev.target.result}" style="max-width:100%;border-radius:6px;margin:4px 0;display:block;" />`
        document.execCommand('insertHTML', false, imgHtml)
        if (activeNote.value) {
          activeNote.value.content = editableDiv.value?.innerHTML || ''
          activeNote.value._richContent = editableDiv.value?.innerHTML || ''
          debounceSave()
        }
      }
      reader.readAsDataURL(file)
    })
  } else {
    // Markdown 模式：附件形式
    files.forEach(file => {
      const reader = new FileReader()
      reader.onload = (ev) => {
        if (!activeNote.value.images) activeNote.value.images = []
        activeNote.value.images.push(ev.target.result)
        debounceSave()
      }
      reader.readAsDataURL(file)
    })
  }
}

function importMarkdown() {
  mdFileInput.value?.click()
}

function handleMdImport(e) {
  const file = e.target.files?.[0]
  if (!file || !activeNote.value) { e.target.value = ''; return }
  const reader = new FileReader()
  reader.onload = (ev) => {
    const text = ev.target.result || ''
    // Try to extract title from first # heading
    const titleMatch = text.match(/^#\s+(.+)/m)
    if (titleMatch && !activeNote.value.title) {
      activeNote.value.title = titleMatch[1].trim()
    }
    activeNote.value.content = text
    debounceSave()
  }
  reader.readAsText(file)
  e.target.value = ''
}

async function exportMarkdown() {
  if (!activeNote.value) return
  const title = activeNote.value.title || '笔记'
  let content = activeNote.value.content || ''
  // 如果是富文本模式，先把 HTML 转成纯文本/Markdown
  if (richMode.value && editableDiv.value) {
    content = editableDiv.value.innerText || editableDiv.value.textContent || content
  }
  // Prepend title as H1 if not already present
  if (title && !content.startsWith('# ' + title)) {
    content = `# ${title}\n\n${content}`
  }
  // 使用 Tauri 命令保存文件（弹出原生保存对话框）
  try {
    const { invoke } = await import('@tauri-apps/api/core')
    const result = await invoke('save_markdown_file', { title, content })
    if (result) {
      showToast('已导出: ' + result)
    }
  } catch (e) {
    console.warn('Tauri save failed, fallback to clipboard:', e)
    // 回退：复制到剪贴板
    try {
      await navigator.clipboard.writeText(content)
      showToast('已复制 Markdown 到剪贴板')
    } catch (e2) {
      console.warn('Clipboard copy failed:', e2)
    }
  }
}

function debounceSave() {
  saveStatus.value = 'saving'
  clearTimeout(saveTimer)
  saveTimer = setTimeout(() => { saveData(); saveStatus.value = 'saved' }, 800)
}

function saveData() {
  writeJSON(NOTES_KEY, notebooks.value)
}

function loadData() {
  // 迁移旧数据：从 sn-notes 迁移到 sn-notebooks
  const oldRaw = localStorage.getItem('sn-notes')
  if (oldRaw && !localStorage.getItem(NOTES_KEY)) {
    try {
      const oldNotes = JSON.parse(oldRaw)
      oldNotes.forEach(n => { if (!n.color) n.color = NOTE_COLORS[Math.floor(Math.random() * NOTE_COLORS.length)] })
      notebooks.value = [{ id: Date.now(), name: '记事本 1', notes: oldNotes }]
      writeJSON(NOTES_KEY, notebooks.value)
      localStorage.removeItem('sn-notes')
    } catch {}
  }

  const data = readJSON(NOTES_KEY, null)
  if (data) {
    notebooks.value = data
    // 兼容：确保每个 notebook 有 notes 数组
    notebooks.value.forEach(b => { if (!b.notes) b.notes = [] })
  }

  if (!notebooks.value.length) {
    const book = { id: Date.now(), name: '记事本 1', notes: [] }
    notebooks.value.push(book)
  }

  // 恢复上次打开的笔记本
  const savedBookId = localStorage.getItem('sn-active-book')
  if (savedBookId && notebooks.value.find(b => b.id == savedBookId)) {
    activeBookId.value = Number(savedBookId)
  } else {
    activeBookId.value = notebooks.value[0].id
  }

  if (notes.value.length) activeNoteId.value = notes.value[0].id

  // 初始化富文本编辑区
  nextTick(() => {
    if (richMode.value && editableDiv.value && activeNote.value) {
      editableDiv.value.innerHTML = activeNote.value._richContent || activeNote.value.content || ''
    }
  })

  // 确保默认是富文本模式（如果没有显式启用 Markdown）
  if (localStorage.getItem('sn-markdown-mode') !== '1') {
    richMode.value = true
    markdownMode.value = false
  }
}

// 监听笔记切换，同步富文本编辑区
watch(activeNoteId, () => {
  if (!richMode.value || !editableDiv.value) return
  nextTick(() => {
    if (activeNote.value) {
      editableDiv.value.innerHTML = activeNote.value._richContent || activeNote.value.content || ''
    } else {
      editableDiv.value.innerHTML = ''
    }
  })
})

// 监听笔记本切换，自动选中第一个笔记
watch(activeBookId, () => {
  activeNoteId.value = notes.value.length ? notes.value[0].id : null
  localStorage.setItem('sn-active-book', activeBookId.value)
})

// 监听富文本模式切换
watch(richMode, (val) => {
  if (!activeNote.value) return
  if (val) {
    // 切换到富文本：恢复之前保存的 HTML 内容
    nextTick(() => {
      restoreRichContent()
    })
  } else {
    // 切换到 Markdown：先保存富文本 HTML，再提取纯文本
    saveRichContent()
    if (editableDiv.value?.innerHTML) {
      const plain = editableDiv.value.innerText || editableDiv.value.textContent || ''
      activeNote.value.content = plain
      debounceSave()
    }
  }
})

// Markdown 模式状态持久化
watch(markdownMode, (val) => {
  localStorage.setItem('sn-markdown-mode', val ? '1' : '0')
})

// 侧边栏显隐状态持久化
watch(sidebarVisible, (val) => {
  localStorage.setItem('sn-sidebar-visible', val ? '1' : '0')
})

// 列表类型状态
const listType = ref(null)
const showListDropdown = ref(false)

// 极简模式监听
const minimalMode = ref(localStorage.getItem('sn-minimal-mode') === '1')
window.addEventListener('minimal-mode-change', (e) => {
  minimalMode.value = !!e.detail
})

const _noteListeners = {
  switchNotebook: null,
  addNotebook: null,
  deleteNotebook: null,
  notebooksUpdated: null
}

onMounted(() => {
  loadData()
  if (localStorage.getItem('sn-markdown-mode') === '1') {
    markdownMode.value = true
  }
  document.addEventListener('click', (e) => {
    if (showBookMenu.value) showBookMenu.value = false
    if (showColorPicker.value) showColorPicker.value = false
    if (noteCtxMenu.value.visible) closeNoteCtxMenu()
    if (showListDropdown.value) showListDropdown.value = false
    if (showScreenshotMenu.value) {
      const wrap = document.querySelector('.screenshot-btn-wrap')
      if (wrap && !wrap.contains(e.target)) showScreenshotMenu.value = false
    }
    // 点击图片选中 / 点击其他取消选中
    if (richMode.value && editableDiv.value) {
      if (e.target.tagName === 'IMG' && editableDiv.value.contains(e.target)) {
        selectImage(e.target)
      } else if (selectedImg.value && !e.target.closest('.img-resize-toolbar')) {
        deselectImage()
      }
    }
  })

  // 注册截图快捷键
  registerScreenshotHotkey()

  // 监听 App.vue 的事件（保存引用以便卸载时清理）
  _noteListeners.switchNotebook = (e) => {
    const id = Number(e.detail)
    // 先确保本地状态与 localStorage 同步，防止数据不一致导致静默失败
    if (!notebooks.value.find(b => b.id === id)) {
      loadData()
    }
    if (notebooks.value.find(b => b.id === id)) {
      switchBook(id)
    }
  }
  _noteListeners.addNotebook = () => { addNotebook() }
  _noteListeners.deleteNotebook = (e) => {
    const id = Number(e.detail)
    deleteBook(id)
  }
  _noteListeners.notebooksUpdated = () => { loadData() }

  window.addEventListener('switch-notebook', _noteListeners.switchNotebook)
  window.addEventListener('add-notebook', _noteListeners.addNotebook)
  window.addEventListener('delete-notebook', _noteListeners.deleteNotebook)
  window.addEventListener('notebooks-updated', _noteListeners.notebooksUpdated)

  // 切换到记事本时，滚动文本编辑器到底部（最近编辑位置）
  nextTick(() => {
    const el = noteEditorEl.value
    if (el) el.scrollTop = el.scrollHeight
  })
})

onUnmounted(() => {
  window.removeEventListener('switch-notebook', _noteListeners.switchNotebook)
  window.removeEventListener('add-notebook', _noteListeners.addNotebook)
  window.removeEventListener('delete-notebook', _noteListeners.deleteNotebook)
  window.removeEventListener('notebooks-updated', _noteListeners.notebooksUpdated)
})

// 暴露方法给父组件 App.vue 直接调用（替代 CustomEvent，消灭竞态）
defineExpose({
  switchToBook(id) { switchBook(id) },
  addNotebook() { addNotebook() },
  deleteNotebook(id) { deleteBook(id) },
  reload() { loadData() }
})
</script>

<style scoped>
.note-panel {
  display: flex;
  flex: 1;
  overflow: hidden;
  position: relative;
}

/* 侧边栏浮动切换按钮：粘在左侧边缘，不占布局空间 */
.sidebar-toggle-float {
  position: absolute;
  left: 0;
  top: 50%;
  transform: translateY(-50%);
  z-index: 10;
  width: 14px;
  height: 40px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: var(--bg-surface);
  border: 0.5px solid var(--border);
  border-left: none;
  border-radius: 0 8px 8px 0;
  cursor: pointer;
  color: var(--text-secondary);
  transition: all 0.2s ease;
  box-shadow: 0 0 0 1px var(--border);
  opacity: 0.7;
}

.sidebar-toggle-float:hover {
  opacity: 1;
  width: 16px;
  background: var(--accent);
  color: #fff;
  border-color: var(--accent);
  box-shadow: 0 2px 8px rgba(0,0,0,0.15), 0 0 0 1px var(--accent);
}

.note-sidebar {
  width: 110px;
  flex-shrink: 0;
  border-right: 0.5px solid var(--border);
  display: flex;
  flex-direction: column;
  background: var(--bg-surface);
}

/* sidebar-header: 只含新建按钮 */
.sidebar-header {
  display: flex;
  align-items: center;
  padding: 8px 6px;
  border-bottom: 0.5px solid var(--border);
}

.sidebar-title {
  font-size: 11px;
  font-weight: 600;
  color: var(--text-tertiary);
  text-transform: uppercase;
  letter-spacing: 0.06em;
}

/* 笔记本选择器 */
.book-selector {
  display: flex;
  align-items: center;
  gap: 4px;
  cursor: pointer;
  padding: 2px 6px;
  border-radius: 5px;
  transition: background var(--transition);
  flex: 1;
  min-width: 0;
}

.book-selector:hover {
  background: var(--bg-hover);
}

.book-name {
  font-size: 11px;
  font-weight: 600;
  color: var(--text-secondary);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.book-rename-input {
  border: none;
  outline: none;
  background: var(--bg-input);
  border-radius: 3px;
  padding: 1px 4px;
  font-size: 11px;
  font-weight: 600;
  color: var(--text-primary);
  font-family: var(--font);
  width: 80px;
}

.book-menu {
  position: absolute;
  top: 100%;
  left: 4px;
  right: 4px;
  z-index: 100;
  background: var(--bg-surface);
  border: 0.5px solid var(--border);
  border-radius: var(--radius-sm);
  padding: 4px;
  box-shadow: 0 6px 20px rgba(0,0,0,0.16);
  animation: fadeIn 0.12s ease;
}

.book-menu-item {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 6px 8px;
  border-radius: 5px;
  cursor: pointer;
  transition: background var(--transition);
  font-size: 12px;
  color: var(--text-primary);
}

.book-menu-item:hover {
  background: var(--bg-hover);
}

.book-menu-item.active {
  background: var(--accent-light);
  color: var(--accent-text);
}

.book-menu-name {
  flex: 1;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.book-menu-count {
  font-size: 10px;
  color: var(--text-tertiary);
  background: var(--bg-input);
  border-radius: 8px;
  padding: 0 5px;
  line-height: 16px;
}

.book-menu-actions {
  display: flex;
  gap: 2px;
  opacity: 0;
  transition: opacity var(--transition);
}

.book-menu-item:hover .book-menu-actions {
  opacity: 1;
}

.book-action-btn {
  width: 18px;
  height: 18px;
  border: none;
  background: transparent;
  border-radius: 3px;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  color: var(--text-tertiary);
  transition: all var(--transition);
}

.book-action-btn:hover {
  color: var(--text-primary);
  background: var(--bg-active);
}

.book-action-btn.del:hover {
  color: var(--danger);
  background: var(--danger-light);
}

.book-menu-divider {
  height: 1px;
  background: var(--border);
  margin: 4px 0;
}

.book-menu-add {
  display: flex;
  align-items: center;
  gap: 6px;
  width: 100%;
  padding: 6px 8px;
  border: none;
  background: transparent;
  border-radius: 5px;
  cursor: pointer;
  font-size: 12px;
  color: var(--accent);
  transition: background var(--transition);
  font-family: var(--font);
}

.book-menu-add:hover {
  background: var(--accent-light);
}

.add-note-btn {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 5px;
  flex: 1;
  padding: 8px 0;
  border: 1.5px dashed var(--border-strong);
  background: transparent;
  border-radius: var(--radius-sm);
  cursor: pointer;
  color: var(--text-secondary);
  font-size: 12px;
  font-weight: 500;
  font-family: var(--font);
  transition: all var(--transition);
}

.add-note-btn:hover {
  border-color: var(--accent);
  color: var(--accent);
  background: var(--accent-light);
  border-style: solid;
}

.add-note-btn:active {
  transform: scale(0.97);
}

.note-list {
  flex: 1;
  overflow-y: auto;
  padding: 6px 4px;
}

.note-item {
  display: flex;
  align-items: flex-start;
  gap: 6px;
  padding: 10px 12px;
  border-radius: var(--radius-sm);
  cursor: pointer;
  position: relative;
  transition: all var(--transition);
  margin-bottom: 2px;
  min-height: 52px;
  border: 0.5px solid transparent;
}

.note-item:hover {
  background: var(--bg-hover);
  border-color: var(--border);
}
.note-item.active {
  background: var(--accent-light);
  border-color: var(--accent);
  box-shadow: var(--shadow-sm);
}

.note-item-title {
  font-size: 12px;
  font-weight: 500;
  color: var(--text-primary);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  line-height: 1.3;
  margin-bottom: 3px;
}

.note-item-content {
  flex: 1;
  min-width: 0;
}

/* 置顶图标：内联在标题前 */
.note-pin-icon {
  flex-shrink: 0;
  vertical-align: middle;
  opacity: 0.75;
}

/* 笔记右键菜单 */
.note-ctx-menu {
  position: fixed;
  z-index: 500;
  background: var(--bg-surface);
  border: 0.5px solid var(--border);
  border-radius: 8px;
  padding: 4px;
  box-shadow: 0 6px 24px rgba(0,0,0,0.2);
  min-width: auto;
  width: max-content;
  animation: fadeIn 0.1s ease;
}

.note-item-preview {
  font-size: 11px;
  color: var(--text-tertiary);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  line-height: 1.3;
}

.note-del-btn {
  position: absolute;
  top: 4px; right: 4px;
  width: 18px; height: 18px;
  border: none; background: transparent;
  border-radius: 4px; cursor: pointer;
  display: none; align-items: center; justify-content: center;
  color: var(--text-tertiary); transition: all var(--transition);
}

.note-item:hover .note-del-btn { display: flex; }
.note-del-btn:hover { background: var(--danger-light); color: var(--danger); }

.note-editor {
  flex: 1;
  display: flex;
  flex-direction: column;
  position: relative;
  background: var(--bg-app);
}

.editor-header {
  display: flex;
  align-items: center;
  padding: 10px 14px 8px;
  border-bottom: 0.5px solid var(--border);
  gap: 8px;
}

.note-title-input {
  flex: 1;
  min-width: 0;
  border: none; outline: none;
  font-size: 14px; font-weight: 600;
  color: var(--text-primary);
  background: transparent;
  font-family: var(--font);
}

.note-title-input::placeholder { color: var(--text-placeholder); font-weight: 400; }

.editor-actions {
  display: flex;
  gap: 2px;
  flex-shrink: 0;
}

.action-btn {
  width: 26px; height: 26px;
  border: none; background: transparent;
  border-radius: 6px; cursor: pointer;
  display: flex; align-items: center; justify-content: center;
  color: var(--text-tertiary);
  transition: all var(--transition);
}

.action-btn:hover { background: var(--bg-hover); color: var(--text-primary); }

.action-btn.active {
  background: var(--accent-light);
  color: var(--accent);
}

.mode-btn {
  gap: 4px;
  padding: 0 6px;
  width: auto;
}

.mode-label {
  font-size: 10px;
  font-weight: 600;
  opacity: 0;
  max-width: 0;
  overflow: hidden;
  transition: all 0.2s ease;
  white-space: nowrap;
}

.mode-btn.active .mode-label {
  opacity: 1;
  max-width: 40px;
}

.image-list {
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
  padding: 8px 14px;
  border-bottom: 0.5px solid var(--border);
  max-height: 120px;
  overflow-y: auto;
}

.image-item {
  position: relative;
  border-radius: 6px;
  overflow: hidden;
  border: 0.5px solid var(--border);
}

.note-img {
  width: 72px; height: 72px;
  object-fit: cover; display: block;
  cursor: zoom-in;
  transition: opacity 0.15s;
}

.note-img:hover { opacity: 0.85; }

.img-del {
  position: absolute; top: 2px; right: 2px;
  width: 16px; height: 16px;
  background: rgba(0,0,0,0.5); color: #fff;
  border: none; border-radius: 50%;
  font-size: 12px; line-height: 1;
  cursor: pointer; display: flex;
  align-items: center; justify-content: center;
  opacity: 0; transition: opacity 0.15s;
}

.image-item:hover .img-del { opacity: 1; }

/* 富文本工具栏 */
.editor-toolbar {
  display: flex;
  align-items: center;
  gap: 4px;
  padding: 7px 12px;
  border-bottom: 0.5px solid var(--border);
  background: var(--bg-surface);
  flex-shrink: 0;
  flex-wrap: wrap;
}

.tb-btn {
  min-width: 28px;
  height: 28px;
  border: none;
  background: transparent;
  border-radius: 6px;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  color: var(--text-secondary);
  font-size: 12px;
  padding: 0 6px;
  transition: all var(--transition);
  font-family: var(--font);
}

.tb-btn:hover {
  background: var(--bg-hover);
  color: var(--text-primary);
}

.tb-btn.active {
  background: var(--accent-light);
  color: var(--accent-text);
}

.tb-list-dropdown {
  position: relative;
  display: flex;
}

.tb-dropdown-arrow {
  margin-left: 2px;
  opacity: 0.5;
}

.tb-list-dropdown-menu {
  position: absolute;
  top: calc(100% + 4px);
  left: 0;
  z-index: 100;
  background: var(--bg-surface);
  border: 0.5px solid var(--border);
  border-radius: 8px;
  padding: 3px;
  box-shadow: 0 6px 20px rgba(0,0,0,0.15);
  min-width: 110px;
  animation: fadeIn 0.1s ease;
}

.tb-dropdown-item {
  display: flex;
  align-items: center;
  gap: 6px;
  width: 100%;
  padding: 6px 10px;
  border: none;
  background: transparent;
  border-radius: 5px;
  cursor: pointer;
  font-size: 12px;
  color: var(--text-primary);
  font-family: var(--font);
  transition: background 0.15s;
}

.tb-dropdown-item:hover {
  background: var(--bg-hover);
}

.tb-dropdown-item.active {
  background: var(--accent-light);
  color: var(--accent-text);
  font-weight: 600;
}

.tb-sep {
  width: 1px;
  height: 16px;
  background: var(--border-strong);
  margin: 0 2px;
}

.tb-color-btn {
  position: relative;
  overflow: hidden;
}

.tb-color {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  border: none;
  background: transparent;
  cursor: pointer;
  padding: 0;
  opacity: 0;
}

.tb-color::-webkit-color-swatch-wrapper {
  padding: 0;
}

.tb-color::-webkit-color-swatch {
  border: none;
  border-radius: 3px;
}

/* 富文本编辑区 */
.note-content-editable {
  flex: 1;
  border: none;
  outline: none;
  font-size: 13px;
  line-height: 1.75;
  overflow-y: auto;
  color: var(--text-primary);
  background: var(--bg-app);
  padding: 12px 14px;
  font-family: var(--font);
  overflow-y: auto;
  word-break: break-word;
}

/* FIX: 深色模式下确保 contenteditable 子元素继承正确颜色 */
.note-content-editable *:not([style*="color"]) {
  color: inherit;
}

.note-content-editable:empty::before {
  content: '开始记录...';
  color: var(--text-placeholder);
}

.note-content-editable:focus {
  box-shadow: inset 0 0 0 1px var(--accent-light);
}

/* 确保富文本内容的样式 */
.note-content-editable ul, .note-content-editable ol {
  padding-left: 24px;
  margin: 4px 0;
}

.note-content-editable ul li,
.note-content-editable ol li {
  padding-left: 2px;
}

.note-content-editable a {
  color: var(--accent);
  text-decoration: underline;
}

.note-content-editable table {
  border-collapse: collapse;
  width: 100%;
  margin: 8px 0;
}

.note-content-editable th,
.note-content-editable td {
  border: 1px solid var(--border-strong);
  padding: 6px 10px;
  font-size: 12px;
  min-width: 40px;
}

.note-content-editable th {
  background: var(--bg-surface);
  font-weight: 600;
}

.note-content-editable td:focus {
  outline: 2px solid var(--accent);
  outline-offset: -2px;
}

.note-textarea {
  flex: 1;
  border: none; outline: none; resize: none;
  font-size: 13px; line-height: 1.75;
  color: var(--text-primary);
  background: var(--bg-app);
  padding: 12px 14px;
  font-family: var(--font);
}

.note-textarea::placeholder { color: var(--text-placeholder); }

.editor-footer {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 6px 14px;
  border-top: 0.5px solid var(--border);
  background: var(--bg-surface);
}

.char-count { font-size: 11px; color: var(--text-tertiary); }

.save-status {
  font-size: 11px; color: var(--text-tertiary);
  transition: color 0.3s;
}

.save-status.saving { color: var(--warn); }
.save-status.saved { color: var(--success); }

/* 拖拽提示遮罩 */
.note-editor.drag-over {
  outline: 2px dashed var(--accent);
  outline-offset: -2px;
}

.drag-overlay {
  position: absolute;
  inset: 0;
  z-index: 50;
  background: var(--accent-light);
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 10px;
  color: var(--accent-text);
  font-size: 13px;
  font-weight: 500;
  pointer-events: none;
  border-radius: 4px;
}

.drag-overlay svg {
  color: var(--accent);
  opacity: 0.8;
}

.drag-hint-enter-active,
.drag-hint-leave-active {
  transition: opacity 0.15s ease;
}

.drag-hint-enter-from,
.drag-hint-leave-to {
  opacity: 0;
}

.note-empty {
  flex: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 10px;
  color: var(--text-tertiary);
  font-size: 13px;
  background: var(--bg-app);
}

.img-preview-mask {
  position: fixed; inset: 0;
  background: rgba(0,0,0,0.75);
  display: flex; align-items: center; justify-content: center;
  z-index: 1000; cursor: zoom-out;
}

.img-preview-full {
  max-width: 90%; max-height: 90%;
  border-radius: 8px;
  box-shadow: 0 8px 40px rgba(0,0,0,0.5);
}

/* 颜色选择器弹出动画 */
.color-pop-enter-active {
  transition: opacity 0.15s ease, transform 0.15s cubic-bezier(0.16, 1, 0.3, 1);
}
.color-pop-leave-active {
  transition: opacity 0.1s ease, transform 0.1s ease;
}
.color-pop-enter-from {
  opacity: 0;
  transform: translateX(-50%) translateY(-4px) scale(0.95);
}
.color-pop-leave-to {
  opacity: 0;
  transform: translateX(-50%) translateY(-2px) scale(0.97);
}

/* ========== Markdown 模式 ========== */
.markdown-wrap {
  flex: 1;
  display: flex;
  flex-direction: column;
  overflow: hidden;
}

.md-tab-bar {
  display: flex;
  gap: 2px;
  padding: 6px 14px;
  border-bottom: 0.5px solid var(--border);
  background: var(--bg-surface);
}

.md-tab {
  padding: 4px 14px;
  border: none;
  background: transparent;
  border-radius: var(--radius-xs);
  font-size: 12px;
  font-weight: 500;
  color: var(--text-tertiary);
  cursor: pointer;
  transition: all var(--transition);
  font-family: var(--font);
}

.md-tab:hover {
  color: var(--text-primary);
  background: var(--bg-hover);
}

.md-tab.active {
  color: var(--accent);
  background: var(--accent-light);
}

.md-body {
  flex: 1;
  overflow: hidden;
  display: flex;
  flex-direction: column;
}

.md-editor {
  flex: 1;
  font-family: 'Cascadia Code', 'Fira Code', 'SF Mono', 'Consolas', monospace;
  font-size: 13px;
  tab-size: 2;
}

.md-preview {
  flex: 1;
  overflow-y: auto;
  padding: 12px 14px;
  font-size: 13px;
  line-height: 1.75;
  color: var(--text-primary);
  word-break: break-word;
}

/* Markdown 渲染样式 */
.md-preview h1 { font-size: 20px; font-weight: 700; margin: 16px 0 8px; color: var(--text-primary); border-bottom: 1px solid var(--border); padding-bottom: 6px; }
.md-preview h2 { font-size: 17px; font-weight: 700; margin: 14px 0 6px; color: var(--text-primary); }
.md-preview h3 { font-size: 15px; font-weight: 600; margin: 12px 0 4px; color: var(--text-primary); }
.md-preview h4, .md-preview h5, .md-preview h6 { font-size: 14px; font-weight: 600; margin: 10px 0 4px; color: var(--text-primary); }
.md-preview p { margin: 6px 0; }
.md-preview ul, .md-preview ol { padding-left: 22px; margin: 6px 0; }
.md-preview li { margin: 3px 0; }
.md-preview blockquote {
  border-left: 3px solid var(--accent);
  padding: 4px 12px;
  margin: 8px 0;
  background: var(--accent-light);
  border-radius: 0 var(--radius-xs) var(--radius-xs) 0;
  color: var(--text-secondary);
}
.md-preview code {
  font-family: 'Cascadia Code', 'Fira Code', 'Consolas', monospace;
  font-size: 12px;
  background: var(--bg-input);
  padding: 1px 5px;
  border-radius: 3px;
  color: var(--accent-text);
}
.md-preview pre {
  background: var(--bg-input);
  border-radius: var(--radius-xs);
  padding: 10px 12px;
  margin: 8px 0;
  overflow-x: auto;
  border: 0.5px solid var(--border);
}
.md-preview pre code {
  background: transparent;
  padding: 0;
  font-size: 12px;
  color: var(--text-primary);
}
.md-preview a { color: var(--accent); text-decoration: underline; }
.md-preview hr { border: none; border-top: 1px solid var(--border); margin: 12px 0; }
.md-preview img { max-width: 100%; border-radius: 6px; margin: 8px 0; }
.md-preview table { border-collapse: collapse; margin: 8px 0; width: 100%; }
.md-preview th, .md-preview td { border: 1px solid var(--border); padding: 6px 10px; font-size: 12px; }
.md-preview th { background: var(--bg-surface); font-weight: 600; }
.md-preview strong { font-weight: 700; }
.md-preview em { font-style: italic; }
.md-preview del { text-decoration: line-through; color: var(--text-tertiary); }
.md-preview input[type="checkbox"] { margin-right: 6px; }

/* BUG3修复：笔记右键菜单美化样式 */
.ctx-menu-item.pin-item {
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
.ctx-menu-item.pin-item:hover { background: var(--bg-hover); }
.ctx-menu-item.pin-item.pinned { color: var(--accent); }
.ctx-menu-item.pin-item.pinned:hover { background: var(--accent-light); }

.ctx-menu-divider {
  height: 1px;
  background: var(--border);
  margin: 3px 4px;
}

/* 上移/下移按钮行 */
.ctx-move-row {
  display: flex;
  align-items: center;
  gap: 4px;
  padding: 4px 6px;
}

.ctx-move-label {
  font-size: 10px;
  color: var(--text-tertiary);
  font-weight: 500;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  flex: 1;
  text-align: center;
}

.ctx-move-btn {
  width: 28px;
  height: 24px;
  border: none;
  background: var(--bg-input);
  border-radius: 5px;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  color: var(--text-secondary);
  transition: all 0.15s ease;
  padding: 0;
}

.ctx-move-btn:hover:not(:disabled) {
  background: var(--accent-light);
  color: var(--accent);
  transform: scale(1.05);
}

.ctx-move-btn:active:not(:disabled) {
  transform: scale(0.95);
}

.ctx-move-btn:disabled {
  opacity: 0.2;
  cursor: default;
}

/* 颜色选择 v3：圆形色块，两行 */
.ctx-color-row-v2 {
  display: flex;
  gap: 6px;
  padding: 3px 8px;
  flex-wrap: nowrap;
  justify-content: center;
}

.ctx-color-chip {
  width: 20px;
  height: 20px;
  border-radius: 50%;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.15s ease;
  padding: 0;
  border: 2px solid transparent;
  background: var(--chip-color);
  position: relative;
}

.ctx-color-chip:hover {
  transform: scale(1.2);
  box-shadow: 0 2px 8px rgba(0,0,0,0.2);
}

.ctx-color-chip.active {
  border-color: var(--text-primary);
  box-shadow: 0 0 0 2px color-mix(in srgb, var(--chip-color) 30%, transparent);
}

.chip-check {
  position: absolute;
  filter: drop-shadow(0 1px 1px rgba(0,0,0,0.35));
}

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
.ctx-menu-item.danger-trigger:hover { background: var(--danger-light); }

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
.ctx-confirm-cancel:hover { background: var(--bg-hover); }
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
.ctx-confirm-ok:hover { opacity: 0.85; }

/* Toast 提示 */
.panel-toast {
  position: fixed;
  bottom: 50px;
  left: 50%;
  transform: translateX(-50%);
  z-index: 9999;
  background: var(--bg-surface);
  border: 0.5px solid var(--border);
  border-radius: 10px;
  padding: 8px 16px;
  font-size: 12px;
  color: var(--text-primary);
  font-weight: 500;
  box-shadow: 0 6px 20px rgba(0,0,0,0.16);
  backdrop-filter: blur(12px);
  -webkit-backdrop-filter: blur(12px);
  pointer-events: none;
}

.toast-fade-enter-active {
  transition: all 0.2s cubic-bezier(0.34, 1.56, 0.64, 1);
}
.toast-fade-leave-active {
  transition: all 0.15s ease;
}
.toast-fade-enter-from,
.toast-fade-leave-to {
  opacity: 0;
  transform: translateX(-50%) translateY(10px);
}

/* 笔记按钮微交互 */
.note-item {
  transition: all 0.15s ease;
}
.note-item:hover {
  transform: translateX(2px);
}
.editor-btn {
  transition: all 0.15s ease;
}
.editor-btn:hover {
  transform: scale(1.08);
}
.editor-btn:active {
  transform: scale(0.92);
}

/* ===== 截图下拉菜单 ===== */
.screenshot-btn-wrap {
  position: relative;
  display: flex;
  align-items: center;
}

.screenshot-dropdown {
  position: absolute;
  top: calc(100% + 6px);
  right: 0;
  z-index: 200;
  background: var(--bg-surface);
  border: 0.5px solid var(--border);
  border-radius: 10px;
  padding: 4px;
  box-shadow: 0 8px 28px rgba(0,0,0,0.18);
  min-width: 160px;
  animation: fadeIn 0.12s ease;
}

.ss-menu-item {
  display: flex;
  align-items: center;
  gap: 8px;
  width: 100%;
  padding: 8px 12px;
  border: none;
  background: transparent;
  border-radius: 6px;
  cursor: pointer;
  font-size: 12px;
  color: var(--text-primary);
  font-family: var(--font);
  transition: background 0.15s;
}

.ss-menu-item:hover {
  background: var(--bg-hover);
}

.ss-divider {
  height: 1px;
  background: var(--border);
  margin: 3px 4px;
}

.ss-hotkey-row {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 6px 12px;
}

.ss-hotkey-label {
  font-size: 11px;
  color: var(--text-tertiary);
  flex-shrink: 0;
}

.ss-hotkey-input {
  flex: 1;
  min-width: 0;
  border: 0.5px solid var(--border);
  border-radius: 5px;
  padding: 4px 8px;
  font-size: 11px;
  background: var(--bg-input);
  color: var(--text-primary);
  font-family: var(--font);
  outline: none;
  cursor: pointer;
  transition: border-color 0.15s;
}

.ss-hotkey-input:focus {
  border-color: var(--accent);
  box-shadow: 0 0 0 1.5px var(--accent-light);
}

/* ===== 富文本图片工具条 ===== */
.img-resize-toolbar {
  position: absolute;
  z-index: 100;
  background: var(--bg-surface);
  border: 0.5px solid var(--border);
  border-radius: 8px;
  padding: 4px 8px;
  box-shadow: 0 4px 16px rgba(0,0,0,0.15);
  display: flex;
  align-items: center;
  gap: 6px;
  animation: fadeIn 0.12s ease;
}

.img-align-btns {
  display: flex;
  gap: 2px;
}

.img-align-btn {
  width: 26px;
  height: 26px;
  border: none;
  background: transparent;
  border-radius: 5px;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  color: var(--text-secondary);
  transition: all 0.15s;
}

.img-align-btn:hover {
  background: var(--bg-hover);
  color: var(--text-primary);
}

.img-size-info {
  font-size: 10px;
  color: var(--text-tertiary);
  white-space: nowrap;
  padding-left: 4px;
  border-left: 1px solid var(--border);
}

/* 富文本图片光标 */
.note-content-editable img {
  cursor: pointer;
  transition: outline 0.15s;
}

.note-content-editable img:hover {
  outline: 2px solid rgba(74, 158, 255, 0.4) !important;
  outline-offset: 2px;
}

/* 图片缩放手柄 */
.img-resize-handle {
  position: absolute;
  width: 8px;
  height: 8px;
  background: #4a9eff;
  border: 1.5px solid white;
  border-radius: 2px;
  z-index: 101;
  cursor: nwse-resize;
}
.img-resize-handle.tl { top: -4px; left: -4px; cursor: nwse-resize; }
.img-resize-handle.tr { top: -4px; right: -4px; cursor: nesw-resize; }
.img-resize-handle.bl { bottom: -4px; left: -4px; cursor: nesw-resize; }
.img-resize-handle.br { bottom: -4px; right: -4px; cursor: nwse-resize; }

/* ===== Markdown 语法提示 ===== */
.md-hint {
  padding: 4px 14px;
  font-size: 10px;
  color: var(--text-tertiary);
  background: var(--bg-surface);
  border-top: 0.5px solid var(--border);
  opacity: 0.7;
}
</style>
