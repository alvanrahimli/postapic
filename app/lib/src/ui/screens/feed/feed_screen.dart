import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
      appBar: AppBar(title: const Text('Feed')),
      body: BlocBuilder<PostsCubit, PostsCubitState>(
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

    Widget leList = CustomScrollView(
      slivers: [
        if (Platform.isIOS)
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
    );

    if (!Platform.isIOS) {
      leList = RefreshIndicator(
        onRefresh: postsCubit.reloadAll,
        child: leList,
      );
    }

    return LazyLoader(
      onEndOfPage: postsCubit.loadMore,
      child: leList,
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
        FeedImage(image: post.image),
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

class FeedImage extends StatelessWidget {
  final ImageRef image;
  final String _imageUrl;

  FeedImage({super.key, required this.image})
      : _imageUrl = _toFullUrl(image.url);

  static String _toFullUrl(String imageUrl) {
    return (imageUrl.startsWith('https://') || imageUrl.startsWith('http://'))
        ? imageUrl
        : Uri.parse(apiBaseUrl).resolve(imageUrl).toString();
  }

  @override
  Widget build(BuildContext context) {
    Widget child = Image(
      image: CachedNetworkImageProvider(_imageUrl),
      errorBuilder: (context, error, stackTrace) {
        return GenericErrorView(
          message: 'Failed to load the image',
          error: error,
          stackTrace: stackTrace,
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        return loadingProgress == null ? child : const SizedBox(height: 300);
      },
    );

    if (image.width > 0 && image.height > 0) {
      return AspectRatio(
        aspectRatio: image.width / image.height,
        child: child,
      );
    }

    return child;
  }
}

String prettyDate(DateTime value) {
  return timeago.format(value, locale: 'en');
}
