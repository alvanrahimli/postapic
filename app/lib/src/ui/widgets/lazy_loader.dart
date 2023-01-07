import 'package:flutter/widgets.dart';

class LazyLoader extends StatefulWidget {
  const LazyLoader({
    super.key,
    required this.child,
    required this.onEndOfPage,
    this.scrollOffset = 0,
    this.scrollDirection = Axis.vertical,
  });

  final Widget child;
  final Future<void> Function() onEndOfPage;
  final int scrollOffset;
  final Axis scrollDirection;

  @override
  State<LazyLoader> createState() => _LazyLoaderState();
}

class _LazyLoaderState extends State<LazyLoader> {
  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: _onNotification,
      child: widget.child,
    );
  }

  bool _onNotification(ScrollNotification notification) {
    if (widget.scrollDirection == notification.metrics.axis) {
      if (notification is ScrollUpdateNotification) {
        if (notification.metrics.maxScrollExtent -
                notification.metrics.pixels <=
            widget.scrollOffset) {
          _loadMore();
        }
        return true;
      }

      if (notification is OverscrollNotification) {
        if (notification.overscroll > 0) {
          _loadMore();
        }
        return true;
      }
    }
    return false;
  }

  var _loading = false;

  void _loadMore() async {
    if (!_loading) {
      _loading = true;
      try {
        await widget.onEndOfPage();
      } finally {
        _loading = false;
      }
    }
  }
}
