<template>
  <div class="note-panel">
    <!-- 笔记列表侧栏 -->
    <div class="note-sidebar" v-show="sidebarVisible">
      <div class="sidebar-header">
        <button class="add-note-btn" @click="addNote" :title="$t('note.sidebar.addNewTitle')">
          <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
            <line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/>
          </svg>
          <span>{{ $t('note.sidebar.addNew') }}</span>
        </button>
      </div>

      <div class="note-list">
        <div
          v-for="(note, idx) in displayedNotes"
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
              {{ note.title || $t('note.item.untitled') }}
            </div>
            <div class="note-item-preview">{{ getPreview(note.content) }}</div>
          </div>
          <button class="note-del-btn" @click.stop="deleteNote(note.id)" :title="$t('note.item.deleteTitle')">
            <svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/>
            </svg>
          </button>
        </div>
        <div v-if="displayedNotes.length === 0" class="note-empty-state">
          <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="var(--text-placeholder)" stroke-width="1.5">
            <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/>
            <polyline points="14 2 14 8 20 8"/>
            <line x1="16" y1="13" x2="8" y2="13"/>
            <line x1="16" y1="17" x2="8" y2="17"/>
          </svg>
          <span v-if="searchQuery">{{ $t('note.empty.noMatch') }}</span>
          <span v-else>{{ $t('note.empty.noNotes') }}</span>
        </div>
      </div>
      <!-- 搜索栏，放在底部，更隐蔽 -->
      <div class="sidebar-search" :class="{ active: searchQuery }">
        <input
          class="search-input"
          v-model="searchQuery"
          :placeholder="$t('note.search.placeholder')"
          @input="onSearchInput"
        />
        <svg class="search-icon" width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/>
        </svg>
        <svg v-if="searchQuery" class="search-clear" width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" @click="searchQuery = ''">
          <line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/>
        </svg>
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
            {{ isNotePinned(noteCtxMenu.note) ? $t('note.ctx.unpin') : $t('note.ctx.pin') }}
          </button>
          <div class="ctx-menu-divider"></div>
          <!-- 上移 / 下移（美化版） -->
          <div class="ctx-move-row">
            <button class="ctx-move-btn" @click="moveNoteUp" :disabled="!canMoveNoteUp" :title="$t('note.ctx.moveUpTitle')">
              <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2">
                <polyline points="18 15 12 9 6 15"/>
              </svg>
            </button>
            <span class="ctx-move-label">{{ $t('note.ctx.sortLabel') }}</span>
            <button class="ctx-move-btn" @click="moveNoteDown" :disabled="!canMoveNoteDown" :title="$t('note.ctx.moveDownTitle')">
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
          :placeholder="$t('note.editor.titlePlaceholder')"
          @input="debounceSave"
          maxlength="50"
        />
        <div class="editor-actions">
          <button class="action-btn" :class="{ active: richMode }" @click="toggleRichMode" :title="$t('note.editor.richModeTitle')">
            <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/>
              <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/>
            </svg>
          </button>
          <button class="action-btn" :class="{ active: markdownMode }" @click="toggleMarkdownMode" :title="$t('note.editor.markdownModeTitle')">
            <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <path d="M4 7v10"/><path d="M8 7v10"/><path d="M4 12h4"/><path d="M14 7l3 10 3-10"/>
            </svg>
          </button>
          <div class="screenshot-btn-wrap" @click.stop>
            <button class="action-btn" :class="{ active: showScreenshotMenu }" @click.stop="showScreenshotMenu = !showScreenshotMenu" :title="$t('note.screenshot.title')">
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
                  {{ $t('note.screenshot.direct') }}
                </button>
                <button class="ss-menu-item" @click="startScreenshot('hide')">
                  <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94"/>
                    <line x1="1" y1="1" x2="23" y2="23"/>
                  </svg>
                  {{ $t('note.screenshot.hide') }}
                </button>
                <div class="ss-divider"></div>
                <div class="ss-hotkey-row">
                  <span class="ss-hotkey-label">{{ $t('note.screenshot.hotkeyLabel') }}</span>
                  <input
                    class="ss-hotkey-input"
                    :value="screenshotHotkey"
                    @keydown.prevent="captureHotkey"
                    @blur="saveHotkey"
                    :placeholder="$t('note.screenshot.hotkeyPlaceholder')"
                    readonly
                  />
                </div>
              </div>
            </transition>
          </div>
          <!-- 导入下拉菜单 -->
          <div class="io-btn-wrap" @click.stop>
            <button class="action-btn" :class="{ active: showImportMenu }" @click.stop="showImportMenu = !showImportMenu" :title="$t('note.io.importTitle')">
              <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/>
                <polyline points="7 10 12 15 17 10"/><line x1="12" y1="15" x2="12" y2="3"/>
              </svg>
            </button>
            <transition name="color-pop">
              <div class="io-dropdown" v-if="showImportMenu" @click.stop>
                <button class="io-menu-item" @click="doImport('md')"><span class="io-fmt">.md</span>{{ $t('note.io.markdown') }}</button>
                <button class="io-menu-item" @click="doImport('txt')"><span class="io-fmt">.txt</span>{{ $t('note.io.plainText') }}</button>
                <button class="io-menu-item" @click="doImport('html')"><span class="io-fmt">.html</span>{{ $t('note.io.htmlPage') }}</button>
                <button class="io-menu-item" @click="doImport('docx')"><span class="io-fmt">.docx</span>{{ $t('note.io.wordDoc') }}</button>
              </div>
            </transition>
          </div>
          <!-- 导出下拉菜单 -->
          <div class="io-btn-wrap" @click.stop>
            <button class="action-btn" :class="{ active: showExportMenu }" @click.stop="showExportMenu = !showExportMenu" :title="$t('note.io.exportTitle')">
              <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/>
                <polyline points="17 8 12 3 7 8"/><line x1="12" y1="3" x2="12" y2="15"/>
              </svg>
            </button>
            <transition name="color-pop">
              <div class="io-dropdown" v-if="showExportMenu" @click.stop>
                <button class="io-menu-item" @click="doExport('md')"><span class="io-fmt">.md</span>{{ $t('note.io.markdown') }}</button>
                <button class="io-menu-item" @click="doExport('txt')"><span class="io-fmt">.txt</span>{{ $t('note.io.plainText') }}</button>
                <button class="io-menu-item" @click="doExport('html')"><span class="io-fmt">.html</span>{{ $t('note.io.htmlPage') }}</button>
                <button class="io-menu-item" @click="doExport('docx')"><span class="io-fmt">.docx</span>{{ $t('note.io.wordDoc') }}</button>
                <button class="io-menu-item" @click="doExport('pdf')"><span class="io-fmt">.pdf</span>{{ $t('note.io.pdfDoc') }}</button>
              </div>
            </transition>
          </div>
        </div>
      </div>

    <!-- 富文本工具栏 -->
    <div class="editor-toolbar" v-if="richMode && !minimalMode">
      <!-- 字体大小 -->
      <select class="tb-fontsize-select" @change="applyFontSize($event.target.value); $event.target.value = ''" :title="$t('note.toolbar.fontSizeTitle')">
        <option value="" disabled selected>{{ $t('note.toolbar.fontSizeDefault') }}</option>
        <option value="1">{{ $t('note.toolbar.fontSizeSmall') }}</option>
        <option value="2">{{ $t('note.toolbar.fontSizeMedium') }}</option>
        <option value="3">{{ $t('note.toolbar.fontSizeNormal') }}</option>
        <option value="4">{{ $t('note.toolbar.fontSizeLarge') }}</option>
        <option value="5">{{ $t('note.toolbar.fontSizeXLarge') }}</option>
        <option value="6">{{ $t('note.toolbar.fontSizeXXLarge') }}</option>
        <option value="7">{{ $t('note.toolbar.fontSizeMax') }}</option>
      </select>
      <span class="tb-sep"></span>
      <button class="tb-btn" @click="execCmd('bold')" :title="$t('note.toolbar.boldTitle')"><b>B</b></button>
      <button class="tb-btn" @click="execCmd('italic')" :title="$t('note.toolbar.italicTitle')"><i>I</i></button>
      <button class="tb-btn" @click="execCmd('underline')" :title="$t('note.toolbar.underlineTitle')"><u>U</u></button>
      <button class="tb-btn" @click="execCmd('strikeThrough')" :title="$t('note.toolbar.strikeTitle')"><s>S</s></button>
      <button class="tb-btn" @click="execCmd('removeFormat')" :title="$t('note.toolbar.clearFormatTitle')">
        <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <path d="M4 7h16M6 7l1.5 13h9L18 7"/>
          <line x1="3" y1="20" x2="21" y2="4" stroke-width="2.5"/>
        </svg>
      </button>
      <span class="tb-sep"></span>
      <button class="tb-btn" @click="execCmd('undo')" :title="$t('note.toolbar.undoTitle')">
        <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <polyline points="1 4 1 10 7 10"/>
          <path d="M3.51 15a9 9 0 1 0 2.13-9.36L1 10"/>
        </svg>
      </button>
      <button class="tb-btn" @click="execCmd('redo')" :title="$t('note.toolbar.redoTitle')">
        <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <polyline points="23 4 23 10 17 10"/>
          <path d="M20.49 15a9 9 0 1 1-2.13-9.36L23 10"/>
        </svg>
      </button>
      <span class="tb-sep"></span>
      <div class="tb-list-dropdown" @click.stop>
        <button class="tb-btn" :class="{ active: listType }" @click="showListDropdown = !showListDropdown" :title="$t('note.toolbar.listTitle')">
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
              {{ $t('note.toolbar.unorderedList') }}
            </button>
            <button class="tb-dropdown-item" :class="{ active: listType === 'ol' }" @click="execCmd('insertOrderedList'); listType = listType === 'ol' ? null : 'ol'; showListDropdown = false">
              <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <line x1="10" y1="6" x2="21" y2="6"/><line x1="10" y1="12" x2="21" y2="12"/><line x1="10" y1="18" x2="21" y2="18"/>
                <text x="3" y="8" font-size="7" fill="currentColor" stroke="none" font-family="sans-serif">1</text>
                <text x="3" y="14" font-size="7" fill="currentColor" stroke="none" font-family="sans-serif">2</text>
                <text x="3" y="20" font-size="7" fill="currentColor" stroke="none" font-family="sans-serif">3</text>
              </svg>
              {{ $t('note.toolbar.orderedList') }}
            </button>
          </div>
        </transition>
      </div>
      <span class="tb-sep"></span>
      <button class="tb-btn" @click="insertLink" :title="$t('note.toolbar.insertLinkTitle')">
        <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <path d="M10 13a5 5 0 0 0 7.54.54l3-3a5 5 0 0 0-7.07-7.07l-1.72 1.71"/>
          <path d="M14 11a5 5 0 0 0-7.54-.54l-3 3a5 5 0 0 0 7.07 7.07l1.71-1.71"/>
        </svg>
      </button>
      <label class="tb-btn tb-color-btn" :title="$t('note.toolbar.fontColorTitle')">
        <input type="color" class="tb-color" @change="execCmd('foreColor', $event.target.value)" />
        <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <path d="M12 2L2 22h20L12 2z"/>
          <line x1="7" y1="16" x2="17" y2="16"/>
        </svg>
      </label>
      <button class="tb-btn" @click="insertImageToEditor" :title="$t('note.toolbar.insertImageTitle')">
        <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <rect x="3" y="3" width="18" height="18" rx="2"/>
          <circle cx="8.5" cy="8.5" r="1.5"/>
          <polyline points="21 15 16 10 5 21"/>
        </svg>
      </button>
      <button class="tb-btn" @click="insertTable" :title="$t('note.toolbar.insertTableTitle')">
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
      :style="{ '--editor-placeholder': `'${$t('note.editor.startTyping')}'` }"
      contenteditable="true"
      @input="onRichInput"
      @paste="onPaste"
      @compositionstart="isComposing = true"
      @compositionend="isComposing = false; onRichInput()"
      @keydown.ctrl.b.prevent="execCmd('bold')"
      @keydown.ctrl.i.prevent="execCmd('italic')"
      @keydown.ctrl.u.prevent="execCmd('underline')"
      @keydown.ctrl.shift.v.prevent="pastePlainText"
      @dragover.prevent="onDragOver"
      @drop.prevent="onDrop"
    ></div>

    <!-- Markdown 模式 -->
    <div v-else class="markdown-wrap">
      <div class="md-tab-bar">
        <button class="md-tab" :class="{ active: !markdownPreview }" @click="markdownPreview = false">{{ $t('note.markdown.tabEdit') }}</button>
        <button class="md-tab" :class="{ active: markdownPreview }" @click="markdownPreview = true">{{ $t('note.markdown.tabPreview') }}</button>
      </div>
      <div class="md-body">
        <textarea
          ref="noteEditorEl"
          v-show="!markdownPreview"
          class="note-textarea selectable md-editor"
          v-model="activeNote.content"
          :placeholder="$t('note.markdown.placeholder')"
          @input="debounceSave"
          spellcheck="false"
        ></textarea>
        <div v-if="markdownPreview" class="md-preview selectable" v-html="markdownHtml"></div>
      </div>
      <div class="md-hint" v-if="!markdownPreview">
        {{ $t('note.markdown.imageHint') }}
      </div>
    </div>

      <div class="editor-footer">
        <span class="char-count" :title="$t('note.footer.statsTitle')">
          {{ stats.chars }} {{ $t('note.footer.charUnit') }} / {{ stats.words }} {{ $t('note.footer.wordUnit') }} / {{ stats.lines }} {{ $t('note.footer.lineUnit') }} · {{ $t('note.footer.readTimePrefix') }} {{ stats.readTime }}
        </span>
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
          <span>{{ $t('note.drag.releaseToInsert') }}</span>
        </div>
      </transition>
    </div>

    <div class="note-empty" v-else>
      <svg width="36" height="36" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" style="opacity:0.25">
        <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/>
        <polyline points="14 2 14 8 20 8"/>
      </svg>
      <p>{{ $t('note.empty.clickToAdd') }}</p>
    </div>

    <!-- 隐藏的文件选择器 -->
    <input
      ref="fileInput"
      type="file"
      accept="image/*"
      style="display:none"
      @change="handleImageSelect"
    />

    <!-- 隐藏的文件导入选择器 -->
    <input
      ref="importFileInput"
      type="file"
      accept=".md,.markdown,.txt,.html,.htm"
      style="display:none"
      @change="handleFileImport"
    />
    <input
      ref="importDocxInput"
      type="file"
      accept=".docx"
      style="display:none"
      @change="handleDocxImport"
    />

    <!-- 图片预览 -->
    <div class="img-preview-mask" v-if="previewImg" @click="previewImg = null">
      <img :src="previewImg" class="img-preview-full" />
    </div>

    <!-- Toast 提示 -->
    <transition name="toast-fade">
      <div class="panel-toast" v-if="toast.show">{{ toast.message }}</div>
    </transition>

    <!-- 截图窗口由 Rust 后端独立创建，不在主窗口内渲染 -->

    <!-- 富文本图片工具条 -->
    <div class="img-resize-toolbar" v-if="selectedImg" :style="imgToolbarStyle">
      <div class="img-align-btns">
        <button class="img-align-btn" @click="setImageAlign('left')" :title="$t('note.image.alignLeftTitle')">
          <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <line x1="3" y1="6" x2="21" y2="6"/><rect x="3" y="10" width="12" height="8" rx="1"/>
          </svg>
        </button>
        <button class="img-align-btn" @click="setImageAlign('center')" :title="$t('note.image.alignCenterTitle')">
          <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <line x1="3" y1="6" x2="21" y2="6"/><rect x="6" y="10" width="12" height="8" rx="1"/>
          </svg>
        </button>
        <button class="img-align-btn" @click="setImageAlign('right')" :title="$t('note.image.alignRightTitle')">
          <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <line x1="3" y1="6" x2="21" y2="6"/><rect x="9" y="10" width="12" height="8" rx="1"/>
          </svg>
        </button>
      </div>
      <span class="img-size-info">{{ selectedImgWidth }}×{{ selectedImgHeight }}</span>
    </div>

    <!-- 侧边栏浮动切换按钮：粘在左侧边缘，不占布局空间 -->
    <div class="sidebar-toggle-float" @click="sidebarVisible = !sidebarVisible" :title="sidebarVisible ? $t('note.sidebar.hideTitle') : $t('note.sidebar.showTitle')">
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
import { useI18n } from 'vue-i18n'
import { marked } from 'marked'
// docx 和 mammoth 体积大（~6MB 源码），改为动态导入，只在导出/导入 Word 时加载
// 截图窗口由 Rust 后端独立创建，主窗口不再导入 ScreenshotOverlay
import { getCurrentWebviewWindow } from '@tauri-apps/api/webviewWindow'
import { invoke } from '@tauri-apps/api/core'
import { readJSON, writeJSON } from '../utils/storage.js'
import { addItemToTrash } from '../utils/trash.js'
import { NOTE_COLORS } from '../utils/colors.js'
import { generateId } from '../utils/id.js'
import { useToast } from '../composables/useToast.js'
import { useContextMenu } from '../composables/useContextMenu.js'

