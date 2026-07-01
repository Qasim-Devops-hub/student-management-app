import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('classroom.db');
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
      CREATE TABLE classes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        section TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE students (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        classId INTEGER NOT NULL,
        name TEXT NOT NULL,
        fatherName TEXT NOT NULL,
        rollNo TEXT NOT NULL,
        monthlyFee REAL NOT NULL,
        phone TEXT NOT NULL,
        description TEXT,
        attendance TEXT, -- Stored as JSON string
        feeStatus TEXT -- Stored as JSON string
      )
    ''');
  }

  // --- CLASS METHODS ---

  // Insert Class
  Future<int> insertClass(Map<String, dynamic> classData) async {
    final db = await instance.database;
    return await db.insert('classes', classData);
  }

  // Fetch Classes
  Future<List<Map<String, dynamic>>> getClasses() async {
    final db = await instance.database;
    return await db.query('classes');
  }

  // Update Class
  Future<int> updateClass(Map<String, dynamic> classData) async {
    final db = await instance.database;
    return await db.update(
      'classes',
      classData,
      where: 'id = ?',
      whereArgs: [classData['id']],
    );
  }

  // Delete Class (Including all students in that class)
  Future<int> deleteClass(int id) async {
    final db = await instance.database;

    // Clean up: Delete all students associated with this class first
    await db.delete(
      'students',
      where: 'classId = ?',
      whereArgs: [id],
    );

    // Then delete the class
    return await db.delete(
      'classes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- STUDENT METHODS ---

  // Insert Student
  Future<int> insertStudent(Map<String, dynamic> studentData) async {
    final db = await instance.database;
    return await db.insert('students', studentData);
  }

  // Fetch Students by Class
  Future<List<Map<String, dynamic>>> getStudentsByClass(int classId) async {
    final db = await instance.database;
    return await db.query(
        'students',
        where: 'classId = ?',
        whereArgs: [classId],
        orderBy: 'rollNo ASC'
    );
  }

  // Update Student
  Future<int> updateStudent(Map<String, dynamic> studentData) async {
    final db = await instance.database;
    return await db.update(
        'students',
        studentData,
        where: 'id = ?',
        whereArgs: [studentData['id']]
    );
  }

  // Delete Student
  Future<int> deleteStudent(int id) async {
    final db = await instance.database;
    return await db.delete(
        'students',
        where: 'id = ?',
        whereArgs: [id]
    );
  }
}