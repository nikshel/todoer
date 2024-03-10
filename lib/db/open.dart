import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;

final List<String> migrations = [
  '''
  CREATE TABLE tasks (
    id INTEGER PRIMARY KEY,
    title TEXT NOT NULL,
    done INTEGER NOT NULL,
    parent_id INTEGER,
    idx INTEGER,

    FOREIGN KEY(parent_id) REFERENCES tasks(id) ON DELETE CASCADE
  ) STRICT;
  
  CREATE UNIQUE INDEX ux_tasks_parent_idx ON tasks(COALESCE(parent_id, -1), idx);
  '''
];

Future<Database> openDatabase() async {
  sqfliteFfiInit();

  var dir = await getApplicationSupportDirectory();
  var dbPath = p.join(dir.path, 'todoer.db');

  return await databaseFactoryFfi.openDatabase(
    dbPath,
    options: OpenDatabaseOptions(
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys=ON');
      },
      version: migrations.length,
      onUpgrade: (db, oldVersion, newVersion) async {
        for (var i = oldVersion; i < newVersion; i++) {
          await db.execute(migrations[i]);
        }
      },
      onDowngrade: (db, oldVersion, newVersion) {
        throw Exception('Downgrade not supported');
      },
    ),
  );
}
