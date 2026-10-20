import 'package:cloud_functions/cloud_functions.dart';

/// Keeps callable requests (including Firebase auth and error handling) on our, own hostname so the backend can move without another app release.
class Api {
  Api(this._functions);

  static const String _apiBaseUrl = 'https://rtchat-api.rtirl.com';
  static Api? _instance;
  static Api get instance => _instance ??= Api(FirebaseFunctions.instance);

  final FirebaseFunctions _functions;
  bool _useEmulator = false;

  HttpsCallable callable(String name) {
    if (_useEmulator) {
      return _functions.httpsCallable(name);
    }
    return _functions.httpsCallableFromUrl('$_apiBaseUrl/$name');
  }

  /// Use named calls for the emulator, which expects /project/region/function, rather than the public API path. This also keeps integration tests local.
  void useEmulator(String host, int port) {
    _functions.useFunctionsEmulator(host, port);
    _useEmulator = true;
  }
}
