<h1 align="center">笺记 FloatNote</h1>
<p align="center">轻量级桌面便签笔记软件 · 记事本 & 待办事项 · Tauri 2 + Vue 3 + Rust</p>
<p align="center">
  <a href="https://github.com/flyanx/FloatNote/releases">下载</a> ·
  <a href="#功能特性">功能</a> ·
  <a href="#云同步使用说明">云同步</a> ·
  <a href="#安装">安装</a> ·
  <a href="CHANGELOG.md">更新日志</a>
</p>

---

笺记（FloatNote）是一款**轻量级 Windows 桌面笔记软件**，体积仅约 17MB，启动秒开。集**记事本、待办事项、屏幕截图、多格式导入导出**于一体，支持富文本与 Markdown 双模式编辑、8 种主题切换、窗口置顶与透明度调节，让随手记录像便签一样简单。

基于 [Tauri 2](https://tauri.app/) + [Vue 3](https://vuejs.org/) + [Rust](https://www.rust-lang.org/) 构建，相比 Electron 方案体积缩小 80% 以上，内存占用更低。

## 功能特性

### 笔记记事本

- **多记事本管理** — 创建多个记事本分类管理，子标签快速切换，支持重命名、颜色标记、锁定保护
- **富文本编辑器** — 加粗、斜体、下划线、删除线、7 档字号选择、一键清除格式
- **Markdown 编辑器** — 实时渲染，支持 GFM 语法、图片、表格、代码块高亮
- **笔记置顶** — 重要笔记固定在列表顶部，新建笔记不会挤掉置顶内容
- **颜色标签** — 为每条笔记设置颜色标识，快速分类定位
- **标题自动生成** — 未填写标题时自动提取正文前 20 字，拼音输入法兼容
- **字数统计** — 底部状态栏实时显示字符数、词数、行数、预估阅读时长
- **全文搜索** — 侧边栏搜索框，同时检索标题和正文内容
- **空状态引导** — 无笔记时显示友好提示，搜索无结果时给出对应引导

### 待办事项 Todo

- **多待办列表** — 创建多个待办事项列表，按项目或场景分类管理
- **未完成计数** — 列表标题栏实时显示未完成任务数量
- **列表管理** — 与记事本一致的锁定、颜色标记、重命名体验

### 屏幕截图工具

- **全屏截图选区** — 独立全屏窗口覆盖整个显示器（含任务栏），体验类似 QQ 截图
- **隐藏后截图** — 先自动隐藏主窗口再截图，避免截到应用自身
- **剪贴板写入** — 选区完成后自动复制到系统剪贴板，可直接粘贴到任意应用
- **快捷键触发** — 默认 Ctrl+Shift+A，可在设置中自定义

### 文件导入导出

- **多格式导入** — 支持 Markdown（.md）、纯文本（.txt）、HTML、Word（.docx）
- **多格式导出** — 支持 Markdown、TXT、HTML、Word、PDF
- **拖拽上传** — 图片文件直接拖入编辑器即可插入；文本文件拖入自动读取内容
- **操作进度提示** — 导入导出过程中显示 Toast 状态提示

### 界面与个性化

- **8 种主题** — 明亮、暗黑、暖纸、薄荷、樱花、雾蓝、奶咖、暖咖
- **窗口透明度** — 20% ~ 100% 自由调节，可融入桌面壁纸
- **窗口置顶** — 一键置顶，随时参考笔记内容
- **极简模式** — 隐藏标签栏，只保留核心编辑区域
- **无边框窗口** — 自定义标题栏，双击切换紧凑模式
- **系统托盘** — 关闭按钮收纳到托盘，不占用任务栏空间

### 数据安全与云同步

- **回收站** — 删除的记事本、待办列表、笔记保留 30 天，支持随时恢复
- **本地优先存储** — 所有数据保存在本地，隐私安全不依赖云端
- **Supabase 云同步** — 支持配置 Supabase 实现跨设备数据同步（详见下方说明）

---

## 云同步使用说明

笺记支持通过 [Supabase](https://supabase.com/) 实现跨设备数据同步，数据以加密形式存储在云端，仅在本地解密。

### 配置步骤

1. 注册 [Supabase](https://supabase.com/) 账号，创建一个新项目
2. 在项目中创建两张数据表：
   - `notes` 表：存储记事本数据（字段：`id`, `data`, `updated_at`）
   - `todos` 表：存储待办数据（字段：`id`, `data`, `updated_at`）
3. 开启 Row Level Security（RLS），建议配置为仅允许认证用户读写
4. 获取项目的 **URL** 和 **Anon Key**（在 Project Settings - API 页面中）
5. 打开笺记，点击标题栏的"云同步"按钮
6. 输入 URL 和 Anon Key，点击"测试连接"确认连通
7. 点击"推送"上传本地数据到云端，或点击"拉取"将云端数据同步到本地

### 注意事项

- 推送会覆盖云端数据，拉取会覆盖本地数据，操作前请确认
- 同步失败时状态栏显示错误信息和"重试"按钮
- 建议定期手动同步，当前版本不支持自动后台同步
- Anon Key 请妥善保管，不要分享给他人

---

## 安装

### 方式一：下载安装包（推荐）

前往 [Releases](https://github.com/flyanx/FloatNote/releases) 页面下载最新版本：

| 文件 | 说明 | 大小 |
|------|------|------|
| `笺记_x.x.x_x64-setup.exe` | NSIS 安装程序，支持开始菜单和桌面快捷方式 | ~9 MB |
| `floatnote.exe` | 便携版，免安装，下载后直接双击运行 | ~17 MB |

### 方式二：源码构建

前置环境要求：
- [Node.js](https://nodejs.org/) 18+
- [Rust](https://www.rust-lang.org/tools/install) 1.70+
- [WebView2](https://developer.microsoft.com/en-us/microsoft-edge/webview2/)（Windows 10/11 通常已内置）

```bash
git clone https://github.com/flyanx/FloatNote.git
cd FloatNote
npm install

# 开发模式（热更新）
npm run tauri dev

# 构建发布版
npm run tauri build
```

构建产物位于 `src-tauri/target/release/`。

---

## 快捷键

| 快捷键 | 功能 |
|---|---|
| Ctrl + N | 新建笔记 |
| Ctrl + S | 保存（自动保存已启用，一般无需手动触发） |
| Ctrl + B | 加粗（富文本模式） |
| Ctrl + I | 斜体（富文本模式） |
| Ctrl + U | 下划线（富文本模式） |
| Ctrl + Shift + V | 纯文本粘贴（富文本模式） |
| Ctrl + Shift + A | 截图（可在设置中自定义） |

---

## 技术栈

| 层级 | 技术 |
|---|---|
| 桌面框架 | [Tauri 2.x](https://tauri.app/) |
| 前端框架 | [Vue 3](https://vuejs.org/) (Composition API) |
| 构建工具 | [Vite 5](https://vite.dev/) |
| 后端语言 | [Rust](https://www.rust-lang.org/) |
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
│   ├── services/                 # 服务层
│   │   ├── syncService.js        # 云同步逻辑
│   │   └── syncState.js          # 同步状态管理
│   ├── App.vue                   # 应用壳（标题栏、主题、面板切换）
│   ├── ScreenshotWindow.vue      # 截图窗口（独立全屏）
│   ├── main.js                   # 主应用入口
│   └── style.css                 # 全局样式 + 主题变量
├── src-tauri/                    # Rust 后端
│   ├── src/main.rs               # Tauri 命令（截图、文件保存、云同步代理）
│   ├── Cargo.toml                # Rust 依赖
│   └── tauri.conf.json           # Tauri 配置
├── screenshot.html               # 截图窗口 HTML 入口
├── package.json                  # 前端依赖
└── vite.config.js                # Vite 配置
```

---

## 更新日志

### v1.3.0

- 截图功能重构为独立全屏窗口，真正覆盖整个显示器
- 新增空状态提示、笔记标题自动生成、字数统计面板
- 导入导出操作增加进度提示
- 云同步失败时增加重试按钮
- 支持拖拽文件（图片 / 文本）到编辑器
- 修复拼音输入法下标题自动生成异常
- 体积优化：exe 从 23MB 降至 17MB
- 应用更名：灵签 -> 笺记

### v1.2.0

- 支持多格式导入导出（Markdown / TXT / HTML / DOCX / PDF）
- 富文本编辑器增强
- 8 种主题切换
- 窗口置顶与透明度调节
- 系统托盘收纳

---

## 开发

```bash
# 启动开发服务器（前端热更新 + Tauri 窗口）
npm run tauri dev

# 仅构建前端
npm run build
```

---

## 许可证

[MIT License](LICENSE)

---

## 致谢

- [Tauri](https://tauri.app/) — 轻量级桌面应用框架
- [Vue.js](https://vuejs.org/) — 渐进式 JavaScript 框架
- [Vite](https://vite.dev/) — 下一代前端构建工具
