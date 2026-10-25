import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rtchat/components/image/resilient_network_image.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory temp;
  late _FakeHttpClient client;
  late Uint8List small;
  late Uint8List large;

  setUpAll(() async {
    // The cache directory is memoized, so every test shares this one and uses
    // its own URL.
    temp = Directory.systemTemp.createTempSync('images-');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => temp.path,
        );
    small = await _png(1);
    large = await _png(2);
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          null,
        );
    temp.deleteSync(recursive: true);
  });

  setUp(() {
    client = _FakeHttpClient();
    debugNetworkImageHttpClientProvider = () => client;
  });

  tearDown(() {
    debugNetworkImageHttpClientProvider = null;
  });

  Future<(File, File)> seed(
    Uri uri,
    Uint8List bytes, {
    Map<String, String>? meta,
    Duration age = Duration.zero,
  }) async {
    final cacheFile = await ResilientNetworkImage.cacheFileFor(uri);
    final metaFile = File('${cacheFile.path}.meta');
    await cacheFile.writeAsBytes(bytes);
    if (meta != null) {
      await metaFile.writeAsString(jsonEncode(meta));
    }
    await cacheFile.setLastModified(DateTime.now().subtract(age));
    return (cacheFile, metaFile);
  }

  test('fnv1a64 matches the reference vectors', () {
    expect(fnv1a64(''), 'cbf29ce484222325');
    expect(fnv1a64('a'), 'af63dc4c8601ec8c');
    expect(fnv1a64('foobar'), '85944171f73967e8');
  });

  test('a fresh cache hit makes no network request', () async {
    final uri = Uri.parse('https://example.com/fresh.png');
    await seed(uri, small, meta: {'etag': '"v1"'});

    expect(await _loadWidth(ResilientNetworkImage(uri)), 1);
    await ResilientNetworkImage.debugRevalidations();

    expect(client.requests, isEmpty);
  });

  test('a stale hit is served immediately and revalidated', () async {
    final uri = Uri.parse('https://example.com/stale.png');
    final (cacheFile, metaFile) = await seed(
      uri,
      small,
      meta: {'etag': '"v1"', 'lastModified': 'Mon, 01 Jan 2024 00:00:00 GMT'},
      age: const Duration(days: 2),
    );
    final requested = Completer<void>();
    final gate = Completer<void>();
    addTearDown(() => gate.isCompleted ? null : gate.complete());
    client.handler = (request) async {
      requested.complete();
      await gate.future;
      return _FakeResponse(200, large, {'etag': '"v2"'});
    };

    // The cached image loads while the revalidation is still blocked.
    expect(await _loadWidth(ResilientNetworkImage(uri)), 1);
    await requested.future;
    expect(client.requests, hasLength(1));
    expect(client.requests.single.headers['if-none-match'], ['"v1"']);
    expect(client.requests.single.headers['if-modified-since'], [
      'Mon, 01 Jan 2024 00:00:00 GMT',
    ]);

    gate.complete();
    await ResilientNetworkImage.debugRevalidations();

    expect(await cacheFile.readAsBytes(), large);
    expect(jsonDecode(await metaFile.readAsString()), {'etag': '"v2"'});
    expect(await _loadWidth(ResilientNetworkImage(uri)), 2);
    expect(client.requests, hasLength(1));
  });

  test('a stale hit touches the cache file on 304', () async {
    final uri = Uri.parse('https://example.com/not-modified.png');
    final (cacheFile, _) = await seed(
      uri,
      small,
      meta: {'etag': '"v1"'},
      age: const Duration(days: 2),
    );
    client.handler = (request) async => _FakeResponse(304, Uint8List(0));

    expect(await _loadWidth(ResilientNetworkImage(uri)), 1);
    await ResilientNetworkImage.debugRevalidations();

    expect(await cacheFile.readAsBytes(), small);
    expect(
      DateTime.now().difference(await cacheFile.lastModified()),
      lessThan(const Duration(hours: 1)),
    );
  });

  test('a stale hit survives a failed revalidation', () async {
    final uri = Uri.parse('https://example.com/offline.png');
    final (cacheFile, _) = await seed(uri, small, age: const Duration(days: 2));
    client.handler = (request) async => throw const SocketException('offline');

    expect(await _loadWidth(ResilientNetworkImage(uri)), 1);
    await ResilientNetworkImage.debugRevalidations();

    expect(client.requests, hasLength(1));
    expect(await cacheFile.readAsBytes(), small);
  });

  test('a response without an ETag is still cached', () async {
    final uri = Uri.parse('https://example.com/no-etag.png');
    client.handler = (request) async => _FakeResponse(200, small);

    expect(await _loadWidth(ResilientNetworkImage(uri)), 1);

    final cacheFile = await ResilientNetworkImage.cacheFileFor(uri);
    expect(await cacheFile.readAsBytes(), small);
    expect(jsonDecode(await File('${cacheFile.path}.meta').readAsString()), {});

    // The next load is served from disk.
    expect(await _loadWidth(ResilientNetworkImage(uri)), 1);
    expect(client.requests, hasLength(1));
  });

  test('a cold miss fetches and writes the cache', () async {
    final uri = Uri.parse('https://example.com/cold.png');
    client.handler =
        (request) async => _FakeResponse(200, large, {
          'etag': '"v1"',
          'last-modified': 'Mon, 01 Jan 2024 00:00:00 GMT',
        });

    expect(await _loadWidth(ResilientNetworkImage(uri)), 2);

    expect(client.requests, hasLength(1));
    expect(client.requests.single.headers.values, isEmpty);
    final cacheFile = await ResilientNetworkImage.cacheFileFor(uri);
    expect(await cacheFile.readAsBytes(), large);
    expect(jsonDecode(await File('${cacheFile.path}.meta').readAsString()), {
      'etag': '"v1"',
      'lastModified': 'Mon, 01 Jan 2024 00:00:00 GMT',
    });
    expect(temp.listSync().where((f) => f.path.endsWith('.tmp')), isEmpty);
  });
}

