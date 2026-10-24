import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rtchat/api.dart';
import 'package:rtchat/models/channels.dart';

import 'fakes/fake_accounts.dart';

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
  HttpsCallable httpsCallableFromUrl(
    String url, {
    HttpsCallableOptions? options,
  }) {
    this.url = url;
    return callable;
  }

  @override
  void useFunctionsEmulator(
    String host,
    int port, {
    bool automaticHostMapping = true,
  }) {
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

  test('each account calls through its own app', () {
    final twitch = fakeAccount(
      Channel(Providers.twitch, '1', 'muxfd'),
      appName: '[DEFAULT]',
    );
    final kick = fakeAccount(Channel(Providers.kick, '2', 'muxfd'));

    expect(Api.forAccount(twitch).app, same(twitch.app));
    expect(Api.forAccount(kick).app, same(kick.app));
    expect(Api.forAccount(twitch), isNot(same(Api.forAccount(kick))));
    // the same app keeps the same Api, and with it any emulator settings.
    expect(Api.forAccount(kick), same(Api.forApp(kick.app)));
  });
}
