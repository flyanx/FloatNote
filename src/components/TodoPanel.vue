<template>
  <div class="todo-panel" :class="{ narrow }">
    <!-- ===== 添加待办区域 ===== -->
    <div class="add-area">
      <div class="add-row">
        <input
          ref="todoInputEl"
          class="todo-input selectable"
          v-model="newText"
          :placeholder="$t('todo.placeholder.addTodo')"
          @keydown.enter.prevent="addTodo"
          maxlength="200"
        />
        <!-- 优先级选择（内联圆点） -->
        <div class="priority-picker-inline">
          <button
            v-for="p in priorities"
            :key="p.val"
            class="priority-dot-btn"
            :class="{ active: newPriority === p.val }"
            :style="{ '--p-color': p.color }"
            :title="p.label"
            @click="newPriority = p.val"
          ></button>
        </div>
        <!-- 日期选择 -->
        <div class="date-picker-inline">
          <button class="date-pick-btn" :class="{ 'has-date': newDate }" @click="openDatePicker" :title="$t('todo.title.setDueDate')">
            <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <rect x="3" y="4" width="18" height="18" rx="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/>
            </svg>
          </button>
          <input ref="hiddenDateEl" type="date" class="hidden-date-input" @change="onDatePicked" />
        </div>
        <!-- 添加按钮 -->
        <button class="add-btn" @click="addTodo" :disabled="!newText.trim()" :title="$t('todo.title.add')">
          <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
            <line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/>
          </svg>
        </button>
      </div>
    </div>

    <!-- ===== 筛选栏（向上折叠） ===== -->
    <transition name="filter-collapse">
      <div class="filter-bar" v-if="filterVisible">
        <button class="filter-toggle-btn" @click="filterVisible = false" :title="$t('todo.title.collapseFilter')">
          <svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <polyline points="18 15 12 9 6 15"/>
          </svg>
        </button>
        <!-- 状态筛选 -->
        <div class="filter-group">
          <button
            v-for="f in statusFilters"
            :key="f.val"
            class="filter-btn"
            :class="{ active: statusFilter === f.val }"
            @click="statusFilter = f.val"
          >{{ narrow ? f.short : f.label }}</button>
        </div>
        <div class="filter-sep"></div>
        <!-- 优先级筛选 -->
        <div class="filter-group">
          <button
            v-for="f in priorityFilters"
            :key="f.val"
            class="filter-btn"
            :class="{ active: priorityFilter === f.val }"
            @click="priorityFilter = f.val"
          >
            <span v-if="f.color" class="filter-dot" :style="{ background: f.color }"></span>
            <span v-if="!narrow || !f.color">{{ narrow ? f.short : f.label }}</span>
          </button>
        </div>
        <div class="filter-spacer"></div>
        <!-- 清除已完成 -->
        <button class="clear-done-btn" @click="clearDone" v-if="doneCount > 0" :title="$t('todo.title.clearAllDone')">
          {{ $t('todo.action.clearDone') }} {{ doneCount }}
        </button>
      </div>
    </transition>

    <!-- ===== 进度条 + 浮动筛选按钮 ===== -->
    <div class="progress-section" v-if="allTodos.length > 0 || !filterVisible">
      <!-- 筛选栏收起时，浮动小按钮（放在左侧） -->
      <button v-if="!filterVisible" class="filter-float-btn" @click="filterVisible = true" :title="$t('todo.title.expandFilter')">
        <svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <polygon points="22 3 2 3 10 12.46 10 19 14 21 14 12.46 22 3"/>
        </svg>
        <span class="filter-float-label">{{ $t('todo.filter.label') }}</span>
        <span v-if="statusFilter !== 'all' || priorityFilter !== 'all'" class="filter-active-dot"></span>
      </button>
      <div class="progress-bar" v-if="allTodos.length > 0">
        <div class="progress-fill" :style="{ width: progress + '%' }"></div>
      </div>
      <div class="progress-bar progress-bar-placeholder" v-else></div>
      <span class="progress-text" v-if="allTodos.length > 0">{{ doneCount }}/{{ allTodos.length }}</span>
    </div>

    <!-- ===== 任务列表 ===== -->
    <div class="task-list">
      <div class="task-inner" v-if="filteredTodos.length">
        <div
          v-for="task in filteredTodos"
          :key="task.id"
          class="task-item"
          :data-drag-id="task.id"
          :class="{ done: task.done, expanded: expandedId === task.id, 'has-subtasks': task.subtasks && task.subtasks.length }"
        >
          <!-- 主行：复选框 + 文本 + 子任务进度 + 优先级 + 日期 + 操作 -->
          <div
            class="task-row"
            :class="{ dragging: dragTaskId === task.id }"
            @click="toggleExpand(task)"
            @contextmenu.prevent="openTaskCtxMenu($event, task)"
            @pointerdown="onDragStart($event, task)"
          >
            <!-- 完成复选框 -->
            <button
              class="task-check"
              :class="{ checked: task.done }"
              @click.stop="toggleDone(task)"
              :title="task.done ? $t('todo.title.uncomplete') : $t('todo.title.markDone')"
            >
              <svg v-if="task.done" width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="#fff" stroke-width="2.5">
                <polyline points="20 6 9 17 4 12"/>
              </svg>
            </button>
            <!-- 任务文本 -->
            <span class="task-text" :class="{ 'line-through': task.done }">
              <span v-if="renamingId === task.id" class="rename-inline-wrap" @click.stop>
                <input
                  class="rename-inline-input selectable"
                  v-model="renameText"
                  @keydown.enter.prevent="finishRename(task)"
                  @keydown.escape.prevent="cancelRename"
                  @blur="finishRename(task)"
                  ref="renameInput"
                  maxlength="150"
                />
              </span>
              <span v-else>{{ task.text }}</span>
            </span>
            <!-- 右侧元数据区域（固定宽度对齐） -->
            <div class="task-meta">
              <!-- 到期日 -->
              <span class="task-due" v-if="task.dueDate && !task.done" :class="{ overdue: isOverdue(task) }">
                {{ formatDue(task) }}
              </span>
              <!-- 优先级圆点 -->
              <span class="task-priority-dot" :class="'pri-' + (task.priority || 'mid')" v-if="!task.done" :title="$t('todo.context.prioritySubtitle') + ': ' + (task.priority === 'high' ? $t('todo.priority.high') : task.priority === 'low' ? $t('todo.priority.low') : $t('todo.priority.mid'))"></span>
              <!-- 展开指示 + 子任务进度 -->
              <span class="task-expand-group" v-if="task.subtasks && task.subtasks.length">
                <svg class="task-expand-icon" :class="{ open: expandedId === task.id }" width="8" height="8" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                  <polyline points="6 9 12 15 18 9"/>
                </svg>
                <span class="task-sub-progress">
                  {{ task.subtasks.filter(s => s.done).length }}/{{ task.subtasks.length }}
                </span>
              </span>
              <!-- 备注指示 -->
              <span class="task-note-tag" v-if="task.note" :title="task.note" @click.stop="toggleNotePanel(task)">{{ $t('todo.note.hasNote') }}</span>
              <span class="task-note-tag empty" v-else @click.stop="toggleNotePanel(task)" :title="$t('todo.title.addNote')">{{ $t('todo.note.label') }}</span>
            </div>
          </div>

          <!-- 子任务列表 -->
          <transition name="subtask-slide">
            <div class="subtask-list" v-if="expandedId === task.id && task.subtasks && task.subtasks.length">
              <div v-for="(sub, si) in task.subtasks" :key="si" class="subtask-item" @contextmenu.prevent="openSubCtxMenu($event, task, si)">
                <button class="task-check subtask-check" :class="{ checked: sub.done }" @click.stop="toggleSubDone(task, si)">
                  <svg v-if="sub.done" width="8" height="8" viewBox="0 0 24 24" fill="none" stroke="#fff" stroke-width="2.5">
                    <polyline points="20 6 9 17 4 12"/>
                  </svg>
                </button>
                <span class="subtask-text" :class="{ 'line-through': sub.done }">{{ sub.text }}</span>
                <span class="task-note-tag sub" v-if="sub.note" :title="sub.note">{{ $t('todo.note.hasNote') }}</span>
                <button class="subtask-del-btn" @click.stop="removeSubtask(task, si)" :title="$t('todo.title.deleteSubtask')">
                  <svg width="8" height="8" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/>
                  </svg>
                </button>
              </div>
            </div>
          </transition>

          <!-- 子任务输入框（展开后显示） -->
          <transition name="subtask-slide">
            <div class="subtask-input-row" v-if="expandedId === task.id" @click.stop>
              <input
                class="subtask-input selectable"
                v-model="subInputs[task.id]"
                :placeholder="$t('todo.placeholder.addSubtask')"
                @keydown.enter.prevent="addSubtask(task)"
                maxlength="150"
              />
              <button class="subtask-add-btn" @click="addSubtask(task)" :disabled="!subInputs[task.id]?.trim()">
                <svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                  <line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/>
                </svg>
              </button>
            </div>
          </transition>

          <!-- 备注编辑面板 -->
          <transition name="subtask-slide">
            <div class="task-note-panel" v-if="notePanelTaskId === task.id" @click.stop>
              <div class="task-note-panel-header">
                <span>{{ $t('todo.note.label') }}</span>
                <button class="task-note-close" @click="notePanelTaskId = null">×</button>
              </div>
              <textarea
                class="task-note-textarea selectable"
                v-model="notePanelText"
                @input="onNotePanelInput"
                :placeholder="$t('todo.placeholder.noteContent')"
                rows="3"
                maxlength="500"
              ></textarea>
            </div>
          </transition>
        </div>
      </div>
      <div class="task-empty" v-else>
        <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" style="opacity:0.2">
          <polyline points="9 11 12 14 22 4"/><path d="M21 12v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11"/>
        </svg>
        <p v-if="allTodos.length === 0">{{ $t('todo.empty.noTodos') }}</p>
        <p v-else>{{ $t('todo.empty.noMatch') }}</p>
      </div>
    </div>

    <!-- ===== 任务右键菜单 ===== -->
    <transition name="ctx-menu">
      <div
        class="task-ctx-menu"
        v-if="taskCtxMenu.visible"
        :style="{ left: taskCtxMenu.x + 'px', top: taskCtxMenu.y + 'px' }"
        @click.stop
      >
        <button class="ctx-menu-item" @click="startRenameFromCtx">
          <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/>
          </svg>
          {{ $t('todo.context.rename') }}
        </button>
        <div class="ctx-menu-divider"></div>
        <!-- 优先级 -->
        <div class="ctx-menu-subtitle">{{ $t('todo.context.prioritySubtitle') }}</div>
        <div class="ctx-priority-row">
          <button
            v-for="p in priorities"
            :key="p.val"
            class="ctx-priority-chip"
            :class="{ active: taskCtxMenu.task?.priority === p.val || (!taskCtxMenu.task?.priority && p.val === 'mid') }"
            :style="{ '--p-chip-color': p.color }"
            @click="setTaskPriority(taskCtxMenu.task, p.val)"
          >{{ p.label }}</button>
        </div>
        <div class="ctx-menu-divider"></div>
        <!-- 日期 -->
        <button class="ctx-menu-item" @click="setDueDateFromCtx">
          <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <rect x="3" y="4" width="18" height="18" rx="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/>
          </svg>
          {{ taskCtxMenu.task?.dueDate ? $t('todo.context.modifyDate') : $t('todo.title.setDueDate') }}
        </button>
        <button v-if="taskCtxMenu.task?.dueDate" class="ctx-menu-item" @click="clearDueDate">
          <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <circle cx="12" cy="12" r="9"/><line x1="8" y1="12" x2="16" y2="12"/>
          </svg>
          {{ $t('todo.context.clearDate') }}
        </button>
        <div class="ctx-menu-divider"></div>
        <button class="ctx-menu-item danger" @click="deleteTaskFromCtx">
          <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <polyline points="3 6 5 6 21 6"/><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6"/>
          </svg>
          {{ $t('todo.context.deleteTask') }}
        </button>
      </div>
    </transition>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted, nextTick, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import { readJSON, writeJSON } from '../utils/storage.js'
