import 'dart:convert';
import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rtchat/api.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/messages/twitch/emote.dart';

class _Result<T> extends Fake implements HttpsCallableResult<T> {
  @override
  final T data;

  _Result(this.data);
}

class _Callable extends Fake implements HttpsCallable {
  final _Functions functions;

  _Callable(this.functions);

  @override
  Future<HttpsCallableResult<T>> call<T>([dynamic parameters]) async {
    functions.calls++;
    final error = functions.error;
    if (error != null) throw error;
    return _Result<T>(functions.emotes as T);
  }
}

class _Functions extends Fake implements FirebaseFunctions {
  var calls = 0;
  Object? error;
  List<Map<String, dynamic>> emotes = [];

  @override
  HttpsCallable httpsCallableFromUrl(
    String url, {
    HttpsCallableOptions? options,
  }) => _Callable(this);
}

Map<String, dynamic> _emote(String code) => {
  'provider': 'twitch',
  'category': null,
  'id': code,
  'code': code,
  'imageUrl': 'https://example.com/$code.png',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final channel = Channel('twitch', '123', 'streamer');
  late Directory temp;
  late File cacheFile;
  late _Functions functions;
  late List<Object> reported;
  late Map<Api, String> callers;
  final defaultRetryDelay = emoteRetryDelay;
  final defaultReportError = reportEmoteError;
  final defaultCaller = emoteCaller;

  setUp(() {
    temp = Directory.systemTemp.createTempSync('emotes-');
    cacheFile = File('${temp.path}/emotes/user/twitch:123.json');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => temp.path,
        );
    functions = _Functions();
    reported = [];
    emoteRetryDelay = Duration.zero;
    reportEmoteError = (error, stack) => reported.add(error);
    callers = {};
    emoteCaller = (api) => callers[api] ?? 'user';
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          null,
        );
    temp.deleteSync(recursive: true);
    emoteRetryDelay = defaultRetryDelay;
    reportEmoteError = defaultReportError;
    emoteCaller = defaultCaller;
  });

  Future<List<Emote>> getEmotesForTest() => getEmotes(channel, Api(functions));

  test('fetches and caches the emotes', () async {
    functions.emotes = [_emote('Kappa')];

    final emotes = await getEmotesForTest();

    expect(emotes.map((emote) => emote.code), ['Kappa']);
    expect(jsonDecode(cacheFile.readAsStringSync()), [_emote('Kappa')]);
    expect(await getEmotesForTest(), hasLength(1));
    expect(functions.calls, 1);
  });

  test('shares one fetch between concurrent requests', () async {
    functions.emotes = [_emote('Kappa')];

    final results = await Future.wait([getEmotesForTest(), getEmotesForTest()]);

    expect(results.map((emotes) => emotes.length), [1, 1]);
    expect(jsonDecode(cacheFile.readAsStringSync()), [_emote('Kappa')]);
    expect(functions.calls, 1);
  });

  test("doesn't share a fetch or cache between users", () async {
    functions.emotes = [_emote('Kappa')];
    final otherFunctions =
        _Functions()..emotes = [_emote('Kappa'), _emote('Pog')];
    final otherApi = Api(otherFunctions);
    callers[otherApi] = 'other';

    final results = await Future.wait([
      getEmotesForTest(),
      getEmotes(channel, otherApi),
    ]);

    expect(results.map((emotes) => emotes.length), [1, 2]);
    expect(functions.calls, 1);
    expect(otherFunctions.calls, 1);
    expect(jsonDecode(cacheFile.readAsStringSync()), [_emote('Kappa')]);
    expect(
      jsonDecode(
        File('${temp.path}/emotes/other/twitch:123.json').readAsStringSync(),
      ),
      [_emote('Kappa'), _emote('Pog')],
    );
  });

  test("drops a fetch when the user changes during a retry", () async {
    functions.error = FirebaseFunctionsException(
      code: 'unavailable',
      message: 'UNAVAILABLE',
    );
    // the user switches accounts after the first attempt fails.
    emoteCaller = (api) => functions.calls == 0 ? 'user' : 'other';

    expect(await getEmotesForTest(), isEmpty);
    expect(functions.calls, 1);
    expect(reported, isEmpty);
  });

  test("doesn't cache emotes fetched after the user changes", () async {
    functions.emotes = [_emote('Kappa')];
    emoteCaller = (api) => functions.calls == 0 ? 'user' : 'other';

    expect(await getEmotesForTest(), isEmpty);
    expect(functions.calls, 1);
    expect(Directory('${temp.path}/emotes').existsSync(), isFalse);
  });

  test('fetches the emotes again when the cache is cut short', () async {
    cacheFile.createSync(recursive: true);
    // e.g. the disk filled up while it was written.
    cacheFile.writeAsStringSync('');
    functions.emotes = [_emote('Kappa')];

    final emotes = await getEmotesForTest();

    expect(emotes.map((emote) => emote.code), ['Kappa']);
    expect(jsonDecode(cacheFile.readAsStringSync()), [_emote('Kappa')]);
    expect(reported, isEmpty);
  });

  test('drops a corrupt cache when the backend is unavailable', () async {
    cacheFile.createSync(recursive: true);
    cacheFile.writeAsStringSync('[{"provider"');
    functions.error = FirebaseFunctionsException(
      code: 'unavailable',
      message: 'UNAVAILABLE',
    );

    expect(await getEmotesForTest(), isEmpty);
    expect(cacheFile.existsSync(), isFalse);
    expect(functions.calls, 3);
    expect(reported, hasLength(1));
  });

  test('uses an outdated cache when the backend is unavailable', () async {
    cacheFile.createSync(recursive: true);
    cacheFile.writeAsStringSync(jsonEncode([_emote('Kappa')]));
    cacheFile.setLastModifiedSync(
      DateTime.now().subtract(const Duration(days: 2)),
    );
    functions.error = FirebaseFunctionsException(
      code: 'unavailable',
      message: 'UNAVAILABLE',
    );

    final emotes = await getEmotesForTest();

    expect(emotes.map((emote) => emote.code), ['Kappa']);
    expect(functions.calls, 3);
  });

  test("returns the fetched emotes when they can't be cached", () async {
    // a directory where the cache file goes makes writing it fail.
    Directory(cacheFile.path).createSync(recursive: true);
    functions.emotes = [_emote('Kappa')];

    final emotes = await getEmotesForTest();

    expect(emotes.map((emote) => emote.code), ['Kappa']);
    expect(functions.calls, 1);
  });
}
