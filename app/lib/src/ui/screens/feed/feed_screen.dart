import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:postapic/src/config.dart';
import 'package:postapic/src/data/blocs.dart';
import 'package:postapic/src/ui/widgets/generic_error_view.dart';
import 'package:postapic/src/ui/widgets/lazy_loader.dart';
import 'package:timeago/timeago.dart' as timeago;

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Post a Pic')),
      body: BlocProvider(
        create: (context) => GetIt.instance.get<PostsCubit>(),
        child: BlocBuilder<PostsCubit, PostsCubitState>(
          builder: (context, state) {
            if (!state.hasData && state.isLoading) {
              return const Center(child: CupertinoActivityIndicator());
            }

            return FeedList(
              posts: state.data ?? const [],
              tailing: state.select(
                error: (_) => Padding(
                  padding: const EdgeInsets.all(15),
                  child: GenericErrorView(error: state.toErrorWithTrace()),
                ),
                loading: () => const SizedBox(
                  height: 50,
                  child: Center(child: CupertinoActivityIndicator()),
                ),
                fallback: () => null,
              ),
            );
          },
        ),
      ),
    );
  }
}

class FeedList extends StatelessWidget {
  final List<Post> posts;
  final Widget? tailing;

  const FeedList({
    super.key,
    required this.posts,
    this.tailing,
  });

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final postsCubit = context.read<PostsCubit>();

    final delegate = SliverChildBuilderDelegate(
      (context, index) {
        return FeedTile(post: posts[index]);
      },
      childCount: posts.length,
      addSemanticIndexes: true,
    );

    const staticPadding = EdgeInsets.only(bottom: 20);

    return LazyLoader(
      onEndOfPage: postsCubit.loadMore,
      child: CustomScrollView(
        slivers: [
          CupertinoSliverRefreshControl(onRefresh: postsCubit.reloadAll),
          SliverPadding(
            padding: tailing == null
                ? mediaQuery.padding.add(staticPadding)
                : EdgeInsets.fromLTRB(mediaQuery.padding.left,
                    mediaQuery.padding.top, mediaQuery.padding.right, 0),
            sliver: SliverList(
              delegate: delegate,
            ),
          ),
          if (tailing != null)
            SliverPadding(
              padding: EdgeInsets.only(bottom: mediaQuery.padding.bottom)
                  .add(staticPadding),
              sliver: SliverToBoxAdapter(child: tailing),
            ),
        ],
      ),
    );
  }
}

class FeedTile extends StatelessWidget {
  FeedTile({required this.post}) : super(key: ValueKey(post.id));

  final Post post;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Text(post.title, style: theme.textTheme.bodyLarge),
        ),
        Image(
          image: CachedNetworkImageProvider(fullImageUrl(post.imageUrl)),
          errorBuilder: (context, error, stackTrace) {
            return GenericErrorView(
              message: 'Failed to load the image',
              error: error,
              stackTrace: stackTrace,
            );
          },
          loadingBuilder: (context, child, loadingProgress) {
            return loadingProgress == null
                ? child
                : const SizedBox(height: 300);
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '@${post.author.userName}',
                  style: theme.textTheme.bodySmall,
                ),
              ),
              Text(
                prettyDate(post.createdAt),
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const Divider(height: 1, thickness: 1),
        const SizedBox(height: 15),
      ],
    );
  }
}

String prettyDate(DateTime value) {
  return timeago.format(value, locale: 'en');
}

String fullImageUrl(String imageUrl) {
  if (imageUrl.startsWith('https://') || imageUrl.startsWith('http://')) {
    return imageUrl;
  }

  return Uri.parse(apiBaseUrl).resolve(imageUrl).toString();
}
