import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rtchat/api.dart';

class _Callable extends Fake implements HttpsCallable {}

class _Functions extends Fake implements FirebaseFunctions {
  final callable = _Callable();
  String? name;
  String? url;
  String? emulatorHost;
  int? emulatorPort;

  @override
  HttpsCallable httpsCallable(String name, {HttpsCallableOptions? options}) {
    this.name = name;
    return callable;
  }

  @override
  HttpsCallable httpsCallableFromUrl(String url,
      {HttpsCallableOptions? options}) {
    this.url = url;
    return callable;
  }

  @override
  void useFunctionsEmulator(String host, int port,
      {bool automaticHostMapping = true}) {
    emulatorHost = host;
    emulatorPort = port;
  }
}

void main() {
  test('public calls use the custom URL through the Firebase callable SDK', () {
    final functions = _Functions();
    final api = Api(functions);

    expect(api.callable('send'), same(functions.callable));
    expect(functions.url, 'https://rtchat-api.rtirl.com/send');
    expect(functions.name, isNull);
  });

  test('emulator calls stay local and use the named function protocol', () {
    final functions = _Functions();
    final api = Api(functions);

    api.useEmulator('localhost', 5999);
    expect(api.callable('subscribe'), same(functions.callable));
    expect(functions.emulatorHost, 'localhost');
    expect(functions.emulatorPort, 5999);
    expect(functions.name, 'subscribe');
    expect(functions.url, isNull);
  });
}
