import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logging/logging.dart';
import 'package:postapic/src/data/api.dart';

class AuthenticationClient {
  AuthenticationClient(this._tokenStore, this._apiClient, this._logger) {
    _load();
  }

  AuthenticationState? get state => _state;
  Stream<AuthenticationState?> get stream async* {
    yield _state;
    yield* _controller.stream;
  }

  Future<AuthenticationState?> login({
    required String username,
    required String password,
  }) async {
    try {
      final result = await _apiClient.login(
        username: username,
        password: password,
      );
      final state = AuthenticationState(result.token, result.user);

      try {
        _tokenStore.write(state);
      } catch (error, stackTrace) {
        _logger.shout(
          'Failed to save auth state on the store',
          error,
          stackTrace,
        );
      }

      _emit(state);
      return state;
    } catch (error, stackTrace) {
      _logger.warning('Login API returned error', error, stackTrace);
      return null;
    }
  }

  Future<void> logout() async {
    try {
      _tokenStore.clear();
    } catch (error, stackTrace) {
      _logger.shout(
        'Failed to clear auth state from the store',
        error,
        stackTrace,
      );
    }

    _emit(null);
  }

  final Logger _logger;
  final TokenStore _tokenStore;
  final ApiClient _apiClient;
  final _controller = StreamController<AuthenticationState?>.broadcast();
  AuthenticationState? _state;

  void _emit(AuthenticationState? state) {
    if (_state != state) {
      _state = state;
      _controller.add(state);
    }
  }

  Future<void> _load() async {
    try {
      final savedState = await _tokenStore.read();
      _emit(savedState);
    } catch (error, stackTrace) {
      _logger.shout(
        'Failed to load auth state from the store',
        error,
        stackTrace,
      );
    }
  }
}

class AuthenticationState {
  const AuthenticationState(this.accessToken, this.user);

  final String accessToken;
  final User user;
}

abstract class TokenStore {
  Future<void> write(AuthenticationState token);
  Future<AuthenticationState?> read();
  Future<void> clear();
}

class FlutterSecureStorageTokenStore implements TokenStore {
  static const _storage = FlutterSecureStorage();

  static const _authTokenKey = 'Auth.v1.token';
  static const _authUserIdKey = 'Auth.v1.user.id';
  static const _authUserNameKey = 'Auth.v1.user.userName';

  @override
  Future<AuthenticationState?> read() async {
    final accessToken = await _storage.read(key: _authTokenKey);
    final userIdS = await _storage.read(key: _authUserIdKey);
    final userId = userIdS != null ? int.tryParse(userIdS) : null;
    final userName = await _storage.read(key: _authUserNameKey);

    if (accessToken != null && userId != null && userName != null) {
      return AuthenticationState(accessToken, User(userId, userName));
    }

    return null;
  }

  @override
  Future<void> write(AuthenticationState token) async {
    await _storage.write(key: _authTokenKey, value: token.accessToken);
    await _storage.write(key: _authUserIdKey, value: token.user.id.toString());
    await _storage.write(key: _authUserNameKey, value: token.user.userName);
  }

  @override
  Future<void> clear() async {
    for (final key in const [_authTokenKey, _authUserIdKey, _authUserNameKey]) {
      await _storage.delete(key: key);
    }
  }
}
