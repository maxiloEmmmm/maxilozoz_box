import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart' as sqliteSDk;

typedef Database = sqliteSDk.Database;

class sqlite {
  String path = "";
  String schema = "";
  dynamic migrate;
  sqlite(this.path, this.schema, this.migrate);

  Database? instance;

  static String migrateTableName = "migrate";
  static const versionField = "version";
  static const sqlField = "sql";
  static const statusField = "status";
  static const CompleteStatus = 1;
  static const WaitStatus = 0;
  String migrateTableSchema = '''
create table $migrateTableName(
  $versionField INTEGER,
  $sqlField TEXT,
  $statusField INTEGER
);
''';

  Future<Database?> DB() async {
    if (instance == null) {
      try {
        var db = await sqliteSDk.openDatabase(path, version: 1, onCreate: (db, version) async {
          await db.execute('''
$migrateTableSchema
$schema
''');
        });

        if (migrate != null && migrate is List<String>) {
          List<String> m = migrate as List<String>;
          for (var i = 0; i < m.length; i++) {
            var rows = await db.query(migrateTableName, where: "$versionField = ?", whereArgs: [i]);
            // sql的改动应以追加sql 不应替换原有
            // 所以不对比相同version sql的变化
            if(rows.isEmpty) {
              await db.insert(migrateTableName, {
                "$versionField": i,
                "$sqlField": m[i],
                "$statusField": WaitStatus,
              });
            }else if(rows[0][sqlField] != m[i]) {
              print("warn: sql change ${rows[0][sqlField]} => ${m[i]}");
              await db.update(migrateTableName, {sqlField: m[i]}, where: "$versionField = ?", whereArgs: [i]);
            }
          }

          await db.delete(migrateTableName, where: "$versionField >= ${m.length}");
        }else {
          await db.delete(migrateTableName);
        }

        var rows = await db.query(migrateTableName, where: "$statusField = ?", whereArgs: [WaitStatus], orderBy: "$versionField ASC");
        for (var i = 0; i < rows.length; i++) {
          await db.execute(rows[i][sqlField]! as String);
          await db.update(
              migrateTableName,
              {statusField: CompleteStatus,},
              where: "$versionField = ? and $statusField = ?",
              whereArgs: [CompleteStatus, WaitStatus]);
        }

        instance = db;
        return db;
      } catch (e) {
        return null;
      }
    }

    return instance;
  }
}