const { t } = useI18n()

const NOTES_KEY = 'sn-notebooks'

const notebooks = ref([])
const activeBookId = ref(null)
const saveStatus = ref('saved')
const previewImg = ref(null)
const fileInput = ref(null)
const importFileInput = ref(null)
const importDocxInput = ref(null)
const showImportMenu = ref(false)
const showExportMenu = ref(false)
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
const isComposing = ref(false) // 跟踪 IME 输入法组合状态
const noteColors = NOTE_COLORS

// 截图相关
const showScreenshotMenu = ref(false)
const screenshotHotkey = ref(localStorage.getItem('sn-screenshot-hotkey') || 'CommandOrControl+Shift+A')
// 截图窗口由 Rust 后端独立创建，主窗口不再维护截图覆盖层状态
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

// 搜索关键词
const searchQuery = ref('')

// 显示笔记列表：置顶在前，其余按创建时间倒序，支持搜索过滤
const displayedNotes = computed(() => {
  const sorted = [...notes.value].sort((a, b) => {
    if (a.pinned && !b.pinned) return -1
    if (!a.pinned && b.pinned) return 1
    return (b.createdAt || 0) - (a.createdAt || 0)
  })
  const q = searchQuery.value.trim().toLowerCase()
  if (!q) return sorted
  return sorted.filter(n => {
    const title = (n.title || '').toLowerCase()
    if (title.includes(q)) return true
    const content = (n.content || '').toLowerCase().replace(/<[^>]+>/g, '')
    return content.includes(q)
  })
})