import { addItemToTrash } from '../utils/trash.js'
import { generateId } from '../utils/id.js'
import { useDragSort } from '../composables/useDragSort.js'
import { useContextMenu } from '../composables/useContextMenu.js'
import { useInlineRename } from '../composables/useInlineRename.js'

const { t } = useI18n()

// ===== 常量 =====
const TODOLISTS_KEY = 'sn-todolists'

const priorities = computed(() => [
  { val: 'high', label: t('todo.priority.high'), color: '#e8453c' },
  { val: 'mid', label: t('todo.priority.mid'), color: '#f59e0b' },
  { val: 'low', label: t('todo.priority.low'), color: '#22c55e' }
])
const statusFilters = computed(() => [
  { val: 'all', label: t('todo.filterStatus.all'), short: t('todo.filterStatus.allShort') },
  { val: 'pending', label: t('todo.filterStatus.pending'), short: t('todo.filterStatus.pendingShort') },
  { val: 'done', label: t('todo.filterStatus.done'), short: t('todo.filterStatus.doneShort') }
])
const priorityFilters = computed(() => [
  { val: 'all', label: t('todo.filterStatus.all'), short: t('todo.filterStatus.allShort'), color: '' },
  { val: 'high', label: t('todo.priority.high'), short: t('todo.priority.high'), color: '#e8453c' },
  { val: 'mid', label: t('todo.priority.mid'), short: t('todo.priority.mid'), color: '#f59e0b' },
  { val: 'low', label: t('todo.priority.low'), short: t('todo.priority.low'), color: '#22c55e' }
])

