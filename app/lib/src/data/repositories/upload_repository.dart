import 'dart:io';

import 'package:logging/logging.dart';
import 'package:postapic/src/data/api.dart';
import 'package:postapic/src/data/blocs/auth/auth_client.dart';

class UploadRepository {
  final AuthenticationClient _authenticationClient;
  final ApiClient _apiClient;
  final Logger _logger;

  const UploadRepository(
    this._authenticationClient,
    this._apiClient,
    this._logger,
  );

  Future<void> upload({required String title, required File picture}) async {
    try {
      return await _apiClient.upload(
        authorizationHeader:
            'Bearer ${_authenticationClient.state?.accessToken}',
        title: title,
        picture: picture,
      );
    } catch (error, stackTrace) {
      _logger.shout(
        'Failed to upload a new post using the api client',
        error,
        stackTrace,
      );
      rethrow;
    }
  }
}
