# EpubStudio - EPUB电子书排版应用

一款基于 Flutter 的 EPUB 电子书排版工具，支持富文本编辑、章节管理、图片插入和 EPUB 格式导出。

## 功能特性

### 📖 项目管理
- 创建、编辑、删除电子书项目
- 自定义书籍元数据（书名、作者、出版社、语言、ISBN、描述）
- 项目列表展示，创建/更新时间排序

### ✏️ 富文本编辑
- 基于 flutter_quill 的专业富文本编辑器
- 支持**标题**、**加粗**、*斜体*、下划线、删除线
- 有序列表、无序列表、引用块
- 文本颜色高亮

### 🖼️ 章节与图片管理
- 多章节支持，动态添加/删除/重命名章节
- 插入图片，自动复制到项目目录
- 封面图片设置

### 📱 预览与导出
- 书页预览组件，真实书籍翻页效果
- 目录导航，快速跳转到任意章节
- 一键生成标准 EPUB 格式文件（EPUB 2/3 双导航）
- 分享导出，通过系统分享功能发送 EPUB 文件

## 技术架构

```
lib/
├── core/                      # 核心配置
│   ├── constants/             # 常量（颜色、尺寸、字符串）
│   ├── router/                # 路由配置（go_router）
│   ├── theme/                 # 主题配置
│   └── utils/                 # 工具函数
├── data/                      # 数据层
│   ├── datasources/           # 数据源（SQLite、文件存储）
│   ├── models/                # 数据模型
│   └── repositories/         # 仓储实现
├── domain/                    # 业务逻辑层
│   └── services/             # 服务（EPUB生成、图片处理）
├── presentation/             # 展示层
│   ├── bloc/                 # 状态管理（flutter_bloc）
│   ├── pages/                # 页面
│   └── widgets/             # 通用组件
├── app.dart                  # 应用入口
├── injection_container.dart  # 依赖注入（GetIt）
└── main.dart                 # main函数
```

### 状态管理
- **flutter_bloc** — BLoC 模式管理编辑器状态和项目列表
- `EditorBloc` — 管理当前章节内容、QuillDelta 文档、脏标记
- `ProjectListBloc` — 管理项目列表的加载、创建、删除

### 数据持久化
- **SQLite（sqflite）** — 存储项目元数据
- **JSON文件** — 存储每个项目的完整内容（BookProject JSON）
- **文件复制** — 图片资源存储在应用文档目录下

### EPUB 生成
- 使用 `archive` 包构建标准 ZIP 格式 EPUB
- 支持 EPUB 2（NCX目录）和 EPUB 3（Nav文档）双目录格式
- mimetype 文件无压缩，符合 EPUB 规范

## 依赖

| 包 | 版本 | 用途 |
|---|---|---|
| flutter_bloc | ^9.1.1 | 状态管理 |
| flutter_quill | ^11.5.0 | 富文本编辑 |
| archive | ^4.0.9 | EPUB ZIP打包 |
| sqflite | ^2.4.2 | SQLite数据库 |
| path_provider | ^2.1.5 | 文件路径 |
| share_plus | ^12.0.2 | 系统分享 |
| go_router | ^17.2.2 | 路由导航 |
| get_it | ^9.2.1 | 依赖注入 |
| image_picker | ^1.2.1 | 图片选择 |
| uuid | ^4.5.3 | ID生成 |

## 构建

### Android
```bash
# 需要 JDK 17 和 Android SDK
export JAVA_HOME=/path/to/jdk17
export ANDROID_HOME=/path/to/android-sdk
export PATH=$JAVA_HOME/bin:$PATH
flutter pub get
flutter build apk --debug
# 输出: build/app/outputs/flutter-apk/app-debug.apk
```

### Web
```bash
flutter pub get
flutter build web
# 输出: build/web/
```

### iOS（仅 macOS）
```bash
flutter pub get
flutter build ios --simulator --no-codesign
```

## 项目结构详情

### 数据模型
- `BookProject` — 书籍项目（书名、作者、章节、封面、元数据、创建/更新时间）
- `Chapter` — 章节（ID、标题、内容块列表）
- `ContentBlock` — 内容块（文本或图片，支持富文本 Delta）
- `EpubMetadata` — EPUB元数据（ISBN、出版社、语言、描述）

### 路由
- `/` — 首页，项目列表
- `/editor/:projectId` — 编辑器页面
- `/editor/:projectId/preview` — 预览页面
- `/editor/:projectId/export` — 导出页面

### BLoC 事件
**EditorBloc**
- `LoadChapter` — 加载章节内容
- `UpdateContent` — 更新富文本内容（Delta）
- `AddBlock` — 添加内容块
- `UpdateBlock` — 更新内容块
- `DeleteBlock` — 删除内容块
- `InsertImage` — 插入图片
- `SaveProject` — 保存项目
- `ReorderChapters` — 重排章节顺序

**ProjectListBloc**
- `LoadProjects` — 加载项目列表
- `CreateProject` — 创建新项目
- `DeleteProject` — 删除项目

## License

MIT