// ===== 状态 =====
const lists = ref([])
const activeListId = ref(null)
const newText = ref('')
const newPriority = ref('mid')
const newDate = ref('')
const statusFilter = ref(localStorage.getItem('sn-todo-filter-status') || 'all')
const priorityFilter = ref(localStorage.getItem('sn-todo-filter-priority') || 'all')
const expandedId = ref(null)
const subInputs = ref({})
const narrow = ref(false)
const filterVisible = ref(localStorage.getItem('sn-filter-visible') !== '0')
const hiddenDateEl = ref(null)
const todoInputEl = ref(null)
let _resizeObserver = null

// 内联重命名
const { renamingId, renameText, startRename, finishRename, cancelRename } = useInlineRename((item, newText) => {
  item.text = newText
  saveLists()
})

// 右键菜单
const { menu: taskCtxMenu, open: openCtxMenu, close: closeTaskCtxMenu } = useContextMenu(150, 200)

// 拖拽排序
const { dragItemId: dragTaskId, onDragStart } = useDragSort(
  computed(() => activeList.value?.todos || []),
  () => saveLists(),
  400
)

// ===== 计算属性 =====
const activeList = computed(() => lists.value.find(l => l.id === activeListId.value) || null)
const allTodos = computed(() => activeList.value?.todos || [])
const today = computed(() => new Date().toISOString().split('T')[0])

const filteredTodos = computed(() => {
  let result = [...allTodos.value].sort((a, b) => {
    if (a.done !== b.done) return a.done ? 1 : -1
    const order = { high: 0, mid: 1, low: 2 }
    return (order[a.priority] ?? 1) - (order[b.priority] ?? 1)
  })
  if (statusFilter.value === 'pending') result = result.filter(t => !t.done)
  if (statusFilter.value === 'done') result = result.filter(t => t.done)
  if (priorityFilter.value !== 'all') result = result.filter(t => t.priority === priorityFilter.value)
  return result
})

const doneCount = computed(() => allTodos.value.filter(t => t.done).length)
const progress = computed(() => allTodos.value.length ? Math.round(doneCount.value / allTodos.value.length * 100) : 0)

// ===== 待办列表管理 =====
function readLists() {
  return readJSON(TODOLISTS_KEY, [])
}

function saveLists() {
  writeJSON(TODOLISTS_KEY, lists.value)
}

function addTodoList() {
  const list = { id: Date.now(), name: t('todo.list.newName', { n: lists.value.length + 1 }), todos: [] }
  lists.value.push(list)
  activeListId.value = list.id
  saveLists()
  window.dispatchEvent(new CustomEvent('todolists-updated'))
}

function switchToList(id) {
  activeListId.value = id
  localStorage.setItem('sn-active-todolist', id)
}

function deleteTodoList(id) {
  if (lists.value.length <= 1) return
  const idx = lists.value.findIndex(l => l.id === id)
  const deleted = lists.value[idx]
  if (deleted) addItemToTrash(deleted, 'list')
  lists.value.splice(idx, 1)
  if (activeListId.value === id) {
    activeListId.value = lists.value[Math.max(0, idx - 1)]?.id || null
  }
  saveLists()
  window.dispatchEvent(new CustomEvent('todolists-updated'))
}

