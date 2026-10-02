import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class SqlDb {
  static Database? _db;
  // String profiles = '''
  //   CREATE TABLE profiles (
  //     username INTEGER,
  //     password INTEGER,
  //     rows INTEGER,
  //     columns INTEGER,
  //     // usernamelength INTEGER,
  //     // passwordlength INTEGER,
  //     usernamefont REAL,
  //     passwordfont REAL,
  //     usernamelocationx REAL,
  //     usernamelocationy REAL,
  //     passwordlocationx REAL,
  //     passwordlocationy REAL
  //   );
  //   ''';
  // password = {0,1}
  String templates="""
    CREATE TABLE templates (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      password INTEGER,
      serial INTEGER DEFAULT 0,
      image BLOB NOT NULL,
      rows INTEGER,
      columns INTEGER,
      username_fontsize REAL,
      password_fontsize REAL,
      username_location_x REAL,
      username_location_y REAL,
      password_location_x REAL,
      password_location_y REAL
    );
  """;

  String batches="""
    CREATE TABLE batches (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      created_at INTEGER ,
      template_id INTEGER,
      generated_cards TEXT,
      cards_profile TEXT,
      card_prefix TEXT,
      card_suffix TEXT,
      customer TEXT,
      router_serial TEXT
    );
  """;

  String cards="""
    CREATE TABLE cards (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      username TEXT NOT NULL,
      password TEXT ,
      profile_name TEXT,
      batch_id INTEGER,
      is_add INTEGER,
      FOREIGN KEY (batch_id) REFERENCES batches(id) ON DELETE CASCADE
    );
  """;

  String savedLogins="""
    CREATE TABLE saved_logins (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      host TEXT,
      username TEXT ,
      password TEXT,
      port TEXT,
      name TEXT
    );
  """;

  

  Future<Database?> get db async {
    if (_db == null || !_db!.isOpen) {
      _db = await _initializeDb();
      return _db;
    } else {
      return _db;
    }
  }

  Future<Database> _initializeDb() async {
    String databasePath = await getDatabasesPath();
    String path = join(databasePath, "mikrotik.db");
    Database database = await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onConfigure: (db) async {
        await db.execute("PRAGMA foreign_keys = ON");
      },
    );
    return database;
  }

  Future<void> _onCreate(Database db, int version) async {
    Batch mybatch = db.batch();

    mybatch.execute(templates);
    mybatch.execute(batches);
    mybatch.execute(cards);
    mybatch.execute(savedLogins);
    // mybatch.execute(inss);

    await mybatch.commit();

    // ????? ????? ???? ??????? ???.
  }
  // @protected
  Future<List<Map>> readData(String sql) async {
    Database? myDb = await db;
    return await myDb!.rawQuery(sql);
  }
  // @protected
  Future<int> insertData(String sql) async {
    Database? myDb = await db;
    return await myDb!.rawInsert(sql);
  }
  // @protected
  Future<int> updateData(String sql) async {
    Database? myDb = await db;
    return await myDb!.rawUpdate(sql);
  }
  // @protected
  Future<int> deleteData(String sql) async {
    Database? myDb = await db;
    return await myDb!.rawDelete(sql);
  }
}
