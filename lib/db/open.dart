import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;
import 'migrations.dart';

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