// ===== 任务操作 =====
function addTodo() {
  const text = newText.value.trim()
  if (!text || !activeList.value) return
  const todo = {
    id: Date.now(),
    text,
    done: false,
    priority: newPriority.value,
    dueDate: newDate.value || null,
    subtasks: [],
    createdAt: Date.now()
  }
  activeList.value.todos.unshift(todo)
  newText.value = ''
  newPriority.value = 'mid'
  newDate.value = ''
  saveLists()
  updatePendingCount()
  nextTick(() => todoInputEl.value?.focus())
}

function toggleDone(task) {
  task.done = !task.done
  if (task.done) {
    expandedId.value = null
    // 自动完成所有子任务
    if (task.subtasks) task.subtasks.forEach(s => s.done = true)
  }
  // 检查父任务是否应自动完成
  checkAutoComplete()
  saveLists()
  updatePendingCount()
}

function toggleExpand(task) {
  expandedId.value = expandedId.value === task.id ? null : task.id
  if (expandedId.value === task.id) {
    if (!subInputs.value[task.id]) subInputs.value[task.id] = ''
  }
}

// 展开状态持久化
watch(expandedId, (val) => {
  if (val) {
    localStorage.setItem('sn-todo-expanded-' + activeListId.value, String(val))
  } else {
    localStorage.removeItem('sn-todo-expanded-' + activeListId.value)
  }
})

// 筛选栏状态持久化
watch(filterVisible, (val) => {
  localStorage.setItem('sn-filter-visible', val ? '1' : '0')
})

// 筛选条件持久化
watch(statusFilter, (val) => {
  localStorage.setItem('sn-todo-filter-status', val)
})
watch(priorityFilter, (val) => {
  localStorage.setItem('sn-todo-filter-priority', val)
})

function toggleSubDone(task, subIdx) {
  task.subtasks[subIdx].done = !task.subtasks[subIdx].done
  // 如果所有子任务都完成了，自动完成父任务
  if (task.subtasks.every(s => s.done)) {
    task.done = true
    expandedId.value = null
  } else {
    task.done = false
  }
  checkAutoComplete()
  saveLists()
  updatePendingCount()
}

function addSubtask(task) {
  const text = (subInputs.value[task.id] || '').trim()
  if (!text) return
  if (!task.subtasks) task.subtasks = []
  task.subtasks.push({ text, done: false })
  subInputs.value[task.id] = ''
  // 添加子任务后，父任务自动取消完成
  if (task.done) task.done = false
  saveLists()
  updatePendingCount()
}

function removeSubtask(task, si) {
  task.subtasks.splice(si, 1)
  checkAutoComplete()
  saveLists()
  updatePendingCount()
}

function checkAutoComplete() {
  // 遍历所有父任务，如果所有子任务都完成了，自动标记父任务完成
  allTodos.value.forEach(task => {
    if (task.subtasks && task.subtasks.length > 0 && task.subtasks.every(s => s.done)) {
      task.done = true
    }
  })
}

function clearDone() {
  if (!activeList.value) return
  const doneItems = activeList.value.todos.filter(t => t.done)
  doneItems.forEach(t => addItemToTrash(t, 'todo'))
  activeList.value.todos = activeList.value.todos.filter(t => !t.done)
  saveLists()
  updatePendingCount()
}

// ===== 日期 =====
function openDatePicker() {
  const el = hiddenDateEl.value
  if (!el) return
  if (el.showPicker) {
    el.showPicker()
  } else {
    el.click()
  }
}

function onDatePicked(e) {
  newDate.value = e.target.value || ''
}

function formatDue(task) {
  if (!task.dueDate || task.done) return ''
  const due = new Date(task.dueDate)
  const now = new Date(today.value)
  const diff = Math.round((due - now) / 86400000)
  if (diff < 0) return t('todo.date.overdue')
  if (diff === 0) return t('todo.date.dueToday')
  if (diff === 1) return t('todo.date.dueTomorrow')
  return t('todo.date.daysRemaining', { n: diff })
}

function isOverdue(task) {
  if (!task.dueDate || task.done) return false
  return new Date(task.dueDate) < new Date(today.value)
}

function setDueDateFromCtx() {
  const task = taskCtxMenu.value.task
  taskCtxMenu.value.visible = false
  if (!task) return
  const input = document.createElement('input')
  input.type = 'date'
  input.value = task.dueDate || today.value
  input.style.cssText = 'position:fixed;opacity:0;pointer-events:none;top:-100px;left:-100px;width:1px;height:1px'
  document.body.appendChild(input)
  input.addEventListener('change', () => {
    task.dueDate = input.value || null
    document.body.removeChild(input)
    saveLists()
  })
  input.addEventListener('blur', () => {
    setTimeout(() => { if (document.body.contains(input)) document.body.removeChild(input) }, 300)
  })
  if (input.showPicker) input.showPicker()
  else input.focus()
}

function clearDueDate() {
  const task = taskCtxMenu.value.task
  taskCtxMenu.value.visible = false
  if (!task) return
  task.dueDate = null
  saveLists()
}

// ===== 右键菜单 =====
function openTaskCtxMenu(e, task) {
  openCtxMenu(e, { task, subTask: null })
}

// 子任务右键菜单
function openSubCtxMenu(e, task, si) {
  openCtxMenu(e, { task, subTask: { task, si, sub: task.subtasks[si] } })
}

function setTaskPriority(task, priority) {
  if (!task) return
  task.priority = priority
  saveLists()
  closeTaskCtxMenu()
}

