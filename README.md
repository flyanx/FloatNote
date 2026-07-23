<div align="center">
  <br>
  <img src="src-tauri/icons/icon.png" width="120" height="120" alt="FloatNote Logo">
  <br><br>
  <h1>笺记 FloatNote</h1>
  <p>轻量级 Windows 桌面便签笔记 · 记事本 & 待办事项</p>
  <p><b>A lightweight Windows desktop sticky note app — Notebook & To-Do</b></p>
  <p>
    <img src="https://img.shields.io/badge/version-1.3.1-blue?style=flat-square" alt="version">
    <img src="https://img.shields.io/badge/platform-Windows-0078D6?style=flat-square&logo=windows" alt="platform">
    <img src="https://img.shields.io/badge/license-MIT-green?style=flat-square" alt="license">
    <img src="https://img.shields.io/badge/Tauri-2.0-24C8D8?style=flat-square&logo=tauri" alt="tauri">
    <img src="https://img.shields.io/badge/Vue-3.0-4FC08D?style=flat-square&logo=vue.js" alt="vue">
  </p>
  <p>
    <a href="https://github.com/flyanx/FloatNote/releases"><b>下载 Download</b></a> ·
    <a href="#功能特性--features"><b>功能 Features</b></a> ·
    <a href="#安装--installation"><b>安装 Install</b></a> ·
    <a href="#更新日志--changelog"><b>更新 Changelog</b></a>
  </p>
  <br>
</div>

---

## 简介 | Introduction

**笺记（FloatNote）** 是一款轻量级 Windows 桌面笔记软件，体积仅约 17MB，启动秒开。集**记事本、待办事项、屏幕截图、多格式导入导出**于一体，支持富文本与 Markdown 双模式编辑、8 种主题切换、窗口透明度调节与置顶，让随手记录像便签一样简单自然。

