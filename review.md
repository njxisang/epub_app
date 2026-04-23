# EpubStudio 代码审查报告

**项目路径**: `/home/xisang/epub_app`
**审查时间**: 2026-04-23
**Flutter版本**: 3.24.0 / Dart 3.5.0

---

## 一、严重问题 (Critical)

### 1.1 Quill编辑器内容未加载 [editor_page.dart:188-192]

```dart
void _initializeQuillController(List blocks) {
  _quillController?.dispose();
  _quillController = QuillController.basic();
  // TODO: Parse blocks and populate editor
}
```

**问题**: `TODO`注释说明内容从未真正加载到Quill编辑器中。用户编辑的内容不会保存回ContentBlock。

**影响**: 核心编辑功能完全不可用。

**建议修复**:
1. 定义ContentBlock到Quill Delta的转换逻辑
2. 实现Delta到ContentBlock的序列化/反序列化
3. 在切换章节时正确加载/保存内容

---

### 1.2 图片路径加载错误 [book_page_view.dart:178]

```dart
child: Image.asset(
  block.imagePath!,
  fit: BoxFit.contain,
```

**问题**: `block.imagePath`是绝对文件路径(如`/data/user/0/.../images/xxx.jpg`)，但使用了`Image.asset()`加载。`asset`用于加载bundle资源，文件路径应该用`Image.file()`。

**影响**: 预览页面的图片全部无法显示。

**同样问题存在于**: [export_page.dart:143]

---

### 1.3 EpubBuilder未通过依赖注入 [export_page.dart:293]

```dart
final epubBuilder = EpubBuilder(); // 手动new
```

**问题**: `EpubBuilder`已在`injection_container.dart`中注册为懒单例，但`ExportPage`手动`new`了一个新实例。

**影响**: 违背依赖注入原则，可能导致状态管理问题。

---

### 1.4 导出时元数据更新为异步未等待 [export_page.dart:285-288]

```dart
context.read<EditorBloc>().add(UpdateMetadata(
  title: _titleController.text,
  author: _authorController.text,
));

final outputFile = await epubBuilder.buildEpub(project); // 使用的是旧state
```

**问题**: `add(UpdateMetadata)`是fire-and-forget，BLoC处理是异步的。紧接着构建EPUB时使用的仍是旧state中的metadata。

**影响**: 导出时用户修改的元数据(书名、作者)不会被反映到EPUB中。

---

## 二、主要问题 (Major)

### 2.1 数据模型与Quill Delta格式不匹配

**问题**: `ContentBlock.textContent`存储纯字符串，但`flutter_quill`使用Delta JSON格式(包含加粗、斜体、标题等信息)。

```dart
// ContentBlock存储
textContent: "这是纯文本"

// Quill Delta格式
"[{\"insert\":\"这是纯文本\\n\"}]"
```

**影响**: 无法保存富文本格式(加粗、斜体、标题等)。

**建议**: 重构`ContentBlock`直接存储Quill Delta JSON，移除中间转换层。

---

### 2.2 BookProject.empty章节ID与项目ID相同 [book_project.dart:87]

```dart
chapters: [
  Chapter(id: id, title: '第一章', blocks: []), // id = 项目ID
],
```

**问题**: 章节ID应该独立生成UUID，不能与项目ID相同。

---

### 2.3 PreviewPage/ExportPage无法获取EditorBloc [preview_page.dart:16]

```dart
return BlocBuilder<EditorBloc, EditorState>(
  builder: (context, state) {
```

**问题**: `EditorPage`使用`BlocProvider`创建`EditorBloc`，但`PreviewPage`和`ExportPage`在导航栈中无法访问同一个bloc实例(除非父级提供了RepositoryProvider)。

实际上`app.dart`提供了`RepositoryProvider<ProjectRepository>`，但`EditorBloc`由`EditorPage`自己创建，不是全局的。

**影响**: 预览和导出页面的状态来源不正确，可能导致数据不一致。

**建议**: 通过路由参数传递projectId，在PreviewPage/ExportPage重新加载数据，或使用全局Bloc。

---

### 2.4 数据存储冗余且不一致

**问题**:
1. `ProjectRepository`同时向FileStorage和LocalDatabase写入
2. `LocalDatabase.insertProject`使用`ConflictAlgorithm.replace`模拟更新
3. `LocalDatabase.updateProject()`方法已定义但从未被调用
4. `getProjectById()`先查FileStorage再查Database，但FileStorage是主数据源

**建议**: 统一数据源，只保留FileStorage(JSON)或LocalDatabase(SQLite)之一。

---

### 2.5 目录导航跳转未实现 [preview_page.dart:88]

```dart
onTap: () {
  Navigator.pop(context);
  // TODO: Navigate to chapter  ← 未实现
},
```

---

## 三、次要问题 (Minor)

### 3.1 硬编码magic string

- 封面后缀`cover${p.extension(coverFile.path)}`依赖文件扩展名 [file_storage.dart:45]
- `mimetype`未压缩要求未在archive层面强制 [epub_builder.dart:15]

---

### 3.2 重复实例化ImageService

- `export_page.dart`通过`context.read<ImageService>()`获取 (正确)
- `ImageService`本身无状态，可以是静态工具类

---

### 3.3 错误处理不完善

多处`try-catch`只有`catch (e)`，没有针对性异常处理。

---

### 3.4 异步函数无await

`EditorBloc`中多个`Future<void>`函数内部没有`await`，如`_onSelectChapter`实际上是同步的却声明为async。

---

## 四、架构优化建议

### 4.1 状态管理

当前使用`flutter_bloc`，结构清晰。建议:

```
EditorBloc (编辑状态)
  └── 考虑拆分: EditorBloc(内容) + ExportBloc(导出状态)
```

### 4.2 目录结构

当前结构符合Clean Architecture:
```
lib/
├── core/          ✓
├── data/          ✓ 分层正确
├── domain/        ✓ services放置合理
└── presentation/  ✓ bloc/pages/widgets分离
```

### 4.3 建议增加

- **Error models**: 定义明确的异常类型
- **Result type**: 使用`Either<Failure, Success>`替代try-catch
- **Dartz/fp**: 考虑引入函数式编程库处理异步状态

---

## 五、安全与性能

### 5.1 安全性

- 图片路径未校验，可能存在路径遍历风险
- 用户输入未做XSS防护(EPUB内容直接拼接XML)

### 5.2 性能

- `getProjectById()`双重查找(FileStorage + Database)低效
- 图片压缩在主线程执行 [image_service.dart:29] 应使用`compute()`
- `_generatePages()`每次build都重新生成 [book_page_view.dart:33] 应缓存

---

## 六、总结

| 类别 | 数量 |
|------|------|
| 严重问题 | 4 |
| 主要问题 | 5 |
| 次要问题 | 4 |

**核心功能状态**: ⚠️ 编辑器富文本功能未完成，图片预览失效。

**建议优先级**:
1. 修复Quill编辑器集成 (编辑功能)
2. 修复图片加载 (预览功能)
3. 修复EPUB导出元数据 (导出功能)
4. 统一数据存储方案