function startRenameFromCtx() {
  const task = taskCtxMenu.value.task
  closeTaskCtxMenu()
  if (!task) return
  startRename(task)
}

function deleteTaskFromCtx() {
  const task = taskCtxMenu.value.task
  closeTaskCtxMenu()
  if (!task || !activeList.value) return
  deleteTodo(task)
}

function deleteTodo(task) {
  if (!activeList.value) return
  addItemToTrash(task, 'todo')
  const idx = activeList.value.todos.findIndex(t => t.id === task.id)
  if (idx >= 0) activeList.value.todos.splice(idx, 1)
  saveLists()
  updatePendingCount()
}

// ===== 备注功能 =====
// 备注面板状态
const notePanelTaskId = ref(null)
const notePanelText = ref('')
let _notePanelTarget = null // { task } 或 { task, subTask: sub }

function toggleNotePanel(task) {
  if (notePanelTaskId.value === task.id && !_notePanelTarget?.subTask) {
    notePanelTaskId.value = null
    _notePanelTarget = null
    return
  }
  notePanelTaskId.value = task.id
  notePanelText.value = task.note || ''
  _notePanelTarget = { task }
  nextTick(() => {
    const ta = document.querySelector('.task-note-textarea')
    if (ta) ta.focus()
  })
}

function onNotePanelInput() {
  if (!_notePanelTarget) return
  if (_notePanelTarget.subTask) {
    _notePanelTarget.subTask.note = notePanelText.value
  } else {
    _notePanelTarget.task.note = notePanelText.value
  }
  saveLists()
}

function editTaskNote() {
  const ctx = taskCtxMenu.value
  closeTaskCtxMenu()
  if (ctx.subTask) {
    // 子任务备注
    const task = ctx.subTask.task
    notePanelTaskId.value = task.id
    notePanelText.value = ctx.subTask.sub.note || ''
    _notePanelTarget = { task, subTask: ctx.subTask.sub }
    nextTick(() => {
      const ta = document.querySelector('.task-note-textarea')
      if (ta) ta.focus()
    })
    return
  }
  // 父任务备注：打开内联备注面板
  if (!ctx.task) return
  toggleNotePanel(ctx.task)
}

// ===== 工具方法 =====
function updatePendingCount() {
  const count = allTodos.value.filter(t => !t.done).length
  window.dispatchEvent(new CustomEvent('todo-pending-update', { detail: count }))
}

// ===== 生命周期 =====
onMounted(() => {
  lists.value = readLists()
  const saved = localStorage.getItem('sn-active-todolist')
  activeListId.value = saved ? Number(saved) : (lists.value[0]?.id || null)
  // 恢复展开状态
  if (activeListId.value) {
    const savedExpanded = localStorage.getItem('sn-todo-expanded-' + activeListId.value)
    if (savedExpanded) expandedId.value = Number(savedExpanded)
  }
  if (!activeListId.value && lists.value.length === 0) {
    // 创建默认待办页
    const defaultList = { id: Date.now(), name: t('todo.list.defaultName'), todos: [] }
    lists.value.push(defaultList)
    activeListId.value = defaultList.id
    saveLists()
    window.dispatchEvent(new CustomEvent('todolists-updated'))
  }
  updatePendingCount()

  // 点击外部关闭右键菜单
  document.addEventListener('click', closeTaskCtxMenu)

  // 窄窗口检测
  const panelEl = document.querySelector('.todo-panel')
  if (panelEl) {
    _resizeObserver = new ResizeObserver(entries => {
      const w = entries[0]?.contentRect?.width || 0
      narrow.value = w < 340
    })
    _resizeObserver.observe(panelEl)
  }
})

onUnmounted(() => {
  document.removeEventListener('click', closeTaskCtxMenu)
  if (_resizeObserver) _resizeObserver.disconnect()
})

// 重新加载数据（云同步/导入后刷新）
function reload() {
  lists.value = readLists()
  const saved = localStorage.getItem('sn-active-todolist')
  activeListId.value = saved ? Number(saved) : (lists.value[0]?.id || null)
  updatePendingCount()
}

// 暴露给父组件
defineExpose({ addTodoList, addTodo, switchToList, deleteTodoList, reload })
</script>

<style scoped>
.todo-panel {
  display: flex;
  flex-direction: column;
  flex: 1;
  overflow: hidden;
  background: var(--bg-app);
}

.todo-panel.narrow .priority-dot-btn { width: 9px; height: 9px; }
.todo-panel.narrow .date-pick-btn { width: 24px; height: 24px; }

/* ===== 添加区域 ===== */
.add-area {
  padding: 10px 14px 8px;
  border-bottom: 0.5px solid var(--border);
  background: var(--bg-surface);
}

.add-row {
  display: flex;
  align-items: center;
  gap: 6px;
}

.todo-input {
  flex: 1;
  border: 0.5px solid var(--border);
  border-radius: var(--radius-sm);
  padding: 9px 14px;
  font-size: 13px;
  background: var(--bg-input);
  color: var(--text-primary);
  outline: none;
  font-family: var(--font);
  transition: all var(--transition);
}

.todo-input:focus {
  border-color: var(--accent);
  box-shadow: 0 0 0 3px var(--accent-light);
  background: var(--bg-surface);
}
.todo-input::placeholder { color: var(--text-placeholder); }

.add-btn {
  width: 30px;
  height: 30px;
  border: none;
  border-radius: var(--radius-sm);
  background: var(--accent);
  color: #fff;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all var(--transition);
  flex-shrink: 0;
  box-shadow: var(--shadow-sm);
}

.add-btn:hover:not(:disabled) {
  opacity: 0.9;
  transform: scale(1.08);
  box-shadow: var(--shadow-glow);
}

