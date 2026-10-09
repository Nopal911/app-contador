import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('seguridad.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 7,
      onConfigure: _onConfigure,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future _createDB(Database db, int version) async {
    await db.execute("""
      CREATE TABLE rol_permiso (
        id INTEGER PRIMARY KEY,
        rol TEXT NOT NULL
      )
    """);

    await db.execute("""
      CREATE TABLE user_app(
        id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        nombre TEXT NOT NULL,
        apellido_paterno TEXT NOT NULL DEFAULT '',
        apellido_materno TEXT,
        latitud REAL,
        longitud REAL,
        direccion TEXT,
        ubicacion_fecha TEXT,
        desc TEXT,
        pass TEXT NOT NULL,
        correo TEXT NOT NULL UNIQUE,
        role_id INTEGER NOT NULL,
        token_recuperacion TEXT,
        token_expiracion TIMESTAMP,             
        codigo_verificacion TEXT,
        codigo_expiracion TIMESTAMP,
        createdAT TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (role_id) REFERENCES rol_permiso (id)
      )
    """);

    await db.execute("""  
      CREATE TABLE product(
        id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        nombre_product TEXT NOT NULL,
        precio REAL NOT NULL,
        cantidad INTEGER NOT NULL,
        imagen TEXT
      )
    """);

    await db.insert('rol_permiso', {'id': 1, 'rol': 'Administrador'});
    await db.insert('rol_permiso', {'id': 2, 'rol': 'Usuario'});
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    // Esquemas muy antiguos (< v5): se recrean, como funcionaba antes.
    if (oldVersion < 5) {
      await db.execute('DROP TABLE IF EXISTS user_app');
      await db.execute('DROP TABLE IF EXISTS rol_permiso');
      await db.execute('DROP TABLE IF EXISTS product');
      await _createDB(db, newVersion);
      return;
    }

    // v5 -> v6: apellidos. NO se borra nada: los usuarios y productos
    // existentes se conservan (su apellido paterno queda vacío).
    if (oldVersion < 6) {
      await db.execute(
          "ALTER TABLE user_app ADD COLUMN apellido_paterno TEXT NOT NULL DEFAULT ''");
      await db.execute(
          'ALTER TABLE user_app ADD COLUMN apellido_materno TEXT');
    }

    // v6 -> v7: ubicación del usuario (latitud, longitud, dirección, fecha).
    if (oldVersion < 7) {
      await db.execute('ALTER TABLE user_app ADD COLUMN latitud REAL');
      await db.execute('ALTER TABLE user_app ADD COLUMN longitud REAL');
      await db.execute('ALTER TABLE user_app ADD COLUMN direccion TEXT');
      await db.execute('ALTER TABLE user_app ADD COLUMN ubicacion_fecha TEXT');
    }
  }

  // ══════════════════════════════════════════════════════════════
  // MÉTODOS DE PRODUCTOS
  // ══════════════════════════════════════════════════════════════

  Future<int> insertProduct(Map<String, dynamic> producto) async {
    final db = await instance.database;
    return await db.insert(
      'product',
      producto,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> syncProductsWithDatabase(
      List<Map<String, dynamic>> products) async {
    for (var product in products) {
      await insertProduct(product);
    }
  }

  Future<List<Map<String, dynamic>>> getProducts() async {
    final db = await instance.database;
    return await db.query('product', orderBy: 'id DESC');
  }

  // Actualizar la cantidad de un producto
  Future<void> updateProductoCantidad(int productoId, int nuevaCantidad) async {
    final db = await instance.database;
    await db.update(
      'product',
      {'cantidad': nuevaCantidad},
      where: 'id = ?',
      whereArgs: [productoId],
    );
  }

  // Eliminar un producto
  Future<void> deleteProducto(int productoId) async {
    final db = await instance.database;
    await db.delete(
      'product',
      where: 'id = ?',
      whereArgs: [productoId],
    );
  }

  // Obtener un producto por ID
  Future<Map<String, dynamic>?> getProductoById(int productoId) async {
    final db = await instance.database;
    final resultado = await db.query(
      'product',
      where: 'id = ?',
      whereArgs: [productoId],
    );
    return resultado.isNotEmpty ? resultado.first : null;
  }

  // ══════════════════════════════════════════════════════════════
  // MÉTODOS DE USUARIOS Y ROLES
  // ══════════════════════════════════════════════════════════════

  Future<int> insertUsuario(Map<String, dynamic> usuario) async {
    final db = await instance.database;
    return await db.insert('user_app', usuario);
  }

  Future<List<Map<String, dynamic>>> getUsuarios() async {
    final db = await instance.database;
    return await db.rawQuery('''
      SELECT user_app.*, rol_permiso.rol as rol_nombre
      FROM user_app
      INNER JOIN rol_permiso ON user_app.role_id = rol_permiso.id
      ORDER BY user_app.id DESC
    ''');
  }

  Future<List<Map<String, dynamic>>> getRoles() async {
    final db = await instance.database;
    return await db.query('rol_permiso', orderBy: 'id');
  }

  Future<bool> existeCorreo(String correo) async {
    final db = await instance.database;
    final resultado = await db.query(
      'user_app',
      where: 'correo = ?',
      whereArgs: [correo],
    );
    return resultado.isNotEmpty;
  }

  /// Guarda la última ubicación compartida por el usuario.
  Future<int> actualizarUbicacion({
    required String correo,
    required double latitud,
    required double longitud,
    String? direccion,
  }) async {
    final db = await instance.database;
    return await db.update(
      'user_app',
      {
        'latitud': latitud,
        'longitud': longitud,
        'direccion': direccion,
        'ubicacion_fecha': DateTime.now().toIso8601String(),
      },
      where: 'correo = ?',
      whereArgs: [correo],
    );
  }

  /// Busca un usuario (con el nombre de su rol) por correo, sin distinguir
  /// mayúsculas. Devuelve null si no existe.
  Future<Map<String, dynamic>?> getUsuarioPorCorreo(String correo) async {
    final db = await instance.database;
    final resultado = await db.rawQuery('''
      SELECT user_app.*, rol_permiso.rol as rol_nombre
      FROM user_app
      INNER JOIN rol_permiso ON user_app.role_id = rol_permiso.id
      WHERE LOWER(user_app.correo) = ?
      LIMIT 1
    ''', [correo.trim().toLowerCase()]);
    return resultado.isNotEmpty ? resultado.first : null;
  }

  Future<bool> existeRol(int roleId) async {
    final db = await instance.database;
    final resultado = await db.query(
      'rol_permiso',
      where: 'id = ?',
      whereArgs: [roleId],
    );
    return resultado.isNotEmpty;
  }

  Future<int> contarAdmins() async {
    final db = await instance.database;
    final resultado = await db.rawQuery(
      'SELECT COUNT(*) as total FROM user_app WHERE role_id = 1',
    );
    return Sqflite.firstIntValue(resultado) ?? 0;
  }

  // ══════════════════════════════════════════════════════════════
  // MÉTODOS DE AUTENTICACIÓN / LOGIN
  // ══════════════════════════════════════════════════════════════

  Future<bool> esAdmin(String correo, String pass) async {
    final db = await instance.database;
    final resultado = await db.rawQuery('''
      SELECT user_app.*, rol_permiso.rol as rol_nombre
      FROM user_app
      INNER JOIN rol_permiso ON user_app.role_id = rol_permiso.id
      WHERE user_app.correo = ? AND user_app.pass = ? AND rol_permiso.rol = 'Administrador'
    ''', [correo, pass]);

    return resultado.isNotEmpty;
  }

  Future<bool> esUsuario(String correo, String pass) async {
    final db = await instance.database;
    final resultado = await db.rawQuery('''
      SELECT user_app.*, rol_permiso.rol as rol_nombre
      FROM user_app
      INNER JOIN rol_permiso ON user_app.role_id = rol_permiso.id
      WHERE user_app.correo = ? AND user_app.pass = ? AND rol_permiso.rol = 'Usuario'
    ''', [correo, pass]);

    return resultado.isNotEmpty;
  }
}
