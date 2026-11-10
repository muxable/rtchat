import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rtchat/api.dart';
import 'package:rtchat/models/accounts.dart';

class _Result<T> extends Fake implements HttpsCallableResult<T> {
  @override
  final T data;

  _Result(this.data);
}

class _Callable extends Fake implements HttpsCallable {
  final FakeFunctions functions;
  final String name;

  _Callable(this.functions, this.name);

  @override
  Future<HttpsCallableResult<T>> call<T>([dynamic parameters]) async {
    functions.calls.add((name: name, data: parameters));
    return _Result<T>(null as T);
  }
}

/// A [FirebaseFunctions] that records the callables called through it.
class FakeFunctions extends Fake implements FirebaseFunctions {
  final calls = <({String name, dynamic data})>[];

  @override
  HttpsCallable httpsCallableFromUrl(
    String url, {
    HttpsCallableOptions? options,
  }) => _Callable(this, Uri.parse(url).pathSegments.last);
}

/// Makes [Api.forAccount] call through fake functions for [account],
/// returning them. Tests using it should call [Api.debugReset] in tearDown.
FakeFunctions fakeApiFor(Account account) {
  final functions = FakeFunctions();
  Api.debugOverride(account.app, Api(functions));
  return functions;
}
