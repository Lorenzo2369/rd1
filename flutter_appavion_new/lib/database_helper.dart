import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sqflite/sqflite.dart' as sql;
import 'package:path/path.dart';
import 'usuario.dart';

class DatabaseHelper {
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  sql.Database? _db;

  Future<void> init() async {
    if (kIsWeb) {
      await Hive.initFlutter();
      Hive.registerAdapter(UsuarioAdapter());
      await Hive.openBox<Usuario>('usersBox');
      await Hive.openBox('sessionBox');
    } else {
      _db = await _initSqflite();
    }
  }

  Future<sql.Database> _initSqflite() async {
    final path = join(await sql.getDatabasesPath(), 'app.db');
    return await sql.openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE usuarios (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nombre TEXT,
            correo TEXT UNIQUE,
            contrasena TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE session (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            correo TEXT
          )
        ''');
      },
    );
  }

  Future<void> insertUser(Usuario user) async {
    if (kIsWeb) {
      final usersBox = Hive.box<Usuario>('usersBox');
      await usersBox.put(user.correo, user);
    } else {
      final db = _db ?? await _initSqflite();
      await db.insert('usuarios', user.toMap());
    }
  }

  Future<Usuario?> getUserByEmail(String correo) async {
    if (kIsWeb) {
      final usersBox = Hive.box<Usuario>('usersBox');
      return usersBox.get(correo);
    } else {
      final db = _db ?? await _initSqflite();
      final result =
          await db.query('usuarios', where: 'correo = ?', whereArgs: [correo]);
      if (result.isNotEmpty) {
        return Usuario.fromMap(result.first);
      }
      return null;
    }
  }

  Future<void> saveSession(String correo) async {
    if (kIsWeb) {
      final sessionBox = Hive.box('sessionBox');
      await sessionBox.put('loggedInUserEmail', correo);
    } else {
      final db = _db ?? await _initSqflite();
      await db.delete('session');
      await db.insert('session', {'correo': correo});
    }
  }

  Future<String?> getSession() async {
    if (kIsWeb) {
      final sessionBox = Hive.box('sessionBox');
      return sessionBox.get('loggedInUserEmail');
    } else {
      final db = _db ?? await _initSqflite();
      final result = await db.query('session');
      return result.isNotEmpty ? result.first['correo'] as String : null;
    }
  }

  Future<void> logout() async {
    if (kIsWeb) {
      final sessionBox = Hive.box('sessionBox');
      await sessionBox.delete('loggedInUserEmail');
    } else {
      final db = _db ?? await _initSqflite();
      await db.delete('session');
    }
  }
}