const activeNoteId = ref(null)
const activeNote = computed(() => displayedNotes.value.find(n => n.id === activeNoteId.value) || null)
const stats = computed(() => {
  if (!activeNote.value) return { chars: 0, words: 0, lines: 0, readTime: t('note.readTime.zero') }
  const content = activeNote.value.content || ''
  // 去除 HTML 标签后的纯文本
  const plain = content.replace(/<[^>]+>/g, '').replace(/&nbsp;/g, ' ')
  const chars = plain.length
  // 中文字符 + 英文单词数
  const cnChars = (plain.match(/[\u4e00-\u9fa5]/g) || []).length
  const enWords = (plain.match(/[a-zA-Z]+/g) || []).length
  const words = cnChars + enWords
  const lines = plain.split('\n').length
  // 阅读时长：按每分钟 300 字计算
  const mins = Math.max(1, Math.ceil(words / 300))
  const readTime = mins < 60 ? t('note.readTime.minute', { n: mins }) : t('note.readTime.hourMinute', { h: Math.floor(mins/60), m: mins%60 })
  return { chars, words, lines, readTime }
})

const saveStatusText = computed(() => saveStatus.value === 'saving' ? t('note.save.saving') : t('note.save.saved'))
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
  const book = { id: Date.now(), name: t('note.book.defaultName', { n: notebooks.value.length + 1 }), notes: [] }
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
  if (!book.name.trim()) book.name = t('common.unnamed')
  editingBookId.value = null
  saveData()
}

