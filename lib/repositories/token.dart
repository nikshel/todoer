import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class Token {
  String value;
  DateTime expireAt;

  Token(this.value, this.expireAt);
}

class TokenRepository {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );
  final String _tokenValueKey;
  final String _tokenExpireAtKey;

  TokenRepository(String keyPrefix)
      : _tokenValueKey = '$keyPrefix::token.value',
        _tokenExpireAtKey = '$keyPrefix::token.expireAt';

  Future<Token?> getToken() async {
    var [value, rawExpireAt] = await Future.wait<String?>([
      _storage.read(key: _tokenValueKey),
      _storage.read(key: _tokenExpireAtKey),
    ]);

    if (value == null || rawExpireAt == null) {
      return null;
    }

    return Token(value, DateTime.parse(rawExpireAt));
  }

  Future saveToken(Token token) async {
    await Future.wait([
      _storage.write(key: _tokenValueKey, value: token.value),
      _storage.write(
          key: _tokenExpireAtKey, value: token.expireAt.toIso8601String()),
    ]);
  }

  Future deleteToken() async {
    await Future.wait([
      _storage.delete(key: _tokenValueKey),
      _storage.delete(key: _tokenExpireAtKey),
    ]);
  }
}
