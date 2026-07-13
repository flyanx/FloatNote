# 笺记 FloatNote

> 轻盈桌面便签 — 记事本 & 待办事项，随手记录，随时可达

笺记是一款基于 Tauri 2 + Vue 3 构建的桌面笔记应用，体积小巧（约 17MB）、启动迅速，支持富文本与 Markdown 双模式编辑，多主题切换，窗口置顶与透明度调节，让笔记像便签一样随手可用。

---

## 功能特性

### 记事本

- **多记事本管理** — 创建多个记事本，子标签切换，支持重命名、颜色标记、锁定
- **富文本编辑** — 加粗、斜体、下划线、字号选择（7 档）、清除格式
- **Markdown 模式** — 实时渲染，支持 GFM、图片、表格、代码块
- **笔记置顶** — 重要笔记固定在顶部，新建笔记不会挤掉置顶
- **笔记标签颜色** — 为每条笔记设置颜色标识
- **标题自动生成** — 未填写标题时，自动提取正文前 20 字作为标题
- **字数统计面板** — 底部状态栏实时显示字符数 / 词数 / 行数 / 预估阅读时长
- **笔记搜索** — 侧边栏底部搜索框，支持标题和内容全文检索
- **空状态提示** — 无笔记时显示友好引导，搜索无结果时显示对应提示

### 待办事项

- **多列表管理** — 创建多个待办列表，分类管理
- **待办计数** — 标题栏实时显示未完成数量
- **列表锁定 / 颜色** — 与记事本一致的标签管理体验

### 截图功能

- **直接截图** — 截取当前屏幕，在独立全屏窗口中选区，支持 Esc 取消
- **隐藏后截图** — 先自动隐藏主窗口，再截图，避免截到应用自身
- **截图写入剪贴板** — 选区完成后自动复制到剪贴板，可直接粘贴使用
- **全屏覆盖** — 截图窗口为独立非透明全屏窗口，真正覆盖整个显示器（含任务栏），体验类似 QQ 截图

### 导入与导出

- **多格式导入** — 支持 Markdown / TXT / HTML / DOCX（Word）
- **多格式导出** — 支持 Markdown / TXT / HTML / DOCX / PDF
- **导入 / 导出进度提示** — 操作过程中显示 Toast 提示，大文件也不会让用户困惑
- **拖拽上传** — 图片文件直接拖入编辑器即可插入；文本文件拖入可直接读取内容

### 界面与交互

- **8 种主题** — 明亮、暗黑、暖纸、薄荷、樱花、雾蓝、奶咖、暖咖
- **窗口透明度** — 20% ~ 100% 自由调节，融入桌面背景
- **窗口置顶** — 一键置顶，随时参考
- **极简模式** — 隐藏标签栏，只保留核心编辑区
- **自定义标题栏** — 无边框窗口，双击标题栏切换紧凑模式
- **系统托盘** — 关闭按钮收纳到托盘，不占用任务栏
- **标签栏空位右键** — 快速新建记事本 / 待办页

### 数据安全与同步

- **回收站** — 删除的记事本 / 待办页 / 笔记保留 30 天，可随时恢复
- **本地存储** — 所有数据保存在本地，隐私安全
- **云同步** — 支持配置 Supabase 远程同步，跨设备使用（详见下方云同步说明）

---

## 云同步使用说明

笺记支持通过 Supabase 实现跨设备数据同步。数据以加密形式存储在云端，仅在本地解密。

### 配置步骤

1. 注册 [Supabase](https://supabase.com/) 账号，创建一个新项目
2. 在项目中创建两张表：
   - `notes` 表：存储记事本数据（字段：`id`, `data`, `updated_at`）
   - `todos` 表：存储待办数据（字段：`id`, `data`, `updated_at`）
3. 开启 Row Level Security（RLS），建议配置为仅允许认证用户读写
4. 获取项目的 **URL** 和 **Anon Key**（在 Project Settings -> API 中）
5. 打开笺记，点击标题栏的 "云同步" 按钮
6. 输入 URL 和 Key，点击"测试连接"确认可用
7. 点击"推送"将本地数据上传到云端，或点击"拉取"将云端数据同步到本地

### 注意事项

- 推送操作会覆盖云端数据，拉取操作会覆盖本地数据，请谨慎操作
- 同步失败时状态栏会显示错误信息和"重试"按钮
- 建议定期手动同步，目前不支持自动后台同步
- Anon Key 请妥善保管，不要分享给他人

---

## 安装

### 方式一：下载安装包（推荐）

前往 [Releases](../../releases) 页面下载最新版本：

- **Windows 安装包**：`笺记_x.x.x_x64-setup.exe`（NSIS 安装程序，支持安装到开始菜单和桌面快捷方式）
- **Windows 便携版**：`floatnote.exe`（免安装，下载后直接双击运行）

### 方式二：源码构建

需要以下环境：
- [Node.js](https://nodejs.org/) 18+
- [Rust](https://www.rust-lang.org/tools/install) 1.70+
- [WebView2](https://developer.microsoft.com/en-us/microsoft-edge/webview2/)（Windows 10/11 已内置）

```bash
# 克隆仓库
git clone https://github.com/flyanx/FloatNote.git
cd FloatNote

# 安装依赖
npm install

# 开发模式
npm run tauri dev

# 构建发布版
npm run tauri build
```

构建产物位于 `src-tauri/target/release/`：
- `floatnote.exe` — 可执行文件（便携版）
- `bundle/nsis/笺记_x.x.x_x64-setup.exe` — NSIS 安装包

---

## 快捷键

| 快捷键 | 功能 |
|---|---|
| Ctrl + N | 新建笔记 |
| Ctrl + S | 保存（自动保存，一般无需手动触发） |
| Ctrl + B | 加粗（富文本模式） |
| Ctrl + I | 斜体（富文本模式） |
| Ctrl + U | 下划线（富文本模式） |
| Ctrl + Shift + V | 纯文本粘贴（富文本模式） |
| Ctrl + Shift + A | 截图（可自定义） |

截图快捷键可在应用设置中修改。

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
| 截图 | [xcap](https://github.com/nashaofu/xcap) |
| 剪贴板 | [arboard](https://github.com/1Password/arboard) |

---

## 项目结构

```
floatnote/
├── src/                          # 前端源码
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
│   ├── screenshot-main.js        # 截图窗口入口
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
- 导入 / 导出操作增加进度提示
- 云同步失败时增加重试按钮
- 支持拖拽文件（图片 / 文本）到编辑器
- 修复拼音输入法下标题自动生成异常
- 体积优化：exe 从 23MB 降至 17MB

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
