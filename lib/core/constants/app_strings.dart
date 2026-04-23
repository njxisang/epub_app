class AppStrings {
  AppStrings._();

  // App
  static const String appName = 'EpubStudio';
  static const String appDescription = '电子书排版应用';

  // Home Page
  static const String homeTitle = '我的书籍';
  static const String emptyStateTitle = '还没有书籍项目';
  static const String emptyStateSubtitle = '点击下方按钮创建您的第一本书籍';
  static const String createProject = '新建项目';
  static const String deleteProject = '删除项目';
  static const String deleteConfirmTitle = '确认删除';
  static const String deleteConfirmMessage = '确定要删除这个项目吗？此操作不可撤销。';
  static const String cancel = '取消';
  static const String delete = '删除';

  // Editor Page
  static const String editorTitle = '编辑器';
  static const String newChapter = '新章节';
  static const String chapterName = '章节名称';
  static const String addChapter = '添加章节';
  static const String deleteChapter = '删除章节';
  static const String renameChapter = '重命名章节';
  static const String insertImage = '插入图片';
  static const String fromGallery = '从相册选择';
  static const String fromCamera = '拍照';
  static const String autoSaved = '已自动保存';

  // Preview Page
  static const String previewTitle = '预览';
  static const String tableOfContents = '目录';
  static const String pageIndicator = '第 %d / %d 页';

  // Export Page
  static const String exportTitle = '导出设置';
  static const String coverImage = '封面图片';
  static const String selectCover = '选择封面';
  static const String useDefaultCover = '使用默认封面';
  static const String metadata = '元数据';
  static const String bookTitle = '书名';
  static const String author = '作者';
  static const String language = '语言';
  static const String publisher = '出版社';
  static const String isbn = 'ISBN';
  static const String description = '简介';
  static const String tags = '标签';
  static const String exportEpub = '导出 EPUB';
  static const String exporting = '正在导出...';
  static const String exportSuccess = '导出成功';
  static const String exportFailed = '导出失败';
  static const String share = '分享';

  // Dialogs
  static const String confirm = '确认';
  static const String save = '保存';
  static const String inputBookTitle = '请输入书名';
  static const String inputAuthor = '请输入作者';

  // Errors
  static const String errorLoadingProjects = '加载项目失败';
  static const String errorSavingProject = '保存项目失败';
  static const String errorExporting = '导出失败';
}
