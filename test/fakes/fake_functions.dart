import 'package:cloud_functions/cloud_functions.dart';

/// A callable that records its parameters and answers with [respond].
class FakeCallable implements HttpsCallable {
  final Future<dynamic> Function(dynamic parameters) respond;
  final calls = <dynamic>[];

  FakeCallable(this.respond);

  @override
  Future<HttpsCallableResult<T>> call<T>([dynamic parameters]) async {
    calls.add(parameters);
    return _Result<T>(await respond(parameters) as T);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Result<T> implements HttpsCallableResult<T> {
  @override
  final T data;

  _Result(this.data);
}

/// [FirebaseFunctions] that serves [callables] by name, for tests.
class FakeFunctions implements FirebaseFunctions {
  final Map<String, FakeCallable> callables;

  FakeFunctions(this.callables);

  @override
  HttpsCallable httpsCallable(String name, {HttpsCallableOptions? options}) =>
      callables[name]!;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// The message the functions send when YouTube's quota is used up.
const youTubeQuotaMessage =
    "YouTube's daily quota for sending and moderating chat is used up. "
    "It resets at midnight Pacific time.";

FirebaseFunctionsException youTubeQuotaError() => FirebaseFunctionsException(
    code: 'resource-exhausted', message: youTubeQuotaMessage);
