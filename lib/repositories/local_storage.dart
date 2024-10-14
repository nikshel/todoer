import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class LocalStorageRepository {
  final Box _cacheBox;

  LocalStorageRepository(this._cacheBox);

  static Future<LocalStorageRepository> create() async {
    var dir = await getApplicationSupportDirectory();
    var dbPath = p.join(dir.path, 'hive');

    Hive.init(dbPath);
    var box = await Hive.openBox('cache');
    return LocalStorageRepository(box);
  }

  Future<dynamic> getCachedValue(String key) async {
    return await _cacheBox.get(key);
  }

  setCachedValue(String key, dynamic value) async {
    await _cacheBox.put(key, value);
  }
}
