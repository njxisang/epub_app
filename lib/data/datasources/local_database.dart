import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../models/book_project.dart';
import '../models/chapter.dart';
import '../models/content_block.dart';
import '../models/epub_metadata.dart';

class LocalDatabase {
  static Database? _database;
  static const String _dbName = 'epub_studio.db';
  static const int _dbVersion = 1;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, _dbName);

    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE projects (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        author TEXT NOT NULL,
        cover_path TEXT,
        chapters_json TEXT NOT NULL,
        metadata_json TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle future schema migrations
  }

  List<Chapter> _parseChapters(String json) {
    final list = jsonDecode(json) as List<dynamic>;
    return list.map((c) {
      final map = c as Map<String, dynamic>;
      return Chapter(
        id: map['id'] as String,
        title: map['title'] as String,
        blocks: (map['blocks'] as List<dynamic>).map((b) {
          final bmap = b as Map<String, dynamic>;
          return ContentBlock(
            id: bmap['id'] as String,
            type: BlockType.values.firstWhere((e) => e.name == bmap['type']),
            textContent: bmap['textContent'] as String?,
            imagePath: bmap['imagePath'] as String?,
            imageWidth: bmap['imageWidth'] as int?,
            imageHeight: bmap['imageHeight'] as int?,
          );
        }).toList(),
      );
    }).toList();
  }

  Future<List<BookProject>> getAllProjects() async {
    final db = await database;
    final results = await db.query(
      'projects',
      orderBy: 'updated_at DESC',
    );

    return results.map((row) {
      return BookProject(
        id: row['id'] as String,
        title: row['title'] as String,
        author: row['author'] as String,
        coverPath: row['cover_path'] as String?,
        chapters: _parseChapters(row['chapters_json'] as String),
        metadata: EpubMetadata.fromJson(
            jsonDecode(row['metadata_json'] as String) as Map<String, dynamic>),
        createdAt: DateTime.parse(row['created_at'] as String),
        updatedAt: DateTime.parse(row['updated_at'] as String),
      );
    }).toList();
  }

  Future<void> insertProject(BookProject project) async {
    final db = await database;
    await db.insert(
      'projects',
      {
        'id': project.id,
        'title': project.title,
        'author': project.author,
        'cover_path': project.coverPath,
        'chapters_json': jsonEncode(project.chapters.map((c) => c.toJson()).toList()),
        'metadata_json': jsonEncode(project.metadata.toJson()),
        'created_at': project.createdAt.toIso8601String(),
        'updated_at': project.updatedAt.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateProject(BookProject project) async {
    final db = await database;
    await db.update(
      'projects',
      {
        'title': project.title,
        'author': project.author,
        'cover_path': project.coverPath,
        'chapters_json': jsonEncode(project.chapters.map((c) => c.toJson()).toList()),
        'metadata_json': jsonEncode(project.metadata.toJson()),
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [project.id],
    );
  }

  Future<void> deleteProject(String id) async {
    final db = await database;
    await db.delete(
      'projects',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<BookProject?> getProjectById(String id) async {
    final db = await database;
    final results = await db.query(
      'projects',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (results.isEmpty) return null;

    final row = results.first;
    return BookProject(
      id: row['id'] as String,
      title: row['title'] as String,
      author: row['author'] as String,
      coverPath: row['cover_path'] as String?,
      chapters: _parseChapters(row['chapters_json'] as String),
      metadata: EpubMetadata.fromJson(
          jsonDecode(row['metadata_json'] as String) as Map<String, dynamic>),
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }
}
