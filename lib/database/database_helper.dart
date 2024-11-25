import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:async';

class DatabaseHelper {
  static final _databaseName = "EmployeeDatabase.db";
  static final _databaseVersion = 1;

  static final table = 'employees';

  static final columnId = 'id';
  static final columnName = 'name';
  static final columnLastName = 'lastName';
  static final columnCedula = 'cedula';
  static final columnPosition = 'position';
  static final columnArea = 'area';
  static final columnSignature = 'signature';

  // Hacer esto una clase singleton
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  // Solo permitir una única referencia a la base de datos
  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Abrir la base de datos y crearla si no existe
  _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);
    return await openDatabase(path,
        version: _databaseVersion,
        onCreate: _onCreate);
  }

  // Código SQL para crear la base de datos y la tabla
  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $table (
        $columnId INTEGER PRIMARY KEY,
        $columnName TEXT NOT NULL,
        $columnLastName TEXT NOT NULL,
        $columnCedula TEXT NOT NULL,
        $columnPosition TEXT NOT NULL,
        $columnArea TEXT NOT NULL,
        $columnSignature TEXT NOT NULL
      )
      ''');
  }

  // Métodos Helper
  // Insertar un empleado
  Future<int> insert(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert(table, row);
  }

  // Todos los empleados
  Future<List<Map<String, dynamic>>> queryAllRows() async {
    Database db = await instance.database;
    return await db.query(table);
  }

  // Número de empleados
  Future<int> queryRowCount() async {
    Database db = await instance.database;
    return Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM $table')) ?? 0;
  }

  // Actualizar un empleado
  Future<int> update(Map<String, dynamic> row) async {
    Database db = await instance.database;
    int id = row[columnId];
    return await db.update(table, row, where: '$columnId = ?', whereArgs: [id]);
  }

  // Eliminar un empleado
  Future<int> delete(int id) async {
    Database db = await instance.database;
    return await db.delete(table, where: '$columnId = ?', whereArgs: [id]);
  }
}

