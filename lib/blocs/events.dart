import 'package:todoer/blocs/auth.dart';

class AuthEvent {
  AuthState newAuthState;

  AuthEvent(this.newAuthState);
}