// 模式互斥：只有富文本和 Markdown 两种模式
function toggleRichMode() {
  richMode.value = true
  markdownMode.value = false
  markdownPreview.value = false
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
  if (!content) return t('note.preview.empty')
  // 去除 HTML 标签后截取预览
  const plain = content.replace(/<[^>]+>/g, ' ').replace(/\s+/g, ' ').trim()
  return plain.slice(0, 30) || t('note.preview.empty')
}

// --- 富文本编辑功能 ---
function execCmd(command, value = null) {
  document.execCommand(command, false, value)
  editableDiv.value?.focus()
}

function applyFontSize(size) {
  if (!size) return
  document.execCommand('fontSize', false, size)
  editableDiv.value?.focus()
}

function insertLink() {
  const url = prompt(t('note.link.promptUrl'))
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

// 清理从外部粘贴的 HTML——移除所有行内样式、class、id、事件属性，保留基础结构
function sanitizePastedHtml(html) {
  const doc = new DOMParser().parseFromString(html, 'text/html')
  const allowedTags = new Set([
    'p','br','div','b','strong','i','em','u','s','strike','del',
    'a','ul','ol','li','h1','h2','h3','h4','h5','h6',
    'img','table','tr','td','th','thead','tbody',
    'pre','code','blockquote','hr','span','sub','sup'
  ])
  // querySelectorAll 返回静态 NodeList，循环中修改 DOM 安全
  const all = doc.body.querySelectorAll('*')
  all.forEach(el => {
    const tag = el.tagName.toLowerCase()
    if (!allowedTags.has(tag)) {
      // 替换不允许的标签为其子节点（如 font、meta 等）
      el.replaceWith(...el.childNodes)
      return
    }
    // 移除所有干扰属性
    el.removeAttribute('style')
    el.removeAttribute('class')
    el.removeAttribute('id')
    Array.from(el.attributes).forEach(attr => {
      const n = attr.name
      if (n.startsWith('data-') || n.startsWith('on') || n === 'face' || n === 'size' || n === 'color') {
        el.removeAttribute(n)
      }
    })
    // 特定标签保留必要属性
    if (tag === 'a') {
      const href = el.getAttribute('href')
      Array.from(el.attributes).forEach(attr => { if (attr.name !== 'href') el.removeAttribute(attr.name) })
    } else if (tag === 'img') {
      const src = el.getAttribute('src'), alt = el.getAttribute('alt')
      Array.from(el.attributes).forEach(attr => {
        if (attr.name !== 'src' && attr.name !== 'alt') el.removeAttribute(attr.name)
      })
    }
  })
  return doc.body.innerHTML
}

// 粘贴处理——支持截图粘贴 + 外部网页内容清理
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
  // 清理 HTML 粘贴（来自网页复制等）
  const html = e.clipboardData?.getData('text/html')
  if (html) {
    e.preventDefault()
    const cleaned = sanitizePastedHtml(html)
    if (cleaned.trim()) {
      document.execCommand('insertHTML', false, cleaned)
    } else {
      const text = e.clipboardData?.getData('text/plain')
      if (text) document.execCommand('insertText', false, text)
    }
    if (activeNote.value) {
      activeNote.value.content = editableDiv.value?.innerHTML || ''
      activeNote.value._richContent = editableDiv.value?.innerHTML || ''
      debounceSave()
    }
    return
  }
  // 纯文本由浏览器默认处理
}