.add-btn:disabled {
  opacity: 0.35;
  cursor: default;
}

/* ===== 优先级选择 ===== */
.priority-picker-inline {
  display: flex;
  gap: 6px;
  flex-shrink: 0;
}

.priority-dot-btn {
  width: 14px;
  height: 14px;
  border-radius: 50%;
  border: 1px solid var(--p-color);
  background: var(--p-color);
  opacity: 0.35;
  cursor: pointer;
  transition: all 0.15s;
  padding: 0;
  flex-shrink: 0;
}

.priority-dot-btn:hover {
  opacity: 0.7;
  transform: scale(1.3);
}

.priority-dot-btn.active {
  opacity: 1;
  transform: scale(1.1);
  box-shadow: 0 0 0 2px var(--p-color), 0 0 0 3px rgba(255,255,255,0.3);
}

/* ===== 日期选择 ===== */
.date-picker-inline {
  flex-shrink: 0;
  position: relative;
}

.date-pick-btn {
  width: 28px;
  height: 28px;
  border: 0.5px solid var(--border);
  border-radius: 6px;
  background: var(--bg-input);
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  color: var(--text-tertiary);
  transition: all 0.15s;
  padding: 0;
}

.date-pick-btn:hover {
  border-color: var(--accent);
  color: var(--accent);
  background: var(--accent-light);
}

.date-pick-btn.has-date {
  color: var(--accent);
  border-color: var(--accent);
}

.hidden-date-input {
  position: absolute;
  top: 0;
  right: 0;
  bottom: 0;
  left: 0;
  opacity: 0;
  pointer-events: none;
  width: 1px;
  height: 1px;
}

/* ===== 筛选栏 ===== */
.filter-bar {
  display: flex;
  align-items: center;
  gap: 4px;
  padding: 6px 14px;
  border-bottom: 0.5px solid var(--border);
  background: var(--bg-surface);
}

/* 浮动筛选按钮（筛选栏收起时） */
.filter-float-btn {
  display: flex;
  align-items: center;
  gap: 3px;
  padding: 3px 8px;
  border: 0.5px solid var(--border);
  background: var(--bg-surface);
  border-radius: 14px;
  cursor: pointer;
  color: var(--text-tertiary);
  font-size: 10px;
  font-family: var(--font);
  transition: all 0.15s;
  flex-shrink: 0;
}

.filter-float-btn:hover {
  background: var(--bg-hover);
  color: var(--text-primary);
  border-color: var(--accent);
}

.filter-float-label {
  font-weight: 500;
}

.filter-active-dot {
  width: 5px;
  height: 5px;
  border-radius: 50%;
  background: var(--accent);
  flex-shrink: 0;
}

.filter-toggle-btn {
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
  transition: all 0.15s;
  flex-shrink: 0;
  padding: 0;
  margin-right: 2px;
}

.filter-toggle-btn:hover {
  background: var(--bg-hover);
  color: var(--text-primary);
}

.filter-group { display: flex; gap: 2px; }

.filter-sep {
  width: 1px;
  height: 14px;
  background: var(--border);
  margin: 0 4px;
}

.filter-btn {
  padding: 4px 10px;
  border-radius: 20px;
  font-size: 11px;
  font-weight: 500;
  cursor: pointer;
  border: 0.5px solid transparent;
  background: transparent;
  color: var(--text-secondary);
  transition: all var(--transition);
  font-family: var(--font);
  display: flex;
  align-items: center;
  gap: 4px;
}

.filter-btn:hover {
  background: var(--bg-hover);
  color: var(--text-primary);
  border-color: var(--border);
}

.filter-btn.active {
  background: var(--accent-light);
  color: var(--accent-text);
  font-weight: 600;
  border-color: var(--accent);
  box-shadow: 0 2px 6px var(--accent-glow);
}

.filter-dot {
  width: 7px;
  height: 7px;
  border-radius: 50%;
  flex-shrink: 0;
  box-shadow: 0 0 4px currentColor;
}

.filter-spacer { flex: 1; }

.clear-done-btn {
  font-size: 11px;
  color: var(--text-tertiary);
  background: transparent;
  border: none;
  cursor: pointer;
  padding: 3px 6px;
  border-radius: 4px;
  transition: all var(--transition);
  font-family: var(--font);
}

.clear-done-btn:hover {
  color: var(--danger);
  background: var(--danger-light);
}

/* 筛选栏向上折叠动画 */
.filter-collapse-enter-active,
.filter-collapse-leave-active {
  transition: all 0.25s cubic-bezier(0.16, 1, 0.3, 1);
  max-height: 40px;
  opacity: 1;
}

.filter-collapse-enter-from,
.filter-collapse-leave-to {
  max-height: 0;
  opacity: 0;
  padding-top: 0;
  padding-bottom: 0;
  border-bottom-width: 0;
  margin-top: -1px;
}

/* ===== 进度条 ===== */
.progress-section {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 5px 14px;
  min-height: 22px;
}

.progress-bar {
  flex: 1;
  height: 4px;
  background: var(--border);
  border-radius: 3px;
  overflow: hidden;
  position: relative;
}

.progress-bar-placeholder {
  flex: 1;
  height: 4px;
  background: transparent;
}

.progress-fill {
  height: 100%;
  background: linear-gradient(90deg, var(--accent), var(--accent-text));
  border-radius: 3px;
  transition: width 0.5s cubic-bezier(0.16, 1, 0.3, 1);
  position: relative;
  box-shadow: 0 0 6px var(--accent-glow);
}

