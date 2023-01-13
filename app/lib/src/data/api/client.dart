import 'dart:io';
import 'dart:math';

import 'models.dart';

abstract class ApiClient {
  Future<List<Post>> getPosts({required int offset, required int limit});

  Future<LoginResult> login({
    required String username,
    required String password,
  });

  Future<void> upload({
    required String authorizationHeader,
    required String title,
    required File picture,
  });
}

class MockApiClient implements ApiClient {
  @override
  Future<List<Post>> getPosts({required int offset, required int limit}) {
    return _mocked(List.generate(
      limit,
      (index) => Post(
        offset + index,
        'Post $index',
        const ImageRef(
          'https://wc.rahim.li/images/2023-01-06T21-24-21-99.webp',
          0,
          0,
        ),
        DateTime.now(),
        const User(1, 'themisir'),
      ),
    ));
  }

  @override
  Future<LoginResult> login({
    required String username,
    required String password,
  }) {
    return _mocked(LoginResult('asjhdjkahdjkahs', User(3, username)));
  }

  @override
  Future<void> upload({
    required String authorizationHeader,
    required String title,
    required File picture,
  }) {
    return _mocked<void>(null);
  }

  static final _random = Random();
  static const _errorRate = 0.1;
  static const _minDelay = Duration(seconds: 2);
  static const _maxDelay = Duration(seconds: 8);

  static Future<T> _mocked<T>(T response) async {
    await Future.delayed(
        _minDelay + (_maxDelay - _minDelay) * _random.nextDouble());
    if (_random.nextDouble() <= _errorRate) {
      throw Exception("Mock response error");
    }
    return response;
  }
}