Future<Uint8List> _png(int size) async {
  final recorder = ui.PictureRecorder();
  Canvas(recorder).drawRect(
    Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
    Paint()..color = const Color(0xFFFF0000),
  );
  final image = await recorder.endRecording().toImage(size, size);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return data!.buffer.asUint8List();
}

Future<int> _loadWidth(ResilientNetworkImage provider) async {
  final stream = provider.loadImage(
    provider,
    (buffer, {getTargetSize}) =>
        PaintingBinding.instance.instantiateImageCodecWithSize(buffer),
  );
  final completer = Completer<ImageInfo>();
  final listener = ImageStreamListener(
    (info, _) => completer.complete(info),
    onError: completer.completeError,
  );
  stream.addListener(listener);
  try {
    final info = await completer.future;
    final width = info.image.width;
    info.dispose();
    return width;
  } finally {
    stream.removeListener(listener);
  }
}

class _FakeHttpClient implements HttpClient {
  final requests = <_FakeRequest>[];
  Future<_FakeResponse> Function(_FakeRequest request) handler =
      (request) => throw StateError('unexpected request to ${request.uri}');

  @override
  bool autoUncompress = false;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    final request = _FakeRequest(url, this);
    requests.add(request);
    return request;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeHeaders implements HttpHeaders {
  final Map<String, List<String>> values = {};

  _FakeHeaders([Map<String, String> initial = const {}]) {
    initial.forEach(add);
  }

  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {
    values.putIfAbsent(name.toLowerCase(), () => []).add('$value');
  }

  @override
  List<String>? operator [](String name) => values[name.toLowerCase()];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeRequest implements HttpClientRequest {
  @override
  final Uri uri;
  final _FakeHttpClient client;

  @override
  final _FakeHeaders headers = _FakeHeaders();

  _FakeRequest(this.uri, this.client);

  @override
  Future<HttpClientResponse> close() => client.handler(this);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeResponse extends Stream<List<int>> implements HttpClientResponse {
  @override
  final int statusCode;
  final Uint8List bytes;

  @override
  final _FakeHeaders headers;

  _FakeResponse(
    this.statusCode,
    this.bytes, [
    Map<String, String> headers = const {},
  ]) : headers = _FakeHeaders(headers);

  @override
  int get contentLength => bytes.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => Stream<List<int>>.value(bytes).listen(
    onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
