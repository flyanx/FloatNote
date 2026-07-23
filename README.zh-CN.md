<div align="center">
  <br>
  <img src="src-tauri/icons/icon.png" width="120" height="120" alt="FloatNote 图标">
  <br><br>
  <h1>笺记 FloatNote</h1>
  <p>轻量级 Windows 桌面便签笔记 · 记事本 & 待办事项</p>
  <p>
    <img src="https://img.shields.io/badge/版本-1.3.1-blue?style=flat-square" alt="version">
    <img src="https://img.shields.io/badge/平台-Windows-0078D6?style=flat-square&logo=windows" alt="platform">
    <img src="https://img.shields.io/badge/许可证-MIT-green?style=flat-square" alt="license">
    <img src="https://img.shields.io/badge/Tauri-2.0-24C8D8?style=flat-square&logo=tauri" alt="tauri">
    <img src="https://img.shields.io/badge/Vue-3.0-4FC08D?style=flat-square&logo=vue.js" alt="vue">
  </p>
  <p>
    <a href="README.md">English</a> · <a href="README.zh-CN.md">简体中文</a>
  </p>
  <p>
    <a href="https://github.com/flyanx/FloatNote/releases"><b>下载</b></a> ·
    <a href="#功能特性"><b>功能</b></a> ·
    <a href="#安装"><b>安装</b></a> ·
    <a href="#更新日志"><b>更新</b></a>
  </p>
  <br>
</div>

---

## 简介

**笺记（FloatNote）** 是一款轻量级 Windows 桌面笔记软件，体积仅约 17MB，启动秒开。集**记事本、待办事项、屏幕截图、多格式导入导出**于一体，支持富文本与 Markdown 双模式编辑、8 种主题切换、窗口透明度调节与置顶，让随手记录像便签一样简单自然。

