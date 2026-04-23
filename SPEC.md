# EPUB电子书排版应用 - 需求规格说明书

## 1. 项目概述

**项目名称**: EpubStudio
**项目类型**: Flutter 移动应用 (Android & iOS)
**核心功能**: 用户通过文本输入和图片插入进行电子书排版，最终输出标准EPUB格式电子书
**目标用户**: 自出版作者、内容创作者、个人知识整理者

---

## 2. UI/UX 需求

### 2.1 页面结构

| 页面 | 功能 | 路由 |
|------|------|------|
| 首页/项目列表 | 展示所有电子书项目，支持新建/打开/删除 | `/` |
| 编辑器 | 核心编辑界面，文本+图片混排 | `/editor/:projectId` |
| 书页预览 | 模拟真实书籍翻页效果 | `/preview/:projectId` |
| 导出设置 | 封面、元数据配置、EPUB导出 | `/export/:projectId` |

### 2.2 导航结构

```
首页 (项目列表)
  └── 编辑器
        ├── 图片插入 (底部工具栏)
        ├── 章节管理 (侧边栏/对话框)
        └── 预览模式
              └── 导出设置
```

### 2.3 视觉风格

- **设计语言**: Material Design 3
- **配色方案**:
  - 主色: `#6750A4` (Deep Purple)
  - 次色: `#625B71`
  - 背景: `#FFFBFE` (浅色) / `#1C1B1F` (深色)
  - 强调色: `#7D5260`
- **字体**: 系统默认 + 书中可嵌入字体
- **主题**: 支持浅色/深色模式

### 2.4 组件需求

#### 首页组件
- `ProjectCard`: 项目卡片，展示封面缩略图、标题、作者、最后修改时间
- `EmptyState`: 无项目时的引导页
- `FloatingActionButton`: 新建项目

#### 编辑器组件
- `RichTextEditor`: 基于 flutter_quill，支持加粗/斜体/下划线/标题/列表
- `ImageBlock`: 可插入的图片块，支持点击放大、删除、调整位置
- `ChapterList`: 章节列表侧边栏，支持拖拽排序
- `EditorToolbar`: 底部工具栏（文本格式/插入图片/添加章节）
- `BlockHandle`: 块级别操作手柄（上下移动/删除）

#### 预览组件
- `BookPageView`: 模拟书页翻页效果，支持左右滑动
- `PageIndicator`: 页码指示器
- `TableOfContents`: 目录浮层

#### 导出组件
- `CoverPicker`: 封面选择器（拍照/相册/默认模板）
- `MetadataForm`: 元数据表单（标题/作者/语言/出版社/ISBN/描述）
- `ExportButton`: 导出EPUB按钮 + 进度显示

---

## 3. 功能需求

### 3.1 项目管理 (P0 - 核心)

| 功能 | 描述 | 优先级 |
|------|------|--------|
| 新建项目 | 输入书名、作者，创建空白项目 | P0 |
| 打开项目 | 从项目列表选择并加载 | P0 |
| 删除项目 | 二次确认后删除项目及所有资源 | P0 |
| 项目列表 | 展示所有项目，按最后修改时间排序 | P0 |
| 自动保存 | 编辑内容每30秒自动保存到本地 | P0 |

### 3.2 文本编辑 (P0 - 核心)

| 功能 | 描述 | 优先级 |
|------|------|--------|
| 基础格式 | 加粗、斜体、下划线、删除线 | P0 |
| 标题样式 | 标题1-3级，正文 | P0 |
| 列表 | 有序列表、无序列表 | P0 |
| 段落操作 | 段落拆分、合并、上移、下移 | P1 |
| 撤销/重做 | 支持多步撤销重做 | P1 |
| 查找替换 | 全文查找并高亮 | P2 |

### 3.3 图片管理 (P0 - 核心)

| 功能 | 描述 | 优先级 |
|------|------|--------|
| 从相册选择 | 调用系统相册选取图片 | P0 |
| 拍照插入 | 调用相机拍摄并插入 | P0 |
| 图片预览 | 点击图片全屏预览 | P0 |
| 删除图片 | 移除图片块 | P0 |
| 图片压缩 | 自动压缩超过1MB的图片 | P0 |
| 调整位置 | 图片块在章节内上下移动 | P1 |

