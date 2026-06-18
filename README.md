# 灵签 FloatNote

> 轻盈桌面便签 — 记事本 & 待办事项，随手记录，随时可达

灵签是一款基于 Tauri 2 + Vue 3 构建的桌面笔记应用，体积小巧、启动迅速，支持富文本与 Markdown 双模式编辑，多主题切换，窗口置顶与透明度调节，让笔记像便签一样随手可用。

---

## ✨ 功能特性

### 记事本
- **多记事本管理** — 创建多个记事本，子标签切换，支持重命名、颜色标记、锁定
- **富文本编辑** — 加粗、斜体、下划线、字号选择（7 档）、清除格式
- **Markdown 模式** — 实时渲染，支持 GFM、图片、表格、代码块
- **笔记置顶** — 重要笔记固定在顶部，新建笔记不会挤掉置顶
- **笔记标签颜色** — 为每条笔记设置颜色标识
- **多格式导入** — 支持 Markdown / TXT / HTML / DOCX（Word）
- **多格式导出** — 支持 Markdown / TXT / HTML / DOCX / PDF

### 待办事项
- **多列表管理** — 创建多个待办列表，分类管理
- **待办计数** — 标题栏实时显示未完成数量
- **列表锁定/颜色** — 与记事本一致的标签管理体验

### 界面与交互
- **8 种主题** — 明亮、暗黑、暖纸、薄荷、樱花、雾蓝、奶咖、暖咖
- **窗口透明度** — 20%~100% 自由调节，融入桌面背景
- **窗口置顶** — 一键置顶，随时参考
- **极简模式** — 隐藏标签栏，只保留核心编辑区
- **自定义标题栏** — 无边框窗口，双击标题栏切换紧凑模式
- **系统托盘** — 关闭按钮收纳到托盘，不占用任务栏
- **标签栏空位右键** — 快速新建记事本/待办页

### 数据安全
- **回收站** — 删除的记事本/待办页/笔记保留 30 天，可随时恢复
- **本地存储** — 所有数据保存在本地，隐私安全
- **云同步** — 支持配置远程同步，跨设备使用

---

## 📸 预览

支持 8 种精心设计的主题配色，搭配透明度调节，让桌面笔记既美观又实用。

| 明亮 | 暗黑 | 暖纸 |
|:---:|:---:|:---:|
| 干净白纸 | 深夜模式 | 米黄纸张 |

| 薄荷 | 樱花 | 雾蓝 |
|:---:|:---:|:---:|
| 清爽护眼 | 温柔不刺眼 | 晨雾轻柔 |

---

## 📥 安装

### 方式一：下载安装包（推荐）

前往 [Releases](../../releases) 页面下载最新版本的安装包：

- **Windows 安装包**：`灵签_x.x.x_x64-setup.exe`（NSIS 安装程序）
- **Windows 便携版**：`floatnote.exe`（免安装，直接运行）

### 方式二：源码构建

需要以下环境：
- [Node.js](https://nodejs.org/) 18+
- [Rust](https://www.rust-lang.org/tools/install) 1.70+
- [WebView2](https://developer.microsoft.com/en-us/microsoft-edge/webview2/)（Windows 10/11 已内置）

```bash
# 克隆仓库
git clone https://github.com/YOUR_USERNAME/floatnote.git
cd floatnote

# 安装依赖
npm install

# 开发模式
npm run tauri dev

# 构建发布版
npm run tauri build
```

构建产物位于 `src-tauri/target/release/`：
- `floatnote.exe` — 可执行文件
- `bundle/nsis/灵签_x.x.x_x64-setup.exe` — NSIS 安装包

---

## 🛠 技术栈

| 层级 | 技术 |
|---|---|
| 桌面框架 | [Tauri 2.x](https://tauri.app/) |
| 前端框架 | [Vue 3](https://vuejs.org/) (Composition API) |
| 构建工具 | [Vite 5](https://vite.dev/) |
| 后端语言 | [Rust](https://www.rust-lang.org/) |
| Markdown 渲染 | [marked](https://marked.js.org/) |
| Word 导出 | [docx](https://www.npmjs.com/package/docx) |
| Word 导入 | [mammoth](https://www.npmjs.com/package/mammoth) |

---

## 📁 项目结构

```
floatnote/
├── src/                    # 前端源码
│   ├── components/         # Vue 组件
│   │   ├── NotePanel.vue   # 记事本面板
│   │   ├── TodoPanel.vue   # 待办事项面板
│   │   ├── SyncPanel.vue   # 云同步面板
│   │   └── ScreenshotOverlay.vue
│   ├── composables/        # 组合式函数
│   ├── services/           # 服务层（同步状态）
│   ├── utils/              # 工具函数
│   ├── App.vue             # 应用壳（标题栏、主题、面板切换）
│   ├── main.js             # 入口
│   └── style.css           # 全局样式 + 主题变量
├── src-tauri/              # Rust 后端
│   ├── src/main.rs         # Tauri 命令（文件保存等）
│   ├── Cargo.toml          # Rust 依赖
│   └── tauri.conf.json     # Tauri 配置
├── package.json            # 前端依赖
└── vite.config.js          # Vite 配置
```

---

## 📝 开发

```bash
# 启动开发服务器（前端热更新 + Tauri 窗口）
npm run tauri dev

# 仅构建前端
npm run build
```

---

## 📄 许可证

[MIT License](LICENSE)

---

## 🙏 致谢

- [Tauri](https://tauri.app/) — 轻量级桌面应用框架
- [Vue.js](https://vuejs.org/) — 渐进式 JavaScript 框架
- [Vite](https://vite.dev/) — 下一代前端构建工具
