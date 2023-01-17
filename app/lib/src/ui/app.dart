import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:postapic/src/data/blocs/auth/auth_cubit.dart';
import 'package:postapic/src/data/blocs/posts/posts_cubit.dart';

import 'screens/main/main_screen.dart';

class TheApp extends StatelessWidget {
  const TheApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => GetIt.instance.get<AuthCubit>(),
          lazy: false,
        ),
        BlocProvider(create: (context) => GetIt.instance.get<PostsCubit>()),
      ],
      child: MaterialApp(
        title: 'Post a Pic',
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.dark,
        theme: ThemeData.light(useMaterial3: true),
        darkTheme: ThemeData.dark(useMaterial3: true),
        home: const MainScreen(),
      ),
    );
  }
}
