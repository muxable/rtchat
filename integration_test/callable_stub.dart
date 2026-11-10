import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// A callable request that reached [CallableStub].
class CallableCall {
  /// The callable's name, the last segment of the request path.
  final String name;

  /// The uid in the request's Auth emulator ID token, or null without one.
  final String? uid;

  /// The request's `data`.
  final dynamic data;

  const CallableCall(this.name, this.uid, this.data);

  @override
  String toString() => 'CallableCall($name, $uid, $data)';
}

/// Stands in for the Functions emulator, which CI doesn't run. It speaks the
/// callable protocol (`{"data": ...}` in, `{"result": ...}` out) and records
/// each call with the uid it was made as, read from the Auth emulator's
/// unsigned ID token, so tests can check which account a call was made as.
///
/// It runs in the test's own process, which on Android is the app on the
/// device, so callables must be pointed at the device's loopback.
class CallableStub {
  final HttpServer _server;
  final _calls = <CallableCall>[];
  final _failures = <(String, String?)>{};
  final _results = <(String, String?), dynamic>{};

  /// The callables answered with a null result. Others fail with UNAVAILABLE,
  /// as they did before there was a stub, which the app already tolerates.
  final Set<String> handled;

  CallableStub._(this._server, this.handled) {
    _server.listen(_handle);
  }

  static Future<CallableStub> start(
    String host,
    int port, {
    Set<String> handled = const {
      'send',
      'ban',
      'unban',
      'timeout',
      'deleteMessage',
      'raid',
      'cancelRaid',
    },
  }) async {
    return CallableStub._(await HttpServer.bind(host, port), handled);
  }

  /// The calls so far, in the order they arrived.
  List<CallableCall> get calls => List.unmodifiable(_calls);

  /// The calls so far to the callable [name].
  List<CallableCall> callsTo(String name) =>
      _calls.where((call) => call.name == name).toList();

  /// Makes calls to [name] fail with INTERNAL, only those made as [uid] if
  /// it's given, until [reset].
  void fail(String name, {String? uid}) => _failures.add((name, uid));

  /// Makes calls to [name] answer with [result] instead of null, only those
  /// made as [uid] if it's given, until [reset].
  void respond(String name, dynamic result, {String? uid}) =>
      _results[(name, uid)] = result;

  /// Forgets the calls, failures and results so far.
  void reset() {
    _calls.clear();
    _failures.clear();
    _results.clear();
  }

  Future<void> close() => _server.close(force: true);

  Future<void> _handle(HttpRequest request) async {
    final response = request.response;
    try {
      final name = request.uri.pathSegments.lastOrNull ?? '';
      final body = await utf8.decoder.bind(request).join();
      final data = body.isEmpty ? null : (jsonDecode(body) as Map)['data'];
      final uid = uidOf(request.headers.value(HttpHeaders.authorizationHeader));
      _calls.add(CallableCall(name, uid, data));

      response.headers.contentType = ContentType.json;
      if (_failures.contains((name, uid)) || _failures.contains((name, null))) {
        response.statusCode = HttpStatus.internalServerError;
        response.write(
          jsonEncode({
            'error': {'status': 'INTERNAL', 'message': 'stub failure'},
          }),
        );
      } else if (!handled.contains(name)) {
        response.statusCode = HttpStatus.serviceUnavailable;
        response.write(
          jsonEncode({
            'error': {'status': 'UNAVAILABLE', 'message': 'not stubbed'},
          }),
        );
      } else {
        response.write(
          jsonEncode({
            'result': _results[(name, uid)] ?? _results[(name, null)],
          }),
        );
      }
    } catch (e) {
      response.statusCode = HttpStatus.badRequest;
      response.write(
        jsonEncode({
          'error': {'status': 'INVALID_ARGUMENT', 'message': '$e'},
        }),
      );
    }
    await response.close();
  }

  /// The uid in an `Authorization: Bearer` header carrying an Auth emulator
  /// ID token, which is an unsigned JWT.
  static String? uidOf(String? authorization) {
    const prefix = 'Bearer ';
    if (authorization == null || !authorization.startsWith(prefix)) {
      return null;
    }
    final parts = authorization.substring(prefix.length).split('.');
    if (parts.length < 2) {
      return null;
    }
    final claims =
        jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))))
            as Map<String, dynamic>;
    return (claims['user_id'] ?? claims['sub']) as String?;
  }
}
