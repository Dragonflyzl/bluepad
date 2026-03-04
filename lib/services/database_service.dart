/// 数据库服务
/// 对应 Android: AppDatabase + ClipboardDao
/// 使用 sqflite 替代 Room 数据库
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/clipboard_item.dart';

/// 数据库服务类
/// 单例模式，对应 Kotlin: companion object
class DatabaseService {
  static Database? _database;
  static final DatabaseService _instance = DatabaseService._internal();

  factory DatabaseService() => _instance;

  DatabaseService._internal();

  /// 获取数据库实例
  /// 对应 Kotlin: getDatabase(context)
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  /// 初始化数据库
  Future<Database> _initDatabase() async {
    // 获取数据库路径
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'bluepad_database.db');

    // 打开数据库，如果不存在则创建
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  /// 创建表
  /// 对应 Kotlin: @Database 注解
  Future<void> _onCreate(Database db, int version) async {
    await db.execute(ClipboardItem.createTableSql);
  }

  /// 关闭数据库
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }

  // ==================== 剪贴板历史记录操作 ====================

  /// 插入剪贴板记录
  /// 对应 Kotlin: @Insert
  Future<int> insertClipboardItem(ClipboardItem item) async {
    final db = await database;
    return await db.insert(
      ClipboardItem.tableName,
      item.toMap()..remove('id'), // 移除 id 让数据库自增
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 获取所有剪贴板记录
  /// 对应 Kotlin: @Query("SELECT * FROM clipboard_history ORDER BY timestamp DESC")
  Future<List<ClipboardItem>> getAllClipboardItems() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      ClipboardItem.tableName,
      orderBy: 'timestamp DESC',
    );
    return List.generate(maps.length, (i) => ClipboardItem.fromMap(maps[i]));
  }

  /// 获取收藏的剪贴板记录
  Future<List<ClipboardItem>> getFavoriteClipboardItems() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      ClipboardItem.tableName,
      where: 'isFavorite = ?',
      whereArgs: [1],
      orderBy: 'timestamp DESC',
    );
    return List.generate(maps.length, (i) => ClipboardItem.fromMap(maps[i]));
  }

  /// 更新剪贴板记录
  /// 对应 Kotlin: @Update
  Future<int> updateClipboardItem(ClipboardItem item) async {
    final db = await database;
    return await db.update(
      ClipboardItem.tableName,
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  /// 删除剪贴板记录
  /// 对应 Kotlin: @Delete
  Future<int> deleteClipboardItem(int id) async {
    final db = await database;
    return await db.delete(
      ClipboardItem.tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 清空所有历史记录（保留收藏的）
  Future<int> clearClipboardHistory() async {
    final db = await database;
    return await db.delete(
      ClipboardItem.tableName,
      where: 'isFavorite = ?',
      whereArgs: [0],
    );
  }

  /// 清空所有记录（包括收藏的）
  Future<int> deleteAllClipboardItems() async {
    final db = await database;
    return await db.delete(ClipboardItem.tableName);
  }

  /// 搜索剪贴板内容
  Future<List<ClipboardItem>> searchClipboardItems(String query) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      ClipboardItem.tableName,
      where: 'content LIKE ? OR preview LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'timestamp DESC',
    );
    return List.generate(maps.length, (i) => ClipboardItem.fromMap(maps[i]));
  }

  /// 获取记录总数
  Future<int> getClipboardItemCount() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ${ClipboardItem.tableName}',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
