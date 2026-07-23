<div align="center">
  <br>
  <img src="src-tauri/icons/icon.png" width="120" height="120" alt="FloatNote Logo">
  <br><br>
  <h1>FloatNote</h1>
  <p>A lightweight Windows desktop note-taking app — Notebook, To-Do, Screenshot & More</p>
  <p>
    <img src="https://img.shields.io/badge/version-1.3.1-blue?style=flat-square" alt="version">
    <img src="https://img.shields.io/badge/platform-Windows-0078D6?style=flat-square&logo=windows" alt="platform">
    <img src="https://img.shields.io/badge/license-MIT-green?style=flat-square" alt="license">
    <img src="https://img.shields.io/badge/Tauri-2.0-24C8D8?style=flat-square&logo=tauri" alt="tauri">
    <img src="https://img.shields.io/badge/Vue-3.0-4FC08D?style=flat-square&logo=vue.js" alt="vue">
  </p>
  <p><a href="README.md">English</a> · <a href="README.zh-CN.md">简体中文</a></p>
  <p>
    <a href="https://github.com/flyanx/FloatNote/releases"><b>Download</b></a> ·
    <a href="#features"><b>Features</b></a> ·
    <a href="#installation"><b>Install</b></a> ·
    <a href="#changelog"><b>Changelog</b></a>
  </p>
  <br>
</div>

---

## Introduction

**FloatNote** is a lightweight Windows desktop note-taking app (~17 MB) that launches instantly. It combines **notebooks, to-do lists, screen capture, and multi-format import/export** in one place, with both rich-text and Markdown dual-mode editing, 8 theme options, window transparency and always-on-top — making quick note-taking as simple and natural as a sticky note.