.progress-fill::after {
  content: '';
  position: absolute;
  inset: 0;
  background: linear-gradient(90deg, transparent, rgba(255,255,255,0.3), transparent);
  background-size: 200% 100%;
  animation: shimmer 2s ease-in-out infinite;
}

.progress-text {
  font-size: 11px;
  color: var(--text-tertiary);
  white-space: nowrap;
}

/* ===== 任务列表 ===== */
.task-list {
  flex: 1;
  overflow-y: auto;
  padding: 6px 8px;
}

.task-inner {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.task-item {
  display: flex;
  flex-direction: column;
  padding: 10px 12px;
  border-radius: var(--radius-sm);
  border: 0.5px solid transparent;
  transition: all var(--transition);
  animation: fadeIn 0.25s ease;
  cursor: default;
  position: relative;
}

.task-item:hover {
  background: var(--bg-hover);
  border-color: var(--border);
  box-shadow: var(--shadow-sm);
}

.task-item.done {
  opacity: 0.55;
}

.task-item.expanded {
  background: var(--bg-surface);
  border-color: var(--border);
}

.task-row {
  display: flex;
  align-items: center;
  gap: 8px;
  min-height: 28px;
}

/* ===== 复选框 ===== */
.task-check {
  width: 18px;
  height: 18px;
  border-radius: 50%;
  border: 1.5px solid var(--border-strong);
  background: transparent;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  transition: all 0.25s cubic-bezier(0.16, 1, 0.3, 1);
  padding: 0;
  position: relative;
}

.task-check:hover {
  border-color: var(--accent);
  background: var(--accent-light);
  transform: scale(1.1);
}

.task-check.checked {
  background: var(--accent);
  border-color: var(--accent);
  animation: checkPop 0.3s ease;
}

.subtask-check {
  width: 14px;
  height: 14px;
}

/* ===== 任务文本 ===== */
.task-text {
  flex: 1;
  font-size: 13px;
  color: var(--text-primary);
  line-height: 1.5;
  min-width: 0;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.task-text.line-through {
  text-decoration: line-through;
  color: var(--text-tertiary);
}

.rename-inline-wrap {
  display: block;
  width: 100%;
}

.rename-inline-input {
  width: 100%;
  border: 0.5px solid var(--accent);
  border-radius: 4px;
  padding: 2px 8px;
  font-size: 13px;
  background: var(--bg-input);
  color: var(--text-primary);
  outline: none;
  font-family: var(--font);
}

/* ===== 到期日 ===== */
.task-due {
  font-size: 10px;
  color: var(--text-tertiary);
  background: var(--bg-hover);
  padding: 2px 6px;
  border-radius: 8px;
  white-space: nowrap;
  flex-shrink: 0;
}

.task-due.overdue {
  color: var(--danger);
  background: var(--danger-light);
}

/* ===== 优先级圆点 ===== */
.task-priority-dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  flex-shrink: 0;
}

.task-priority-dot.pri-high { background: #e8453c; }
.task-priority-dot.pri-mid { background: #f59e0b; }
.task-priority-dot.pri-low { background: #22c55e; }

/* ===== 展开图标 ===== */
.task-expand-icon {
  flex-shrink: 0;
  color: var(--text-tertiary);
  transition: transform 0.2s ease;
}

.task-expand-icon.open {
  transform: rotate(180deg);
}

/* ===== 子任务 ===== */
.subtask-list {
  padding: 4px 0 2px 26px;
  display: flex;
  flex-direction: column;
  gap: 3px;
}

.subtask-item {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 3px 0;
}

.subtask-text {
  flex: 1;
  font-size: 12px;
  color: var(--text-secondary);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.subtask-text.line-through {
  text-decoration: line-through;
  color: var(--text-tertiary);
}

.subtask-del-btn {
  width: 18px;
  height: 18px;
  border: none;
  background: transparent;
  border-radius: 4px;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  color: var(--text-tertiary);
  opacity: 0;
  transition: all 0.15s;
  flex-shrink: 0;
}

.subtask-item:hover .subtask-del-btn,
.subtask-del-btn:hover {
  opacity: 1;
}

.subtask-del-btn:hover {
  background: var(--danger-light);
  color: var(--danger);
}

/* 子任务输入行 */
.subtask-input-row {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 4px 0 2px 26px;
}

.subtask-input {
  flex: 1;
  border: 0.5px solid var(--border);
  border-radius: 6px;
  padding: 5px 10px;
  font-size: 12px;
  background: var(--bg-input);
  color: var(--text-primary);
  outline: none;
  font-family: var(--font);
  transition: border-color var(--transition);
}

.subtask-input:focus { border-color: var(--accent); }
.subtask-input::placeholder { color: var(--text-placeholder); }

.subtask-add-btn {
  width: 24px;
  height: 24px;
  border: none;
  border-radius: 5px;
  background: var(--accent-light);
  color: var(--accent);
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.15s;
  flex-shrink: 0;
}

.subtask-add-btn:hover:not(:disabled) {
  background: var(--accent);
  color: #fff;
}

.subtask-add-btn:disabled {
  opacity: 0.3;
  cursor: default;
}

/* 子任务折叠动画 */
.subtask-slide-enter-active,
.subtask-slide-leave-active {
  transition: all 0.2s cubic-bezier(0.16, 1, 0.3, 1);
  overflow: hidden;
}

.subtask-slide-enter-from,
.subtask-slide-leave-to {
  opacity: 0;
  max-height: 0;
}

.subtask-slide-enter-to,
.subtask-slide-leave-from {
  opacity: 1;
  max-height: 300px;
}

/* ===== 空状态 ===== */
.task-empty {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 40px 0;
  color: var(--text-tertiary);
  font-size: 13px;
  gap: 8px;
}

/* ===== 右键菜单 ===== */
.task-ctx-menu {
  position: fixed;
  z-index: 500;
  background: var(--bg-surface);
  border: 0.5px solid var(--border);
  border-radius: 8px;
  padding: 4px;
  box-shadow: 0 6px 24px rgba(0,0,0,0.2);
  min-width: 130px;
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

.ctx-menu-subtitle {
  font-size: 10px;
  color: var(--text-tertiary);
  padding: 2px 10px;
  font-weight: 500;
}

.ctx-priority-row {
  display: flex;
  gap: 3px;
  padding: 2px 10px;
}

.ctx-priority-chip {
  padding: 3px 8px;
  border-radius: 12px;
  font-size: 11px;
  font-weight: 500;
  cursor: pointer;
  border: 1px solid var(--border);
  background: transparent;
  color: var(--text-secondary);
  font-family: var(--font);
  transition: all 0.15s;
}

.ctx-priority-chip:hover {
  border-color: var(--p-chip-color);
  color: var(--p-chip-color);
  background: color-mix(in srgb, var(--p-chip-color) 10%, transparent);
}

.ctx-priority-chip.active {
  background: var(--p-chip-color);
  color: #fff;
  border-color: var(--p-chip-color);
}

.ctx-menu-divider {
  height: 1px;
  background: var(--border);
  margin: 3px 4px;
}

/* ===== 右侧元数据区域（固定宽度对齐） ===== */
.task-meta {
  display: flex;
  align-items: center;
  gap: 6px;
  flex-shrink: 0;
  min-width: 0;
}

.task-expand-group {
  display: flex;
  align-items: center;
  gap: 3px;
  flex-shrink: 0;
}

/* ===== 子任务进度 ===== */
.task-sub-progress {
  font-size: 10px;
  color: var(--text-tertiary);
  background: var(--bg-hover);
  padding: 1px 6px;
  border-radius: 8px;
  white-space: nowrap;
  flex-shrink: 0;
  font-weight: 500;
}

/* ===== 备注标签 ===== */
.task-note-tag {
  font-size: 10px;
  color: #22c55e;
  background: rgba(34, 197, 94, 0.1);
  padding: 1px 6px;
  border-radius: 8px;
  white-space: nowrap;
  flex-shrink: 0;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.15s;
  border: 0.5px solid rgba(34, 197, 94, 0.25);
}

.task-note-tag:hover {
  background: rgba(34, 197, 94, 0.18);
  border-color: #22c55e;
}

.task-note-tag.empty {
  color: var(--text-tertiary);
  background: var(--bg-hover);
  border-color: transparent;
}

.task-note-tag.empty:hover {
  color: #22c55e;
  background: rgba(34, 197, 94, 0.1);
}

.task-note-tag.sub {
  font-size: 9px;
  padding: 0 4px;
  cursor: default;
}

/* ===== 备注编辑面板 ===== */
.task-note-panel {
  padding: 6px 8px 6px 26px;
}

.task-note-panel-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 4px;
  font-size: 11px;
  font-weight: 500;
  color: var(--text-secondary);
}

.task-note-close {
  width: 18px;
  height: 18px;
  border: none;
  background: transparent;
  border-radius: 4px;
  cursor: pointer;
  font-size: 14px;
  color: var(--text-tertiary);
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.15s;
  padding: 0;
  line-height: 1;
}

.task-note-close:hover {
  background: var(--bg-hover);
  color: var(--text-primary);
}

.task-note-textarea {
  width: 100%;
  border: 0.5px solid var(--border);
  border-radius: 6px;
  padding: 8px 10px;
  font-size: 12px;
  font-family: var(--font);
  background: var(--bg-input);
  color: var(--text-primary);
  outline: none;
  resize: vertical;
  min-height: 50px;
  max-height: 120px;
  line-height: 1.5;
  transition: border-color 0.15s;
}

.task-note-textarea:focus {
  border-color: var(--accent);
  box-shadow: 0 0 0 2px var(--accent-light);
}

.task-note-textarea::placeholder {
  color: var(--text-placeholder);
}

/* ===== 拖动排序 ===== */
.task-row.dragging {
  opacity: 0.5;
  background: var(--accent-light);
  border-radius: 4px;
  cursor: grabbing;
}

.task-item:has(.task-row.dragging) {
  border-color: var(--accent);
  box-shadow: 0 2px 8px rgba(0,0,0,0.1);
}

/* 任务项微交互 */
.task-item {
  transition: all 0.15s ease;
}
.task-row {
  transition: background 0.15s ease, transform 0.1s ease;
}
.task-row:hover {
  transform: translateX(2px);
}
.task-row:active {
  transform: scale(0.99);
}
.task-check {
  transition: all 0.2s cubic-bezier(0.34, 1.56, 0.64, 1);
}
.task-check:hover {
  transform: scale(1.15);
}
.task-check:active {
  transform: scale(0.9);
}
.task-check.checked {
  animation: checkBounce 0.3s cubic-bezier(0.34, 1.56, 0.64, 1);
}
@keyframes checkBounce {
  0% { transform: scale(1); }
  50% { transform: scale(1.3); }
  100% { transform: scale(1); }
}

/* 筛选按钮动画 */
.filter-btn {
  transition: all var(--transition-fast);
}
.filter-btn:active {
  transform: scale(0.92);
}

/* 优先级圆点动画 */
.priority-dot-btn {
  transition: all 0.2s cubic-bezier(0.34, 1.56, 0.64, 1);
}
.priority-dot-btn:hover {
  transform: scale(1.2);
}
.priority-dot-btn:active {
  transform: scale(0.9);
}
</style>
