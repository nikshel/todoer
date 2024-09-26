import 'package:app_links/app_links.dart';
import 'package:event_bus/event_bus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:todoer/blocs/events.dart';
import 'package:todoer/client.dart';

import 'package:todoer/repositories/token.dart';
import 'package:url_launcher/url_launcher.dart';

const String loginUrlPath = '/auth/social/login/{provider}/';
const String loginNextUrlPath = '/auth/v1/login_app/';

class AuthState {
  final String? token;
  bool get authorized => token != null;

  AuthState(Token? fullToken) : token = fullToken?.value;
}

class AuthCubit extends Cubit<AuthState> {
  static final AppLinks _appLinks = AppLinks();

  final TokenRepository _tokenRepository;
  final EventBus _eventBus;
  final TodoerClient _todoerClient;
  final Uri _todoerUrl;

  AuthCubit(this._tokenRepository, this._eventBus, this._todoerClient,
      this._todoerUrl)
      : super(AuthState(null)) {
    _loadSavedToken();
    _appLinks.uriLinkStream.listen((uri) {
      var token = uri.queryParameters['token']!;
      var rawExpireAt = uri.queryParameters['expire']!;
      _saveToken(Token(token, DateTime.parse(rawExpireAt)));
    });
  }

  startLogin([String provider = 'yandex']) async {
    var loginUrl = _todoerUrl.replace(
      path: _todoerUrl.path +
          loginUrlPath.replaceFirst(RegExp(r'{provider}'), provider),
      queryParameters: {'next': loginNextUrlPath},
    );
    await launchUrl(loginUrl, mode: LaunchMode.externalApplication);
  }

  _saveToken(Token token) async {
    await _tokenRepository.saveToken(token);
    _todoerClient.setToken(token.value);
    _emitState(token);
  }

  logout() async {
    try {
      await _todoerClient.logoutToken();
    } catch (e) {}
    await _tokenRepository.deleteToken();
    _todoerClient.setToken(null);
    _emitState(null);
  }

  _loadSavedToken() async {
    Token? token = await _tokenRepository.getToken();
    if (token != null &&
        token.expireAt
            .subtract(const Duration(days: 1))
            .isAfter(DateTime.now())) {
      _todoerClient.setToken(token.value);
      _emitState(token);
    }
  }

  _emitState(Token? token) {
    var state = AuthState(token);
    emit(state);
    _eventBus.fire(AuthEvent(state));
  }
}