### 3.4 章节管理 (P0 - 核心)

| 功能 | 描述 | 优先级 |
|------|------|--------|
| 添加章节 | 在当前位置后插入新章节 | P0 |
| 删除章节 | 删除章节（需确认） | P0 |
| 重命名章节 | 修改章节标题 | P0 |
| 章节排序 | 拖拽调整章节顺序 | P1 |
| 章节预览 | 快速跳转到某章节开头 | P1 |

### 3.5 书页预览 (P1 - 重要)

| 功能 | 描述 | 优先级 |
|------|------|--------|
| 翻页效果 | 左右滑动模拟翻书 | P1 |
| 目录导航 | 点击目录跳转到对应章节 | P1 |
| 页码显示 | 显示当前页/总页数 | P1 |
| 预览设置 | 切换横屏/竖屏预览 | P2 |

### 3.6 EPUB导出 (P0 - 核心)

| 功能 | 描述 | 优先级 |
|------|------|--------|
| 封面设置 | 选择封面图片或使用默认 | P0 |
| 元数据配置 | 书名、作者、语言、出版社等 | P0 |
| 生成EPUB | 生成标准EPUB 3文件 | P0 |
| 保存到本地 | 保存到 Downloads 或指定目录 | P0 |
| 分享EPUB | 通过系统分享功能发送 | P0 |
| 导出预览 | 导出前预览EPUB结构 | P1 |

### 3.7 数据持久化 (P0 - 核心)

| 功能 | 描述 | 优先级 |
|------|------|--------|
| SQLite存储 | 保存项目元数据到SQLite | P0 |
| JSON存储 | 章节内容以JSON格式存储 | P0 |
| 图片存储 | 图片资源存储到应用私有目录 | P0 |
| 项目导入 | 导入已有EPUB文件进行编辑 | P2 |

---

## 4. 技术架构

### 4.1 技术栈

| 层级 | 技术 | 版本/说明 |
|------|------|----------|
| 框架 | Flutter | 3.24.0 (Dart 3.5.0) |
| 状态管理 | flutter_bloc | ^9.0.0 |
| 富文本编辑 | flutter_quill | ^10.0.0 |
| 图片选择 | image_picker | ^1.0.0 |
| 图片处理 | image | ^4.0.0 |
| EPUB生成 | epub | ^3.0.0 |
| 本地存储 | sqflite | ^2.3.0 |
| 路径管理 | path_provider | ^2.1.0 |
| 文件分享 | share_plus | ^7.0.0 |
| 路由管理 | go_router | ^14.0.0 |
| 依赖注入 | get_it | ^8.0.0 |
| 序列化 | json_serializable | ^6.0.0 |

### 4.2 项目结构

```
lib/
├── main.dart
├── app.dart
├── injection_container.dart          # 依赖注入
│
├── core/
│   ├── constants/
│   │   ├── app_colors.dart
│   │   ├── app_strings.dart
│   │   └── app_dimensions.dart
│   ├── theme/
│   │   └── app_theme.dart
│   ├── router/
│   │   └── app_router.dart
│   └── utils/
│       ├── file_utils.dart
│       └── image_utils.dart
│
├── data/
│   ├── models/
│   │   ├── book_project.dart
│   │   ├── chapter.dart
│   │   ├── content_block.dart
│   │   └── epub_metadata.dart
│   ├── repositories/
│   │   └── project_repository.dart
│   └── datasources/
│       ├── local_database.dart
│       └── file_storage.dart
│
├── domain/
│   └── services/
│       ├── epub_builder.dart
│       └── image_service.dart
│
├── presentation/
│   ├── bloc/
│   │   ├── project_list/
│   │   │   ├── project_list_bloc.dart
│   │   │   ├── project_list_event.dart
│   │   │   └── project_list_state.dart
│   │   └── editor/
│   │       ├── editor_bloc.dart
│   │       ├── editor_event.dart
│   │       └── editor_state.dart
│   │
│   ├── pages/
│   │   ├── home_page.dart
│   │   ├── editor_page.dart
│   │   ├── preview_page.dart
│   │   └── export_page.dart
│   │
│   └── widgets/
│       ├── common/
│       │   ├── app_button.dart
│       │   └── app_text_field.dart
│       ├── project_card.dart
│       ├── rich_text_editor.dart
│       ├── image_block_widget.dart
│       ├── chapter_list_tile.dart
│       ├── editor_toolbar.dart
│       ├── book_page_view.dart
│       └── export_form.dart
```

