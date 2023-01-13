import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'auth_client.dart';

export 'auth_client.dart' show AuthenticationState;

class AuthCubit extends Cubit<AuthenticationState?> {
  final AuthenticationClient _client;
  late final StreamSubscription _subscription;

  AuthCubit(this._client) : super(null) {
    _subscription = _client.stream.listen(emit);
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    await super.close();
  }

  Future<AuthenticationState?> login({
    required String username,
    required String password,
  }) {
    return _client.login(
      username: username,
      password: password,
    );
  }

  Future<void> logout() {
    return _client.logout();
  }
}