Built with [Tauri 2](https://tauri.app/) + [Vue 3](https://vuejs.org/) + [Rust](https://www.rust-lang.org/), it is 80%+ smaller than comparable Electron apps and uses significantly less memory.

---

## Features

### Notes

| Feature | Description |
|---|---|
| Multi-Notebook | Create multiple notebooks with rename, color labels, and lock protection |
| Rich Text Editor | Bold, italic, underline, strikethrough, 7 font sizes, clear formatting |
| Markdown Editor | Live preview with GFM, images, tables, and code highlighting |
| Pin Notes | Pin important notes to the top of the list |
| Color Labels | Color-code notes for quick visual categorization |
| Auto Title | Auto-extract first 20 characters as title when left blank |
| Word Count | Real-time character, word, line count and estimated reading time |
| Full-Text Search | Search across titles and content from the sidebar |

### To-Do

| Feature | Description |
|---|---|
| Multiple Lists | Create multiple to-do lists grouped by project or context |
| Pending Count | Show pending task count in the list header |
| List Management | Lock, color label, and rename lists |

### Screenshot

| Feature | Description |
|---|---|
| Full-Screen Capture | Standalone fullscreen window covering the entire display including taskbar |
| Hide & Capture | Auto-hide main window before capturing to avoid capturing the app itself |
| Clipboard Copy | Auto-copy selected region to clipboard |
| Hotkey | Default `Ctrl + Shift + A`, customizable in settings |

### Import & Export

| Feature | Description |
|---|---|
| Import | Markdown (.md), plain text (.txt), HTML, Word (.docx) |
| Export | Markdown, TXT, HTML, Word, PDF |
| Drag & Drop | Drag images to insert; drag text files to import content |

### UI & Personalization

| Feature | Description |
|---|---|
| 8 Themes | Light / Dark / Warm Paper / Mint / Sakura / Mist Blue / Milk Coffee / Warm Coffee |
| Transparency | 20%–100% adjustable via native Windows layered window API |
| Always on Top | Pin window on top with one click |
| Minimal Mode | Hide tab bar, keep only the core editor |
| Frameless Window | Custom title bar, double-click to toggle compact mode |
| System Tray | Minimize to tray; right-click for quick note/to-do creation |
| Bilingual UI | Switch UI language with one click (English / Chinese) |

### Data & Sync

| Feature | Description |
|---|---|
| Trash | Deleted items kept for 30 days with restore support |
| Local-First | All data stored locally, no cloud dependency |
| Supabase Sync | Optional Supabase sync for cross-device data |

---

## Installation

### Option 1: Download Installer (Recommended)

Download the latest release from [Releases](https://github.com/flyanx/FloatNote/releases):

| File | Description | Size |
|---|---|---|
| `FloatNote_x.x.x_x64-setup.exe` | NSIS installer with Start Menu & desktop shortcuts | ~7 MB |
| `floatnote.exe` | Portable edition, no install needed — just double-click to run | ~17 MB |

### Option 2: Build from Source

```bash
# 1. Clone the repo
git clone https://github.com/flyanx/FloatNote.git
cd FloatNote

# 2. Install dependencies
npm install

# 3. Dev mode (hot reload)
npm run tauri dev

# 4. Build for production
npm run tauri build
```

Build output: `src-tauri/target/release/`

**Prerequisites**: Node.js 18+, Rust 1.70+, WebView2 (usually pre-installed on Windows 10/11)

---

## Shortcuts

| Shortcut | Function |
|---|---|
| `Ctrl + N` | New Note |
| `Ctrl + S` | Save (auto-save enabled) |
| `Ctrl + B` | Bold (rich text mode) |
| `Ctrl + I` | Italic (rich text mode) |
| `Ctrl + U` | Underline (rich text mode) |
| `Ctrl + Shift + V` | Paste as plain text |
| `Ctrl + Shift + A` | Screenshot |

---

## Tech Stack

| Layer | Technology |
|---|---|
| Desktop Framework | [Tauri 2.x](https://tauri.app/) |
| Frontend Framework | [Vue 3](https://vuejs.org/) (Composition API) |
| Build Tool | [Vite 5](https://vite.dev/) |
| Backend Language | [Rust](https://www.rust-lang.org/) |
| i18n | [vue-i18n](https://vue-i18n.intlify.dev/) |
| Markdown Rendering | [marked](https://marked.js.org/) |
| Word Export | [docx](https://www.npmjs.com/package/docx) |
| Word Import | [mammoth](https://www.npmjs.com/package/mammoth) |
| Screenshot | [xcap](https://github.com/nashaofu/xcap) |
| Clipboard | [arboard](https://github.com/1Password/arboard) |

---

## Project Structure

```
FloatNote/
├── src/                          # Frontend source (Vue 3)
│   ├── components/               # Vue components
│   │   ├── NotePanel.vue         # Notebook panel
│   │   ├── TodoPanel.vue         # To-do panel
│   │   ├── SyncPanel.vue         # Cloud sync panel
│   │   ├── ScreenshotOverlay.vue # Screenshot overlay
│   │   └── TrashPanel.vue        # Trash panel
│   ├── composables/              # Vue composables
│   │   ├── useClickOutside.js    # Click-outside detection
│   │   ├── useCollectionManager.js # Collection management
│   │   ├── useContextMenu.js     # Context menu
│   │   ├── useDragSort.js        # Drag-and-drop sorting
│   │   ├── useInlineRename.js    # Inline rename
│   │   └── useToast.js           # Toast notifications
│   ├── i18n/                     # i18n resources
│   │   ├── index.js
│   │   ├── zh.json               # Chinese locale
│   │   └── en.json               # English locale
│   ├── services/                 # Service layer
│   │   ├── syncService.js        # Cloud sync logic
│   │   └── syncState.js          # Sync state management
│   ├── utils/                    # Utilities
│   │   ├── colors.js             # Color utilities
│   │   ├── date.js               # Date utilities
│   │   ├── id.js                 # ID generation
│   │   ├── storage.js            # Local storage
│   │   └── trash.js              # Trash logic
│   ├── App.vue                   # App shell (title bar, theme, panel switching)
│   ├── ScreenshotWindow.vue      # Screenshot window (standalone fullscreen)
│   ├── main.js                   # Main app entry
│   └── style.css                 # Global styles + theme variables
├── src-tauri/                    # Rust backend
│   ├── src/main.rs               # Tauri commands
│   ├── Cargo.toml                # Rust dependencies
│   ├── tauri.conf.json           # Tauri configuration
│   └── icons/                    # App icons
├── public/                       # Static assets
├── screenshot.html               # Screenshot window HTML entry
├── package.json                  # Frontend dependencies
└── vite.config.js                # Vite configuration
```

---

## Changelog

### v1.3.1

- Added bilingual UI (English / Chinese) with one-click language switch
- Window transparency now uses native Windows `SetLayeredWindowAttributes` API
- Added "New Note" and "New To-Do" to system tray context menu
- Unified app icon across exe, taskbar, tray, and title bar
- Fixed transparent frame bug caused by frontend resources not loading correctly
- Improved startup: window shown only after initialization completes

### v1.3.0

- Screenshot rewritten as a standalone fullscreen window covering the entire display
- Added empty-state hints, auto title generation, and word count panel
- Added progress indicators for import/export operations
- Added retry button when cloud sync fails
- Added drag-and-drop support for images and text files into the editor
- Fixed auto title generation bug with Pinyin IME
- Size optimized: exe reduced from 23 MB to 17 MB
- Renamed: LingQian -> FloatNote

### v1.2.0

- Multi-format import/export (Markdown / TXT / HTML / DOCX / PDF)
- Enhanced rich-text editor
- 8 theme options
- Always-on-top and adjustable transparency
- System tray support

---

## License

[MIT License](LICENSE)

---

## Acknowledgements

- [Tauri](https://tauri.app/) — Lightweight desktop app framework
- [Vue.js](https://vuejs.org/) — The Progressive JavaScript Framework
- [Vite](https://vite.dev/) — Next-generation frontend build tool
- [Rust](https://www.rust-lang.org/) — A safe, concurrent, and practical systems language
