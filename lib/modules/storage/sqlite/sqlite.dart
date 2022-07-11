import 'package:sqflite/sqflite.dart';

class sqlite {
  String path = "";
  String schema = "";
  sqlite(this.path, this.schema);

  Database? instance;

  Future<Database?> DB() async {
    if (instance == null) {
      try {
        var db =
            await openDatabase(path, version: 1, onCreate: (db, version) async {
          await db.execute(schema);
        });
        instance = db;
        return db;
      } catch (e) {
        return null;
      }
    }

    return instance;
  }
}