基于 [Tauri 2](https://tauri.app/) + [Vue 3](https://vuejs.org/) + [Rust](https://www.rust-lang.org/) 构建，相比 Electron 方案体积缩小 80% 以上，内存占用更低。

**FloatNote** is a lightweight Windows desktop note-taking app, only ~17 MB and launches instantly. It combines **notebooks, to-do lists, screen capture, and multi-format import/export** in one place, with both rich-text and Markdown editing, 8 theme options, window transparency and always-on-top — making quick note-taking as simple and natural as a sticky note.

Built with [Tauri 2](https://tauri.app/) + [Vue 3](https://vuejs.org/) + [Rust](https://www.rust-lang.org/), it is 80%+ smaller than comparable Electron apps and uses significantly less memory.

---

## 功能特性 | Features

### 笔记 | Notes

| 功能 Feature | 说明 Description |
|---|---|
| 多记事本管理 Multi-Notebook | 创建多个记事本分类管理，支持重命名、颜色标记、锁定保护 — Create multiple notebooks with rename, color labels, and lock protection |
| 富文本编辑器 Rich Text Editor | 加粗、斜体、下划线、删除线、7 档字号、一键清除格式 — Bold, italic, underline, strikethrough, 7 font sizes, clear formatting |
| Markdown 编辑器 Markdown Editor | 实时渲染，支持 GFM、图片、表格、代码块高亮 — Live preview with GFM, images, tables, code highlighting |
| 笔记置顶 Pin Notes | 重要笔记固定在列表顶部 — Pin important notes to the top of the list |
| 颜色标签 Color Labels | 为每条笔记设置颜色标识，快速分类定位 — Color-code notes for quick visual categorization |
| 标题自动生成 Auto Title | 未填写标题时自动提取正文前 20 字 — Auto-extract first 20 characters as title when left blank |
| 字数统计 Word Count | 底部状态栏实时显示字符数、词数、行数、预估阅读时长 — Real-time character, word, line count and estimated reading time |
| 全文搜索 Full-Text Search | 侧边栏搜索框同时检索标题和正文内容 — Search across titles and content from the sidebar |

### 待办 | To-Do

| 功能 Feature | 说明 Description |
|---|---|
| 多待办列表 Multiple Lists | 创建多个待办事项列表，按项目或场景分类管理 — Create multiple to-do lists grouped by project or context |
| 未完成计数 Pending Count | 列表标题栏实时显示未完成任务数量 — Show pending task count in the list header |
| 列表管理 List Management | 与记事本一致的锁定、颜色标记、重命名体验 — Same lock, color label, and rename experience as notebooks |

### 截图 | Screenshot

| 功能 Feature | 说明 Description |
|---|---|
| 全屏截图选区 Full-Screen Capture | 独立全屏窗口覆盖整个显示器（含任务栏） — Standalone fullscreen window covering the entire display including taskbar |
| 隐藏后截图 Hide & Capture | 先自动隐藏主窗口再截图，避免截到应用自身 — Auto-hide main window before capturing |
| 剪贴板写入 Clipboard | 选区完成后自动复制到系统剪贴板 — Auto-copy selected region to clipboard |
| 快捷键触发 Hotkey | 默认 `Ctrl + Shift + A`，可在设置中自定义 — Default `Ctrl + Shift + A`, customizable in settings |

### 导入导出 | Import & Export

| 功能 Feature | 说明 Description |
|---|---|
| 多格式导入 Import | Markdown（.md）、纯文本（.txt）、HTML、Word（.docx） |
| 多格式导出 Export | Markdown、TXT、HTML、Word、PDF |
| 拖拽上传 Drag & Drop | 图片文件拖入编辑器直接插入；文本文件拖入自动读取内容 — Drag images to insert, drag text files to import content |

### 界面 | UI & Personalization

| 特性 Feature | 说明 Description |
|---|---|
| 8 种主题 8 Themes | 明亮 / 暗黑 / 暖纸 / 薄荷 / 樱花 / 雾蓝 / 奶咖 / 暖咖 — Light / Dark / Warm Paper / Mint / Sakura / Mist Blue / Milk Coffee / Warm Coffee |
| 窗口透明度 Transparency | 20% ~ 100% 自由调节，原生 Windows 分层窗口实现 — 20%–100% adjustable via native Windows layered window API |
| 窗口置顶 Always on Top | 一键置顶，随时参考笔记内容 — Pin window on top with one click |
| 极简模式 Minimal Mode | 隐藏标签栏，只保留核心编辑区域 — Hide tab bar, keep only the editor |
| 无边框窗口 Frameless Window | 自定义标题栏，双击切换紧凑模式 — Custom title bar, double-click to toggle compact mode |
| 系统托盘 System Tray | 关闭按钮收纳到托盘，右键可快速新建笔记/待办 — Minimize to tray; right-click for quick note/to-do creation |
| 中英双语 Bilingual UI | 一键切换界面语言（中文 / English） — Switch UI language with one click |

### 数据安全 | Data & Sync

| 功能 Feature | 说明 Description |
|---|---|
| 回收站 Trash | 删除的记事本、待办列表、笔记保留 30 天，支持随时恢复 — Deleted items kept for 30 days with restore support |
| 本地优先存储 Local-First | 所有数据保存在本地，隐私安全不依赖云端 — All data stored locally, no cloud dependency |
| Supabase 云同步 Cloud Sync | 支持配置 Supabase 实现跨设备数据同步 — Optional Supabase sync for cross-device data |

---

## 安装 | Installation

### 方式一：下载安装包 | Option 1: Download Installer (Recommended)

前往 [Releases](https://github.com/flyanx/FloatNote/releases) 页面下载最新版本 / Download the latest release from [Releases](https://github.com/flyanx/FloatNote/releases):

| 文件 File | 说明 Description | 大小 Size |
|---|---|---|
| `笺记_x.x.x_x64-setup.exe` | NSIS 安装程序，支持开始菜单和桌面快捷方式 — NSIS installer with Start Menu & desktop shortcuts | ~7 MB |
| `floatnote.exe` | 便携版，免安装，下载后直接双击运行 — Portable edition, no install needed | ~17 MB |

### 方式二：源码构建 | Option 2: Build from Source

```bash
# 1. 克隆仓库 / Clone the repo
git clone https://github.com/flyanx/FloatNote.git
cd FloatNote

# 2. 安装依赖 / Install dependencies
npm install

# 3. 开发模式（热更新）/ Dev mode (hot reload)
npm run tauri dev

# 4. 构建发布版 / Build for production
npm run tauri build
```

构建产物位于 `src-tauri/target/release/` / Build output: `src-tauri/target/release/`

**前置环境 / Prerequisites**：Node.js 18+、Rust 1.70+、WebView2（Windows 10/11 通常已内置 / usually pre-installed on Windows 10/11）

---

## 快捷键 | Shortcuts

| 快捷键 Shortcut | 功能 Function | 功能 Function (EN) |
|---|---|---|
| `Ctrl + N` | 新建笔记 | New Note |
| `Ctrl + S` | 保存（自动保存已启用） | Save (auto-save enabled) |
| `Ctrl + B` | 加粗（富文本模式） | Bold (rich text mode) |
| `Ctrl + I` | 斜体（富文本模式） | Italic (rich text mode) |
| `Ctrl + U` | 下划线（富文本模式） | Underline (rich text mode) |
| `Ctrl + Shift + V` | 纯文本粘贴 | Paste as plain text |
| `Ctrl + Shift + A` | 屏幕截图 | Screenshot |

---

## 技术栈 | Tech Stack

| 层级 Layer | 技术 Technology |
|---|---|
| 桌面框架 Desktop Framework | [Tauri 2.x](https://tauri.app/) |
| 前端框架 Frontend Framework | [Vue 3](https://vuejs.org/) (Composition API) |
| 构建工具 Build Tool | [Vite 5](https://vite.dev/) |
| 后端语言 Backend Language | [Rust](https://www.rust-lang.org/) |
| 国际化 i18n | [vue-i18n](https://vue-i18n.intlify.dev/) |
| Markdown 渲染 Markdown Rendering | [marked](https://marked.js.org/) |
| Word 导出 Word Export | [docx](https://www.npmjs.com/package/docx) |
| Word 导入 Word Import | [mammoth](https://www.npmjs.com/package/mammoth) |
| 屏幕截图 Screenshot | [xcap](https://github.com/nashaofu/xcap) |
| 剪贴板 Clipboard | [arboard](https://github.com/1Password/arboard) |

---

## 项目结构 | Project Structure

```
FloatNote/
├── src/                          # 前端源码（Vue 3）/ Frontend source (Vue 3)
│   ├── components/               # Vue 组件 / Vue components
│   │   ├── NotePanel.vue         # 记事本面板 / Notebook panel
│   │   ├── TodoPanel.vue         # 待办事项面板 / To-do panel
│   │   ├── SyncPanel.vue         # 云同步面板 / Cloud sync panel
│   │   ├── ScreenshotOverlay.vue # 截图选区覆盖层 / Screenshot overlay
│   │   └── TrashPanel.vue        # 回收站面板 / Trash panel
│   ├── composables/              # 组合式函数 / Vue composables
│   │   ├── useClickOutside.js    # 外部点击检测 / Click-outside detection
│   │   ├── useCollectionManager.js # 集合管理 / Collection management
│   │   ├── useContextMenu.js     # 右键菜单 / Context menu
│   │   ├── useDragSort.js        # 拖拽排序 / Drag-and-drop sorting
│   │   ├── useInlineRename.js    # 行内重命名 / Inline rename
│   │   └── useToast.js           # 提示通知 / Toast notifications
│   ├── i18n/                     # 国际化资源 / i18n resources
│   │   ├── index.js
│   │   ├── zh.json               # 中文语言包 / Chinese locale
│   │   └── en.json               # 英文语言包 / English locale
│   ├── services/                 # 服务层 / Service layer
│   │   ├── syncService.js        # 云同步逻辑 / Cloud sync logic
│   │   └── syncState.js          # 同步状态管理 / Sync state management
│   ├── utils/                    # 工具函数 / Utilities
│   │   ├── colors.js             # 颜色工具 / Color utilities
│   │   ├── date.js               # 日期工具 / Date utilities
│   │   ├── id.js                 # ID 生成 / ID generation
│   │   ├── storage.js            # 本地存储 / Local storage
│   │   └── trash.js              # 回收站逻辑 / Trash logic
│   ├── App.vue                   # 应用壳（标题栏、主题、面板切换）/ App shell
│   ├── ScreenshotWindow.vue      # 截图窗口（独立全屏）/ Screenshot window (standalone fullscreen)
│   ├── main.js                   # 主应用入口 / Main app entry
│   └── style.css                 # 全局样式 + 主题变量 / Global styles + theme variables
├── src-tauri/                    # Rust 后端 / Rust backend
│   ├── src/main.rs               # Tauri 命令 / Tauri commands
│   ├── Cargo.toml                # Rust 依赖 / Rust dependencies
│   ├── tauri.conf.json           # Tauri 配置 / Tauri configuration
│   └── icons/                    # 应用图标 / App icons
├── public/                       # 静态资源 / Static assets
├── screenshot.html               # 截图窗口 HTML 入口 / Screenshot window HTML entry
├── package.json                  # 前端依赖 / Frontend dependencies
└── vite.config.js                # Vite 配置 / Vite configuration
```

---

## 更新日志 | Changelog

### v1.3.1

- 新增中英双语界面，一键切换 / Added bilingual UI with one-click language switching
- 窗口透明度改用原生 Windows 分层窗口 API，效果更自然 / Switched to native Windows layered window API for smoother transparency
- 系统托盘右键菜单新增「新建笔记」「新建待办」快捷入口 / Added "New Note" and "New To-Do" entries to the system tray context menu
- 统一应用图标：exe / 任务栏 / 托盘 / 窗口左上角均使用同一图标 / Unified app icon across exe, taskbar, tray, and window title bar
- 修复前端资源未正确加载导致的透明框问题 / Fixed transparent frame issue caused by frontend resources not loading correctly
- 优化窗口启动显示逻辑，加载完成后再展示界面 / Improved startup display logic — UI shown only after loading completes

### v1.3.0

- 截图功能重构为独立全屏窗口，真正覆盖整个显示器 / Rewrote screenshot as a standalone fullscreen window covering the entire display
- 新增空状态提示、笔记标题自动生成、字数统计面板 / Added empty-state hints, auto title generation, and word count panel
- 导入导出操作增加进度提示 / Added progress indicators for import/export operations
- 云同步失败时增加重试按钮 / Added retry button when cloud sync fails
- 支持拖拽文件（图片 / 文本）到编辑器 / Added drag-and-drop support for images and text files into the editor
- 修复拼音输入法下标题自动生成异常 / Fixed auto title generation bug with Pinyin IME
- 体积优化：exe 从 23MB 降至 17MB / Size optimization: exe reduced from 23 MB to 17 MB
- 应用更名：灵签 → 笺记 / App renamed: 灵签 → 笺记 (FloatNote)

### v1.2.0

- 支持多格式导入导出（Markdown / TXT / HTML / DOCX / PDF）/ Multi-format import/export (Markdown / TXT / HTML / DOCX / PDF)
- 富文本编辑器增强 / Enhanced rich-text editor
- 8 种主题切换 / 8 theme options
- 窗口置顶与透明度调节 / Always-on-top and adjustable transparency
- 系统托盘收纳 / System tray support

---

## 许可证 | License

[MIT License](LICENSE)

---

## 致谢 | Acknowledgements

- [Tauri](https://tauri.app/) — 轻量级桌面应用框架 / Lightweight desktop app framework
- [Vue.js](https://vuejs.org/) — 渐进式 JavaScript 框架 / The Progressive JavaScript Framework
- [Vite](https://vite.dev/) — 下一代前端构建工具 / Next-generation frontend build tool
- [Rust](https://www.rust-lang.org/) — 安全、并发、实用的系统编程语言 / A safe, concurrent, and practical systems language
