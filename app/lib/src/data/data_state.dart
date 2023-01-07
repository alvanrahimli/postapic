// ignore_for_file: unnecessary_this, prefer_initializing_formals

import 'package:flutter/foundation.dart';

enum LoadingStatus { unloaded, loading, error, ready }

@immutable
class DataState<T> {
  const DataState.initial({this.data, this.error})
      : status = LoadingStatus.unloaded;

  const DataState.loading({this.data, this.error})
      : status = LoadingStatus.loading;

  const DataState.error(Object error, {this.data})
      : status = LoadingStatus.error,
        this.error = error;

  const DataState.ready(T data, {this.error})
      : status = LoadingStatus.ready,
        this.data = data;

  factory DataState.errorWithTrace(Object error, StackTrace stackTrace,
          {T? data}) =>
      DataState.error(ErrorWithTrace(error, stackTrace), data: data);

  final LoadingStatus status;
  final T? data;
  final Object? error;

  bool get isLoading => status == LoadingStatus.loading;
  bool get isReady => status == LoadingStatus.ready;
  bool get isError => status == LoadingStatus.error;

  bool get hasData => data != null;
  bool get hasError => error != null;

  ErrorWithTrace? toErrorWithTrace() {
    if (error is ErrorWithTrace) {
      return error as ErrorWithTrace;
    }
    if (error != null) {
      return ErrorWithTrace(error!, null);
    }
    return null;
  }

  E select<E>({
    E Function()? initial,
    E Function()? loading,
    E Function(Object error)? error,
    E Function(T data)? ready,
    E Function()? fallback,
  }) {
    switch (status) {
      case LoadingStatus.unloaded:
        if (initial != null) return initial();
        break;
      case LoadingStatus.loading:
        if (loading != null) return loading();
        break;
      case LoadingStatus.error:
        if (error != null) return error(this.error!);
        break;
      case LoadingStatus.ready:
        if (ready != null) return ready(data as T);
        break;
    }

    if (fallback != null) {
      return fallback();
    }

    throw Exception('Selector is not defined for $status state');
  }
}

class ErrorWithTrace {
  const ErrorWithTrace(this.error, this.stackTrace);

  final Object error;
  final StackTrace? stackTrace;

  @override
  String toString() {
    var str = error.toString();
    if (stackTrace != null) {
      str += '\n$stackTrace';
    }
    return str;
  }
}
