import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('usuarios.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE usuarios (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        correo TEXT NOT NULL UNIQUE,
        contraseña TEXT NOT NULL
      )
    ''');
  }

  Future<int> insertUser(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('usuarios', row);
  }

  Future<List<Map<String, dynamic>>> queryAllUsers() async {
    final db = await instance.database;
    return await db.query('usuarios');
  }

  Future<List<Map<String, dynamic>>> queryUserByEmail(String correo) async {
    final db = await instance.database;
    return await db.query(
      'usuarios',
      where: 'correo = ?',
      whereArgs: [correo],
    );
  }

  Future close() async {
    final db = await instance.database;
    await db.close();
  }
}
