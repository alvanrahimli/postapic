import 'package:logging/logging.dart';
import 'package:postapic/src/data/api.dart';

class PostRepository {
  final ApiClient _apiClient;
  final Logger _logger;

  const PostRepository(this._apiClient, this._logger);

  Future<List<Post>> getPosts({required int offset, required int limit}) async {
    try {
      return await _apiClient.getPosts(offset: offset, limit: limit);
    } catch (error, stackTrace) {
      _logger.shout(
        'Failed to request posts from api client',
        error,
        stackTrace,
      );
      rethrow;
    }
  }
}
