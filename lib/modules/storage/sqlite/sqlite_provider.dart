import 'package:maxilozoz_box/application.dart';
import 'package:maxilozoz_box/modules/storage/sqlite/sqlite.dart';

class SqliteProvider {
  String get name {
    return 'sqlite';
  }

  void register(Application app) {
    app.bind(name, (Application app, dynamic params) {
      if (app.config('db_enable') ?? false) {
        // if relative path, add warn will store on app document dir with db file
        return sqlite(
            app.config('db_path') ?? 'db', app.config('db_schema') ?? '', app.config("db_migrate") ?? "");
      }
      return null;
    });
  }

  void boot(Application app) {}
}