基于 [Tauri 2](https://tauri.app/) + [Vue 3](https://vuejs.org/) + [Rust](https://www.rust-lang.org/) 构建，相比 Electron 方案体积缩小 80% 以上，内存占用更低。

---

## 功能特性

### 笔记

| 功能 | 说明 |
|---|---|
| 多记事本管理 | 创建多个记事本分类管理，支持重命名、颜色标记、锁定保护 |
| 富文本编辑器 | 加粗、斜体、下划线、删除线、7 档字号、一键清除格式 |
| Markdown 编辑器 | 实时渲染，支持 GFM、图片、表格、代码块高亮 |
| 笔记置顶 | 重要笔记固定在列表顶部 |
| 颜色标签 | 为每条笔记设置颜色标识，快速分类定位 |
| 标题自动生成 | 未填写标题时自动提取正文前 20 字 |
| 字数统计 | 底部状态栏实时显示字符数、词数、行数、预估阅读时长 |
| 全文搜索 | 侧边栏搜索框同时检索标题和正文内容 |

### 待办

| 功能 | 说明 |
|---|---|
| 多待办列表 | 创建多个待办事项列表，按项目或场景分类管理 |
| 未完成计数 | 列表标题栏实时显示未完成任务数量 |
| 列表管理 | 与记事本一致的锁定、颜色标记、重命名体验 |

### 截图

| 功能 | 说明 |
|---|---|
| 全屏截图选区 | 独立全屏窗口覆盖整个显示器（含任务栏） |
| 隐藏后截图 | 先自动隐藏主窗口再截图，避免截到应用自身 |
| 剪贴板写入 | 选区完成后自动复制到系统剪贴板 |
| 快捷键触发 | 默认 `Ctrl + Shift + A`，可在设置中自定义 |

### 导入导出

| 功能 | 说明 |
|---|---|
| 多格式导入 | 支持 Markdown（.md）、纯文本（.txt）、HTML、Word（.docx） |
| 多格式导出 | 支持 Markdown、TXT、HTML、Word、PDF |
| 拖拽上传 | 图片文件拖入编辑器直接插入；文本文件拖入自动读取内容 |

### 界面与个性化

| 特性 | 说明 |
|---|---|
| 8 种主题 | 明亮 / 暗黑 / 暖纸 / 薄荷 / 樱花 / 雾蓝 / 奶咖 / 暖咖 |
| 窗口透明度 | 20% ~ 100% 自由调节，原生 Windows 分层窗口实现 |
| 窗口置顶 | 一键置顶，随时参考笔记内容 |
| 极简模式 | 隐藏标签栏，只保留核心编辑区域 |
| 无边框窗口 | 自定义标题栏，双击切换紧凑模式 |
| 系统托盘 | 关闭按钮收纳到托盘，右键可快速新建笔记/待办 |
| 中英双语 | 一键切换界面语言（中文 / English） |

### 数据安全

| 功能 | 说明 |
|---|---|
| 回收站 | 删除的记事本、待办列表、笔记保留 30 天，支持随时恢复 |
| 本地优先存储 | 所有数据保存在本地，隐私安全不依赖云端 |
| Supabase 云同步 | 支持配置 Supabase 实现跨设备数据同步 |

---

## 安装

### 方式一：下载安装包（推荐）

前往 [Releases](https://github.com/flyanx/FloatNote/releases) 页面下载最新版本：

| 文件 | 说明 | 大小 |
|---|---|---|
| `笺记_x.x.x_x64-setup.exe` | NSIS 安装程序，支持开始菜单和桌面快捷方式 | ~7 MB |
| `floatnote.exe` | 便携版，免安装，下载后直接双击运行 | ~17 MB |

### 方式二：源码构建

```bash
# 1. 克隆仓库
git clone https://github.com/flyanx/FloatNote.git
cd FloatNote

# 2. 安装依赖
npm install

# 3. 开发模式（热更新）
npm run tauri dev

# 4. 构建发布版
npm run tauri build
```

构建产物位于 `src-tauri/target/release/`

**前置环境**：Node.js 18+、Rust 1.70+、WebView2（Windows 10/11 通常已内置）

---

## 快捷键

| 快捷键 | 功能 |
|---|---|
| `Ctrl + N` | 新建笔记 |
| `Ctrl + S` | 保存（自动保存已启用） |
| `Ctrl + B` | 加粗（富文本模式） |
| `Ctrl + I` | 斜体（富文本模式） |
| `Ctrl + U` | 下划线（富文本模式） |
| `Ctrl + Shift + V` | 纯文本粘贴 |
| `Ctrl + Shift + A` | 屏幕截图 |

---

## 技术栈

| 层级 | 技术 |
|---|---|
| 桌面框架 | [Tauri 2.x](https://tauri.app/) |
| 前端框架 | [Vue 3](https://vuejs.org/)（Composition API） |
| 构建工具 | [Vite 5](https://vite.dev/) |
| 后端语言 | [Rust](https://www.rust-lang.org/) |
| 国际化 | [vue-i18n](https://vue-i18n.intlify.dev/) |
| Markdown 渲染 | [marked](https://marked.js.org/) |
| Word 导出 | [docx](https://www.npmjs.com/package/docx) |
| Word 导入 | [mammoth](https://www.npmjs.com/package/mammoth) |
| 屏幕截图 | [xcap](https://github.com/nashaofu/xcap) |
| 剪贴板 | [arboard](https://github.com/1Password/arboard) |

---

## 项目结构

```
FloatNote/
├── src/                          # 前端源码（Vue 3）
│   ├── components/               # Vue 组件
│   │   ├── NotePanel.vue         # 记事本面板
│   │   ├── TodoPanel.vue         # 待办事项面板
│   │   ├── SyncPanel.vue         # 云同步面板
│   │   ├── ScreenshotOverlay.vue # 截图选区覆盖层
│   │   └── TrashPanel.vue        # 回收站面板
│   ├── composables/              # 组合式函数
│   │   ├── useClickOutside.js    # 外部点击检测
│   │   ├── useCollectionManager.js # 集合管理
│   │   ├── useContextMenu.js     # 右键菜单
│   │   ├── useDragSort.js        # 拖拽排序
│   │   ├── useInlineRename.js    # 行内重命名
│   │   └── useToast.js           # 提示通知
│   ├── i18n/                     # 国际化资源
│   │   ├── index.js
│   │   ├── zh.json               # 中文语言包
│   │   └── en.json               # 英文语言包
│   ├── services/                 # 服务层
│   │   ├── syncService.js        # 云同步逻辑
│   │   └── syncState.js          # 同步状态管理
│   ├── utils/                    # 工具函数
│   │   ├── colors.js             # 颜色工具
│   │   ├── date.js               # 日期工具
│   │   ├── id.js                 # ID 生成
│   │   ├── storage.js            # 本地存储
│   │   └── trash.js              # 回收站逻辑
│   ├── App.vue                   # 应用壳（标题栏、主题、面板切换）
│   ├── ScreenshotWindow.vue      # 截图窗口（独立全屏）
│   ├── main.js                   # 主应用入口
│   └── style.css                 # 全局样式 + 主题变量
├── src-tauri/                    # Rust 后端
│   ├── src/main.rs               # Tauri 命令
│   ├── Cargo.toml                # Rust 依赖
│   ├── tauri.conf.json           # Tauri 配置
│   └── icons/                    # 应用图标
├── public/                       # 静态资源
├── screenshot.html               # 截图窗口 HTML 入口
├── package.json                  # 前端依赖
└── vite.config.js                # Vite 配置
```

---

## 更新日志

### v1.3.1

- 新增中英双语界面，一键切换
- 窗口透明度改用原生 Windows 分层窗口 API，效果更自然
- 系统托盘右键菜单新增「新建笔记」「新建待办」快捷入口
- 统一应用图标：exe / 任务栏 / 托盘 / 窗口左上角均使用同一图标
- 修复前端资源未正确加载导致的透明框问题
- 优化窗口启动显示逻辑，加载完成后再展示界面

### v1.3.0

- 截图功能重构为独立全屏窗口，真正覆盖整个显示器
- 新增空状态提示、笔记标题自动生成、字数统计面板
- 导入导出操作增加进度提示
- 云同步失败时增加重试按钮
- 支持拖拽文件（图片 / 文本）到编辑器
- 修复拼音输入法下标题自动生成异常
- 体积优化：exe 从 23MB 降至 17MB
- 应用更名：灵签 → 笺记

### v1.2.0

- 支持多格式导入导出（Markdown / TXT / HTML / DOCX / PDF）
- 富文本编辑器增强
- 8 种主题切换
- 窗口置顶与透明度调节
- 系统托盘收纳

---

## 许可证

[MIT 许可证](LICENSE)

---

## 致谢

- [Tauri](https://tauri.app/) — 轻量级桌面应用框架
- [Vue.js](https://vuejs.org/) — 渐进式 JavaScript 框架
- [Vite](https://vite.dev/) — 下一代前端构建工具
- [Rust](https://www.rust-lang.org/) — 安全、并发、实用的系统编程语言
