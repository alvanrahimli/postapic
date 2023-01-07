import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:postapic/src/data/api.dart';
import 'package:postapic/src/data/data_state.dart';
import 'package:postapic/src/data/repositories/post_repository.dart';

typedef PostsCubitState = DataState<List<Post>>;

class PostsCubit extends Cubit<PostsCubitState> {
  final int postsPerPage;
  final PostRepository _postRepository;

  PostsCubit(
    this._postRepository, {
    this.postsPerPage = 10,
  }) : super(const PostsCubitState.initial()) {
    loadMore();
  }

  var _reachedToTheEnd = false;
  var _latestRequestId = 0;
  var _loadingMore = false;

  Future<void> loadMore() async {
    if (_loadingMore) return;

    _loadingMore = true;
    try {
      await _load(offset: state.data?.length ?? 0, reset: false);
    } finally {
      _loadingMore = false;
    }
  }

  Future<void> reloadAll() {
    return _load(offset: 0, reset: true);
  }

  Future<void> _load({required int offset, required bool reset}) async {
    if (_reachedToTheEnd && !reset) {
      return;
    }

    var currentRequestId = ++_latestRequestId;

    try {
      // emit loading state (ignore previous state if a reset is requested)
      emit(DataState.loading(data: reset ? null : state.data));

      final posts = await _postRepository.getPosts(
        offset: offset,
        limit: postsPerPage,
      );

      // ignore previous requests, henceforth fixes race conditions
      if (currentRequestId != _latestRequestId) {
        return;
      }

      // readed to the end if there's no remaining posts
      if (posts.isEmpty) {
        _reachedToTheEnd = true;
      }

      // insert previously read data in front of the response to continue pagination
      if (!reset && state.hasData) {
        posts.insertAll(0, state.data!);
      }

      emit(PostsCubitState.ready(posts));
    } catch (error, stackTrace) {
      emit(PostsCubitState.errorWithTrace(error, stackTrace, data: state.data));
    }
  }
}