### 4.3 数据模型

```dart
// BookProject - 整个电子书项目
class BookProject {
  String id;              // UUID
  String title;           // 书名
  String author;          // 作者
  String? coverPath;      // 封面图片路径
  List<Chapter> chapters; // 章节列表
  EpubMetadata metadata;  // 扩展元数据
  DateTime createdAt;
  DateTime updatedAt;
}

// Chapter - 章节
class Chapter {
  String id;              // UUID
  String title;           // 章节标题
  List<ContentBlock> blocks; // 内容块列表
}

// ContentBlock - 内容块 (文本或图片)
class ContentBlock {
  String id;              // UUID
  BlockType type;         // text / image
  String? textContent;    // 文本内容 (Delta JSON)
  String? imagePath;      // 图片路径
  int? imageWidth;        // 图片宽度
  int? imageHeight;       // 图片高度
}

// EpubMetadata - EPUB元数据
class EpubMetadata {
  String? language;       // 语言 (默认 zh-CN)
  String? publisher;      // 出版社
  String? description;    // 简介
  String? isbn;           // ISBN
  List<String> tags;      // 标签
}
```

---

## 5. EPUB生成规格

### 5.1 EPUB结构

```
book.epub/
├── mimetype                    # application/epub+zip
├── META-INF/
│   └── container.xml           # 根文件索引
├── EPUB/
│   ├── content.opf             # 包文档 (元数据+资源清单)
│   ├── toc.ncx                 # NCX导航 (EPUB2兼容)
│   ├── nav.xhtml               # 导航文档 (EPUB3)
│   ├── styles/
│   │   └── styles.css          # 样式表
│   ├── images/
│   │   ├── cover.jpg           # 封面
│   │   └── *.jpg/png           # 正文图片
│   └── chapters/
│       ├── chapter_1.xhtml     # 章节内容
│       ├── chapter_2.xhtml
│       └── ...
```

### 5.2 图片规格

| 类型 | 最大尺寸 | 格式 | 压缩率 |
|------|---------|------|--------|
| 封面 | 1600x2560 | JPG/PNG | 85% |
| 正文图片 | 1200x1600 | JPG | 80% |

---

## 6. 验收标准

### 6.1 功能验收

- [ ] 可创建新的电子书项目
- [ ] 可编辑书名、作者
- [ ] 可添加/删除/重命名章节
- [ ] 可在章节中输入富文本（加粗/斜体/标题/列表）
- [ ] 可从相册或相机插入图片
- [ ] 可预览电子书翻页效果
- [ ] 可配置封面和元数据
- [ ] 可成功导出标准EPUB文件
- [ ] 可通过系统分享发送EPUB文件

### 6.2 性能要求

- 应用冷启动时间 < 3秒
- 100页文本编辑流畅不卡顿
- 图片插入到显示 < 1秒
- EPUB导出 < 10秒（无图片的情况下）

### 6.3 兼容性

- Android 6.0+ (API 23)
- iOS 12.0+

---

## 7. 开发计划

### Phase 1: 项目基础 (预计 3-5 天)
- [ ] 项目初始化，依赖配置
- [ ] 路由和主题配置
- [ ] 数据模型定义
- [ ] SQLite本地存储实现
- [ ] 项目列表页面 (Bloc)

### Phase 2: 核心编辑功能 (预计 5-7 天)
- [ ] flutter_quill 集成
- [ ] 文本编辑_bloc
- [ ] 章节管理功能
- [ ] 图片插入功能
- [ ] 自动保存机制

### Phase 3: 预览与导出 (预计 3-5 天)
- [ ] 书页预览组件
- [ ] 目录生成与导航
- [ ] EPUB生成服务
- [ ] 导出页面和分享功能

### Phase 4: 优化与完善 (预计 2-3 天)
- [ ] 错误处理和边界情况
- [ ] 性能优化
- [ ] UI细节打磨
- [ ] 深色模式支持
