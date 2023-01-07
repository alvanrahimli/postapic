import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

class LoggerFactory {
  final _loggers = <String, int>{};

  Logger createWithName(String name) {
    _ensureInitialized();

    final count = _loggers.update(name, (v) => v + 1, ifAbsent: () => 1);
    if (count > 1) {
      name = '$name [$count]';
    }

    return Logger(name);
  }

  Logger create<T>() => createWithName(T.toString());

  var _initialized = false;
  void _ensureInitialized() {
    if (!_initialized) {
      Logger.root.level = kDebugMode ? Level.ALL : Level.WARNING;
      Logger.root.onRecord.listen((record) {
        final line = '${record.level.name}: ${record.time}: ${record.message}';
        stdout.writeln(line);

        if (record.error != null) {
          stderr.writeln(record.error);
          if (record.stackTrace != null) {
            stderr.writeln(record.stackTrace);
          }
        }
      });

      _initialized = true;
    }
  }
}