function insertTable() {
  // 插入 3x3 表格
  const rows = 3, cols = 3
  let html = '<table style="border-collapse:collapse;width:100%;margin:8px 0;">'
  for (let r = 0; r < rows; r++) {
    html += '<tr>'
    for (let c = 0; c < cols; c++) {
      const tag = r === 0 ? 'th' : 'td'
      html += `<${tag} style="border:1px solid var(--border-strong);padding:6px 10px;font-size:12px;${r === 0 ? 'background:var(--bg-surface);font-weight:600;' : ''}">${r === 0 ? t('note.table.headerCell') : ''}</${tag}>`
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
  const now = Date.now()
  const note = { id: generateId(), title: '', content: '', images: [], color, createdAt: now, updatedAt: now }
  // 插入到置顶笔记之后，而不是最前面
  const pinCount = activeBook.value.notes.filter(n => n.pinned).length
  activeBook.value.notes.splice(pinCount, 0, note)
  activeNoteId.value = note.id
  saveData()
}

function onSearchInput() {
  // 搜索过滤由 displayedNotes computed 自动处理，此处仅占位（v-model 已绑定）
}

function pastePlainText() {
  if (!editableDiv.value) return
  navigator.clipboard.readText().then(text => {
    if (text) {
      document.execCommand('insertText', false, text)
      if (activeNote.value) {
        activeNote.value.content = editableDiv.value.innerHTML
        activeNote.value._richContent = editableDiv.value.innerHTML
        debounceSave()
      }
    }
  }).catch(() => {})
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
// 截图窗口由 Rust 后端独立创建（非透明、无边框、全屏、置顶）
// 主窗口只需要：隐藏自己 → 调用 capture_screen → Rust 自动创建截图窗口并恢复主窗口

async function startScreenshot(mode) {
  showScreenshotMenu.value = false
  _lastScreenshotMode = mode
  const win = getCurrentWebviewWindow()

  // 隐藏后截图：先隐藏主窗口，等待 DWM 刷新
  if (mode === 'hide') {
    try {
      await win.hide()
      await new Promise(r => setTimeout(r, 300))
    } catch (e) {
      console.warn('隐藏窗口失败:', e)
    }
  }

  // 截图（Rust 后端会自动创建独立的截图全屏窗口）
  try {
    await invoke('capture_screen')
  } catch (e) {
    const err = typeof e === 'string' ? e : (e?.message || t('common.unknownError'))
    console.error('截图失败:', err)
    showToast(t('note.toast.screenshotFailed', { error: err }))
    // 截图失败时恢复主窗口
    if (mode === 'hide') {
      try { await win.show(); await win.setFocus() } catch {}
    }
  }
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

// 拖拽文件进编辑区
function onDragOver(e) {
  const hasFiles = (e.dataTransfer.items || []).length > 0
  if (hasFiles) {
    e.dataTransfer.dropEffect = 'copy'
    isDragOver.value = true
  }
}

function onDragLeave(e) {
  if (!e.currentTarget.contains(e.relatedTarget)) {
    isDragOver.value = false
  }
}

function onDrop(e) {
  isDragOver.value = false
  if (!activeNote.value) return
  const files = [...(e.dataTransfer.files || [])]
  if (!files.length) return

  const imgFiles = files.filter(f => f.type.startsWith('image/'))
  const textFiles = files.filter(f => f.type.startsWith('text/') || !f.type)
  const total = files.length

  if (imgFiles.length) {
    if (richMode.value && editableDiv.value) {
      editableDiv.value.focus()
      imgFiles.forEach(file => {
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
      imgFiles.forEach(file => {
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

  if (textFiles.length) {
    textFiles.forEach(file => {
      const reader = new FileReader()
      reader.onload = (ev) => {
        const text = ev.target.result
        if (richMode.value && editableDiv.value) {
          editableDiv.value.focus()
          document.execCommand('insertText', false, text)
          activeNote.value.content = editableDiv.value?.innerHTML || ''
          activeNote.value._richContent = editableDiv.value?.innerHTML || ''
        } else {
          activeNote.value.content = (activeNote.value.content || '') + text
        }
        debounceSave()
      }
      reader.readAsText(file)
    })
  }

  showToast(t('note.toast.importedFiles', { count: total }))
}

function importMarkdown() {
  importFileInput.value?.click()
}

// ========== 导入功能 ==========
let _pendingImportFormat = 'md'

function doImport(fmt) {
  showImportMenu.value = false
  _pendingImportFormat = fmt
  if (fmt === 'docx') {
    importDocxInput.value?.click()
  } else {
    importFileInput.value?.click()
  }
}

function handleFileImport(e) {
  const file = e.target.files?.[0]
  if (!file || !activeNote.value) { e.target.value = ''; return }
  showToast(t('note.toast.importing'))
  const reader = new FileReader()
  reader.onload = (ev) => {
    const text = ev.target.result || ''
    const fmt = _pendingImportFormat

    if (fmt === 'html' || file.name.endsWith('.html') || file.name.endsWith('.htm')) {
      // HTML 导入：用 DOMParser 提取 body 内容
      const parser = new DOMParser()
      const doc = parser.parseFromString(text, 'text/html')
      const bodyHtml = doc.body?.innerHTML || text
      // 提取标题
      const h1 = doc.querySelector('h1')
      if (h1 && !activeNote.value.title) {
        activeNote.value.title = h1.textContent.trim()
      }
      if (richMode.value && editableDiv.value) {
        editableDiv.value.innerHTML = bodyHtml
        activeNote.value.content = editableDiv.value.innerText
        activeNote.value._richContent = bodyHtml
      } else {
        activeNote.value.content = doc.body?.innerText || text
      }
    } else {
      // Markdown / 纯文本导入
      const titleMatch = text.match(/^#\s+(.+)/m)
      if (titleMatch && !activeNote.value.title) {
        activeNote.value.title = titleMatch[1].trim()
      }
      activeNote.value.content = text
    }
    debounceSave()
    showToast(t('note.toast.importedFile'))
  }
  reader.readAsText(file)
  e.target.value = ''
}

async function handleDocxImport(e) {
  const file = e.target.files?.[0]
  if (!file || !activeNote.value) { e.target.value = ''; return }
  showToast(t('note.toast.importing'))
  try {
    const mammoth = await import('mammoth')
    const arrayBuffer = await file.arrayBuffer()
    const result = await mammoth.default.convertToHtml({ arrayBuffer })
    const html = result.value
    // 提取标题
    const parser = new DOMParser()
    const doc = parser.parseFromString(html, 'text/html')
    const h1 = doc.querySelector('h1')
    if (h1 && !activeNote.value.title) {
      activeNote.value.title = h1.textContent.trim()
    }
    if (richMode.value && editableDiv.value) {
      editableDiv.value.innerHTML = html
      activeNote.value.content = editableDiv.value.innerText
      activeNote.value._richContent = html
    } else {
      activeNote.value.content = doc.body?.innerText || html
    }
    debounceSave()
    showToast(t('note.toast.importedWord'))
  } catch (err) {
    console.error('DOCX import error:', err)
    showToast(t('note.toast.importWordFailed'))
  }
  e.target.value = ''
}

// ========== 导出功能 ==========
function getNotePlainText() {
  if (!activeNote.value) return ''
  if (richMode.value && editableDiv.value) {
    return editableDiv.value.innerText || editableDiv.value.textContent || activeNote.value.content || ''
  }
  return activeNote.value.content || ''
}

function getNoteHtmlContent() {
  if (!activeNote.value) return ''
  if (richMode.value && editableDiv.value) {
    return editableDiv.value.innerHTML || ''
  }
  // Markdown 模式：用 marked 渲染为 HTML
  try {
    return marked.parse(activeNote.value.content || '', { breaks: true, gfm: true })
  } catch {
    return activeNote.value.content || ''
  }
}

function wrapHtmlTemplate(title, bodyHtml) {
  return `<!DOCTYPE html>
<html lang="zh-CN">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>${title}</title>
<style>
  body { font-family: -apple-system, 'PingFang SC', 'Microsoft YaHei', sans-serif; max-width: 800px; margin: 40px auto; padding: 0 20px; line-height: 1.7; color: #333; }
  h1 { border-bottom: 2px solid #eee; padding-bottom: 8px; }
  img { max-width: 100%; border-radius: 6px; }
  table { border-collapse: collapse; width: 100%; }
  th, td { border: 1px solid #ddd; padding: 8px 12px; text-align: left; }
  th { background: #f5f5f5; }
  code { background: #f4f4f4; padding: 2px 6px; border-radius: 3px; font-size: 0.9em; }
  pre { background: #f4f4f4; padding: 16px; border-radius: 6px; overflow-x: auto; }
  blockquote { border-left: 3px solid #ddd; margin-left: 0; padding-left: 16px; color: #666; }
</style>
</head>
<body>
<h1>${title}</h1>
${bodyHtml}
</body>
</html>`
}

// docx 动态导入，只在导出 Word 时加载
async function htmlToDocxParagraphs(html, docx) {
  const { Paragraph, TextRun, HeadingLevel, TableRow, TableCell, Table: DocxTable, WidthType } = docx
  const container = document.createElement('div')
  container.innerHTML = html
  const result = []

  function nodeToRuns(node) {
    if (node.nodeType === Node.TEXT_NODE) {
      const text = node.textContent
      if (!text) return []
      return [new TextRun({ text })]
    }
    if (node.nodeType !== Node.ELEMENT_NODE) return []

    const el = node
    const childRuns = []
    for (const child of el.childNodes) {
      childRuns.push(...nodeToRuns(child))
    }
    if (childRuns.length === 0) return []

    const opts = {}
    if (el.tagName === 'STRONG' || el.tagName === 'B') opts.bold = true
    if (el.tagName === 'EM' || el.tagName === 'I') opts.italics = true
    if (el.tagName === 'U') opts.underline = {}
    if (el.tagName === 'S' || el.tagName === 'STRIKE' || el.tagName === 'DEL') opts.strike = true
    if (el.tagName === 'CODE') opts.font = 'Courier New'

    if (Object.keys(opts).length > 0) {
      return childRuns.map(r => {
        const props = { ...r.options, ...opts }
        return new TextRun(props)
      })
    }
    return childRuns
  }

  function processBlock(el) {
    if (el.nodeType === Node.TEXT_NODE) {
      const text = el.textContent.trim()
      if (text) result.push(new Paragraph({ children: [new TextRun({ text })] }))
      return
    }
    if (el.nodeType !== Node.ELEMENT_NODE) return

    const tag = el.tagName
    if (/^H[1-6]$/.test(tag)) {
      const level = parseInt(tag[1])
      result.push(new Paragraph({
        text: el.textContent,
        heading: [HeadingLevel.HEADING_1, HeadingLevel.HEADING_2, HeadingLevel.HEADING_3,
                  HeadingLevel.HEADING_4, HeadingLevel.HEADING_5, HeadingLevel.HEADING_6][level - 1],
      }))
    } else if (tag === 'P' || tag === 'DIV') {
      const runs = nodeToRuns(el)
      if (runs.length > 0) result.push(new Paragraph({ children: runs }))
    } else if (tag === 'LI') {
      result.push(new Paragraph({
        children: [new TextRun({ text: el.textContent })],
        bullet: { level: 0 },
      }))
    } else if (tag === 'UL' || tag === 'OL') {
      for (const li of el.children) processBlock(li)
    } else if (tag === 'BR') {
      result.push(new Paragraph({ children: [new TextRun({ text: '', break: 1 })] }))
    } else if (tag === 'TABLE') {
      const rows = []
      for (const tr of el.querySelectorAll('tr')) {
        const cells = []
        for (const td of tr.querySelectorAll('th,td')) {
          cells.push(new TableCell({
            children: [new Paragraph({ children: [new TextRun({ text: td.textContent })] })],
          }))
        }
        if (cells.length > 0) rows.push(new TableRow({ children: cells }))
      }
      if (rows.length > 0) {
        result.push(new DocxTable({ rows, width: { size: 100, type: WidthType.PERCENTAGE } }))
      }
    } else if (tag === 'BLOCKQUOTE') {
      result.push(new Paragraph({
        children: [new TextRun({ text: el.textContent, italics: true })],
        indent: { left: 720 },
      }))
    } else if (tag === 'PRE') {
      const lines = el.textContent.split('\n')
      for (const line of lines) {
        result.push(new Paragraph({ children: [new TextRun({ text: line || ' ', font: 'Courier New' })] }))
      }
    } else if (tag === 'HR') {
      result.push(new Paragraph({ children: [new TextRun({ text: '─'.repeat(50), color: 'AAAAAA' })] }))
    } else {
      for (const child of el.childNodes) processBlock(child)
    }
  }

  for (const child of container.childNodes) processBlock(child)
  if (result.length === 0) result.push(new Paragraph({ text: '' }))
  return result
}

async function exportAsDocx() {
  if (!activeNote.value) return
  const title = activeNote.value.title || t('note.export.defaultTitle')
  const htmlContent = getNoteHtmlContent()
  try {
    const docx = await import('docx')
    const children = await htmlToDocxParagraphs(htmlContent, docx)
    const doc = new docx.Document({
      creator: t('note.export.creator'),
      title,
      sections: [{ children }],
    })
    const blob = await docx.Packer.toBlob(doc)
    const arrayBuf = await blob.arrayBuffer()
    const bytes = new Uint8Array(arrayBuf)
    let binary = ''
    for (let i = 0; i < bytes.length; i++) binary += String.fromCharCode(bytes[i])
    const b64 = btoa(binary)
    const result = await invoke('save_binary_file', { title, dataBase64: b64, format: 'docx' })
    if (result) showToast(t('note.toast.exported', { path: result }))
  } catch (err) {
    console.error('DOCX export error:', err)
    showToast(t('note.toast.exportWordFailed'))
  }
}

async function exportAsPdf() {
  if (!activeNote.value) return
  const title = activeNote.value.title || t('note.export.defaultTitle')
  const htmlContent = getNoteHtmlContent()
  const fullHtml = wrapHtmlTemplate(title, htmlContent)
  // 打开新窗口打印
  const printWin = window.open('', '_blank', 'width=800,height=600')
  if (!printWin) {
    showToast(t('note.toast.printWindowBlocked'))
    return
  }
  printWin.document.write(fullHtml)
  printWin.document.close()
  printWin.onload = () => {
    printWin.focus()
    printWin.print()
  }
  showToast(t('note.toast.printWindowOpened'))
}

async function doExport(fmt) {
  showExportMenu.value = false
  if (!activeNote.value) return
  showToast(t('note.toast.exporting'))
  const title = activeNote.value.title || t('note.export.defaultTitle')

  if (fmt === 'docx') { await exportAsDocx(); return }
  if (fmt === 'pdf') { await exportAsPdf(); return }

  let content = ''
  if (fmt === 'md') {
    content = getNotePlainText()
    if (title && !content.startsWith('# ' + title)) content = `# ${title}\n\n${content}`
  } else if (fmt === 'txt') {
    content = getNotePlainText()
    if (title) content = `${title}\n${'═'.repeat(title.length * 2)}\n\n${content}`
  } else if (fmt === 'html') {
    const bodyHtml = getNoteHtmlContent()
    content = wrapHtmlTemplate(title, bodyHtml)
  }

  try {
    const result = await invoke('save_text_file', { title, content, format: fmt })
    if (result) showToast(t('note.toast.exported', { path: result }))
  } catch (e) {
    console.warn('Tauri save failed, fallback to clipboard:', e)
    try {
      await navigator.clipboard.writeText(content)
      showToast(t('note.toast.copiedToClipboard'))
    } catch (e2) {
      console.warn('Clipboard copy failed:', e2)
    }
  }
}

function debounceSave() {
  if (activeNote.value) {
    activeNote.value.updatedAt = Date.now()
    // 标题自动生成：输入法组合中不触发，避免拼音字母被截取为标题
    if (!isComposing.value && (!activeNote.value.title || !activeNote.value.title.trim())) {
      const plain = (activeNote.value.content || '').replace(/<[^>]+>/g, ' ').replace(/&nbsp;/g, ' ').replace(/\s+/g, ' ').trim()
      if (plain) {
        activeNote.value.title = plain.slice(0, 20) + (plain.length > 20 ? '…' : '')
      }
    }
  }
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
      notebooks.value = [{ id: Date.now(), name: t('note.book.defaultName1'), notes: oldNotes }]
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
    const book = { id: Date.now(), name: t('note.book.defaultName1'), notes: [] }
    notebooks.value.push(book)
  }

  // 加载标志：防止 watcher 在 loadData 期间和之后异步覆盖恢复的状态
  _isLoading = true

  // 恢复上次打开的笔记本
  const savedBookId = localStorage.getItem('sn-active-book')
  if (savedBookId && notebooks.value.find(b => b.id == savedBookId)) {
    activeBookId.value = Number(savedBookId)
  } else {
    activeBookId.value = notebooks.value[0].id
  }

  // 恢复上次选中的笔记
  const savedNoteId = localStorage.getItem('sn-active-note')
  if (savedNoteId && notes.value.find(n => n.id == savedNoteId)) {
    activeNoteId.value = Number(savedNoteId)
  } else if (notes.value.length) {
    activeNoteId.value = notes.value[0].id
  }

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

  // 用 nextTick 等待 Vue 刷新 watcher 队列后再放开，防止 watcher 异步覆盖
  nextTick(() => {
    _isLoading = false
    _initialized = true
  })
}

// 初始化守卫：防止 watcher 在 loadData() 完成之前干扰
let _initialized = false
let _isLoading = true

// 监听笔记切换，同步富文本编辑区 + 保存选中状态
watch(activeNoteId, (newId) => {
  if (_initialized && !_isLoading && newId) localStorage.setItem('sn-active-note', newId)
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
  if (!_initialized || _isLoading) return
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
    if (showImportMenu.value) {
      const wraps = document.querySelectorAll('.io-btn-wrap')
      if (wraps[0] && !wraps[0].contains(e.target)) showImportMenu.value = false
    }
    if (showExportMenu.value) {
      const wraps = document.querySelectorAll('.io-btn-wrap')
      if (wraps[1] && !wraps[1].contains(e.target)) showExportMenu.value = false
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
  addNote() { addNote() },
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

.sidebar-search {
  position: relative;
  padding: 4px 6px 6px;
  border-top: 0.5px solid var(--border);
  opacity: 0.5;
  transition: opacity var(--transition-fast);
}

.sidebar-search:hover,
.sidebar-search.active {
  opacity: 1;
}

.sidebar-search .search-icon {
  position: absolute;
  left: 12px;
  top: 50%;
  transform: translateY(-50%);
  color: var(--text-placeholder);
  pointer-events: none;
}

.search-input {
  width: 100%;
  padding: 4px 8px 4px 22px;
  border: 0.5px solid transparent;
  background: transparent;
  border-radius: 4px;
  font-size: 11px;
  color: var(--text-primary);
  font-family: var(--font);
  outline: none;
  transition: all var(--transition-fast);
  box-sizing: border-box;
}

.search-input::placeholder {
  color: transparent;
}

.sidebar-search:hover .search-input::placeholder,
.sidebar-search.active .search-input::placeholder {
  color: var(--text-placeholder);
}

.search-input:focus {
  border-color: var(--accent);
  background: var(--bg-input);
}

.search-input:focus ~ .search-icon {
  color: var(--accent);
}

.search-clear {
  position: absolute;
  right: 12px;
  top: 50%;
  transform: translateY(-50%);
  cursor: pointer;
  color: var(--text-secondary);
  opacity: 0.6;
  transition: opacity var(--transition-fast);
}

.search-clear:hover {
  opacity: 1;
  color: var(--text-primary);
}

.note-list {
  flex: 1;
  overflow-y: auto;
  padding: 6px 4px;
}

.note-empty-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 8px;
  padding: 24px 8px;
  color: var(--text-placeholder);
  font-size: 11px;
  text-align: center;
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
  gap: 3px;
  padding: 6px 10px;
  border-bottom: 0.5px solid var(--border);
  background: var(--bg-surface);
  flex-shrink: 0;
  flex-wrap: wrap;
}

.tb-btn {
  min-width: 28px;
  height: 26px;
  border: none;
  background: transparent;
  border-radius: 5px;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  color: var(--text-secondary);
  font-size: 12px;
  padding: 0 5px;
  transition: all var(--transition-fast);
  font-family: var(--font);
}

.tb-btn:hover {
  background: var(--bg-hover);
  color: var(--text-primary);
}

.tb-btn:active {
  transform: scale(0.92);
}

.tb-btn.active {
  background: var(--accent-light);
  color: var(--accent-text);
}

.tb-list-dropdown {
  position: relative;
  display: flex;
}

.tb-fontsize-select {
  height: 26px;
  border: 0.5px solid var(--border);
  background: transparent;
  border-radius: 5px;
  cursor: pointer;
  font-size: 11px;
  color: var(--text-secondary);
  padding: 0 4px;
  font-family: var(--font);
  outline: none;
  transition: all var(--transition-fast);
}

.tb-fontsize-select:hover {
  background: var(--bg-hover);
  color: var(--text-primary);
  border-color: var(--border-strong);
}

.tb-fontsize-select:focus {
  border-color: var(--accent);
  box-shadow: 0 0 0 1px var(--accent-light);
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
  height: 14px;
  background: var(--border-strong);
  margin: 0 3px;
  flex-shrink: 0;
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
  font-size: 14px;
  line-height: 1.8;
  overflow-y: auto;
  color: var(--text-primary);
  background: var(--bg-app);
  padding: 14px 16px;
  font-family: var(--font);
  word-break: break-word;
  transition: background-color var(--transition-theme), color var(--transition-theme);
}

/* FIX: 深色模式下确保 contenteditable 子元素继承正确颜色 */
.note-content-editable *:not([style*="color"]) {
  color: inherit;
}

.note-content-editable:empty::before {
  content: var(--editor-placeholder, '开始记录...');
  color: var(--text-placeholder);
}

.note-content-editable:focus {
  box-shadow: inset 0 0 0 1px var(--accent-light);
}

/* 富文本内容基础排版 */
.note-content-editable p {
  margin: 6px 0;
  min-height: 1.4em;
}

.note-content-editable ul, .note-content-editable ol {
  padding-left: 24px;
  margin: 6px 0;
}

.note-content-editable ul li,
.note-content-editable ol li {
  padding-left: 4px;
  margin: 3px 0;
  line-height: 1.7;
}

.note-content-editable a {
  color: var(--accent);
  text-decoration: underline;
  text-underline-offset: 2px;
}

.note-content-editable a:hover {
  opacity: 0.85;
}

.note-content-editable h1 {
  font-size: 20px; font-weight: 700; margin: 16px 0 8px;
  border-bottom: 1px solid var(--border); padding-bottom: 6px;
}
.note-content-editable h2 { font-size: 17px; font-weight: 700; margin: 14px 0 6px; }
.note-content-editable h3 { font-size: 15px; font-weight: 600; margin: 12px 0 4px; }
.note-content-editable h4 { font-size: 14px; font-weight: 600; margin: 10px 0 4px; }

.note-content-editable blockquote {
  border-left: 3px solid var(--accent);
  padding: 6px 12px;
  margin: 8px 0;
  background: var(--accent-light);
  border-radius: 0 var(--radius-xs) var(--radius-xs) 0;
  color: var(--text-secondary);
  font-style: italic;
}

.note-content-editable pre {
  background: var(--bg-input);
  border-radius: var(--radius-xs);
  padding: 10px 12px;
  margin: 8px 0;
  overflow-x: auto;
  border: 0.5px solid var(--border);
  font-family: 'Cascadia Code', 'Fira Code', 'Consolas', monospace;
  font-size: 12px;
  line-height: 1.6;
}

.note-content-editable code {
  font-family: 'Cascadia Code', 'Fira Code', 'Consolas', monospace;
  font-size: 12px;
  background: var(--bg-input);
  padding: 1px 5px;
  border-radius: 3px;
  color: var(--accent-text);
}

.note-content-editable pre code {
  background: transparent;
  padding: 0;
  font-size: 12px;
  color: inherit;
}

.note-content-editable hr {
  border: none;
  border-top: 1px solid var(--border);
  margin: 12px 0;
}

.note-content-editable table {
  border-collapse: collapse;
  width: 100%;
  margin: 8px 0;
}

.note-content-editable th,
.note-content-editable td {
  border: 1px solid var(--border-strong);
  padding: 8px 12px;
  font-size: 13px;
  min-width: 40px;
  line-height: 1.5;
}

.note-content-editable th {
  background: var(--bg-surface);
  font-weight: 600;
  text-align: left;
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

/* ===== 导入/导出下拉菜单 ===== */
.io-btn-wrap {
  position: relative;
  display: flex;
  align-items: center;
}

.io-dropdown {
  position: absolute;
  top: calc(100% + 6px);
  right: 0;
  z-index: 200;
  background: var(--bg-surface);
  border: 0.5px solid var(--border);
  border-radius: 10px;
  padding: 4px;
  box-shadow: 0 8px 28px rgba(0,0,0,0.18);
  min-width: 150px;
  animation: fadeIn 0.12s ease;
}

.io-menu-item {
  display: flex;
  align-items: center;
  gap: 10px;
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

.io-menu-item:hover {
  background: var(--bg-hover);
}

.io-fmt {
  display: inline-block;
  min-width: 40px;
  padding: 1px 5px;
  background: var(--bg-hover);
  border: 0.5px solid var(--border);
  border-radius: 4px;
  font-size: 10px;
  font-family: 'SF Mono', 'Courier New', monospace;
  color: var(--text-secondary);
  text-align: center;
  flex-shrink: 0;
}
</style>
