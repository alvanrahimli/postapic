import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import 'src/services.dart';
import 'src/ui/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  configureServices(GetIt.instance);
  await GetIt.instance.allReady();

  runApp(const TheApp());
}
