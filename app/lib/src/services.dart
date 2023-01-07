import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:postapic/src/config.dart';
import 'package:postapic/src/data/api.dart';
import 'package:postapic/src/data/api/rest_client.dart';
import 'package:postapic/src/data/blocs/posts/posts_cubit.dart';
import 'package:postapic/src/data/repositories/post_repository.dart';

import 'logger.dart';

void configureServices(GetIt services) {
  services.registerSingleton(LoggerFactory());

  services.registerFactory<Dio>(() {
    final httpLogger = services.get<LoggerFactory>().createWithName('http');
    final httpClient = Dio()
      ..interceptors.add(LogInterceptor(logPrint: httpLogger.info));
    return httpClient;
  });

  services.registerSingleton<ApiClient>(RestApiClient(
    services.get<Dio>(),
    baseUrl: apiBaseUrl,
  ));
  services.registerSingleton(PostRepository(
    services.get<ApiClient>(),
    services.get<LoggerFactory>().create<PostRepository>(),
  ));

  services.registerFactory(
    () => PostsCubit(
      services.get<PostRepository>(),
    ),
  );
}
