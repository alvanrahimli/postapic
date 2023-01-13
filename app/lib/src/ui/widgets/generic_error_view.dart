import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:postapic/src/data/data_state.dart';

class GenericErrorView extends StatelessWidget {
  final String title;
  final String message;
  final Object? error;
  final StackTrace? stackTrace;
  final EdgeInsets padding;

  static const defaultPadding = EdgeInsets.symmetric(vertical: 15);

  GenericErrorView({
    super.key,
    this.title = 'Uh, oh!',
    this.message = 'Something went wrong.',
    Object? error,
    StackTrace? stackTrace,
    this.padding = defaultPadding,
  })  : error = error is ErrorWithTrace ? error.error : error,
        stackTrace =
            stackTrace ?? (error is ErrorWithTrace ? error.stackTrace : null);

  void copyDetailsToClipboard() {
    Clipboard.setData(ClipboardData(
      text: '$error\n\nStack trace:\n$stackTrace',
    ));
  }

  void showMoreDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Details'),
        content: ListView(
          children: [
            Text(error?.toString() ?? ''),
            if (stackTrace != null) ...[
              const SizedBox(height: 15),
              Text(stackTrace.toString()),
            ]
          ],
        ),
        actions: [
          TextButton(
            onPressed: copyDetailsToClipboard,
            child: const Text('Copy to clipboard'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: padding,
      child: Column(
        children: [
          Text(title, style: theme.textTheme.bodyLarge),
          Text(message, style: theme.textTheme.bodyMedium),
          if (error != null) ...[
            const SizedBox(height: 15),
            TextButton(
              onPressed: () => showMoreDetails(context),
              child: const Text('More details'),
            ),
          ]
        ],
      ),
    );
  }
}
