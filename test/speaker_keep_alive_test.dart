import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:audioplayers_platform_interface/audioplayers_platform_interface.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rtchat/speaker_keep_alive.dart';

/// Stands in for audioplayers_android: a local source is opened the way
/// `MediaPlayer.setDataSource` opens it, so a missing file fails with the
/// same error Crashlytics reports.
class FakeAndroidAudioplayers extends AudioplayersPlatformInterface {
  final _events = <String, StreamController<AudioEvent>>{};
  final played = <Uint8List>[];

  /// Runs between audioplayers handing over a path and the file being
  /// opened, where Android may clear the cache directory.
  void Function(String path)? beforeOpen;

  /// When set, every source fails to load with this error.
  PlatformException? sourceError;

  void _prepared(String playerId) => _events[playerId]!.add(
    const AudioEvent(eventType: AudioEventType.prepared, isPrepared: true),
  );

  @override
  Future<void> create(String playerId) async {
    _events[playerId] = StreamController.broadcast();
  }

  @override
  Stream<AudioEvent> getEventStream(String playerId) =>
      _events[playerId]!.stream;

  @override
  Future<void> setSourceUrl(
    String playerId,
    String url, {
    bool? isLocal,
    String? mimeType,
  }) async {
    if (sourceError != null) throw sourceError!;
    beforeOpen?.call(url);
    if (isLocal == true && !File(url).existsSync()) {
      throw PlatformException(
        code: "AndroidAudioError",
        message:
            "Failed to set source. For troubleshooting, see: "
            "https://github.com/bluefireteam/audioplayers/blob/main/troubleshooting.md",
        details:
            "java.io.FileNotFoundException: $url: open failed: ENOENT "
            "(No such file or directory)",
      );
    }
    _prepared(playerId);
  }

  @override
  Future<void> setSourceBytes(
    String playerId,
    Uint8List bytes, {
    String? mimeType,
  }) async {
    if (sourceError != null) throw sourceError!;
    played.add(bytes);
    _prepared(playerId);
  }

  @override
  Future<void> dispose(String playerId) async {
    await _events.remove(playerId)?.close();
  }

  @override
  Future<void> setAudioContext(String playerId, AudioContext ctx) async {}
  @override
  Future<void> setPlayerMode(String playerId, PlayerMode mode) async {}
  @override
  Future<void> resume(String playerId) async {}
  @override
  Future<void> pause(String playerId) async {}
  @override
  Future<void> stop(String playerId) async {}
  @override
  Future<void> release(String playerId) async {}
  @override
  Future<void> seek(String playerId, Duration position) async {}
  @override
  Future<void> setBalance(String playerId, double balance) async {}
  @override
  Future<void> setVolume(String playerId, double volume) async {}
  @override
  Future<void> setReleaseMode(String playerId, ReleaseMode mode) async {}
  @override
  Future<void> setPlaybackRate(String playerId, double rate) async {}
  @override
  Future<int?> getDuration(String playerId) async => null;
  @override
  Future<int?> getCurrentPosition(String playerId) async => null;
  @override
  Future<void> emitLog(String playerId, String message) async {}
  @override
  Future<void> emitError(String playerId, String code, String message) async {}
}

/// Copies assets into a test directory instead of the app's cache.
class TempDirAudioCache extends AudioCache {
  final Directory dir;

  TempDirAudioCache(this.dir);

  @override
  Future<String> getTempDir() async => dir.path;

  @override
  Future<ByteData> loadAsset(String path) async =>
      ByteData.sublistView(Uint8List.fromList([0xff, 0xf3, 0x18, 0xc4]));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeAndroidAudioplayers platform;

  setUpAll(() {
    // a source that fails to load only reports its error once audioplayers
    // stops waiting for it to be prepared.
    AudioPlayer.preparationTimeout = const Duration(milliseconds: 100);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('xyz.luan/audioplayers.global'),
          (call) async => true,
        );
  });

  setUp(() {
    platform = FakeAndroidAudioplayers();
    AudioplayersPlatformInterface.instance = platform;
  });

  test(
    "an asset played after Android clears the cache crashes the app",
    () async {
      // the keep-alive used to play an asset: audioplayers copies it into the
      // cache directory and hands the copy's path to MediaPlayer.
      final cacheDir = Directory.systemTemp.createTempSync("cache");
      addTearDown(() => cacheDir.deleteSync(recursive: true));
      final player = AudioPlayer()..audioCache = TempDirAudioCache(cacheDir);
      addTearDown(player.dispose);

      await player.play(AssetSource("silence.mp3"));

      // Android deletes cache files whenever it needs the space, including
      // after audioplayers checked that its copy still exists.
      platform.beforeOpen = (path) => File(path).deleteSync();

      final uncaught = Completer<Object>();
      runZonedGuarded(() {
        // the old timer callback didn't await or catch the play.
        Timer(Duration.zero, () => player.play(AssetSource("silence.mp3")));
      }, (error, _) => uncaught.complete(error));

      final error = await uncaught.future;
      expect(
        error,
        isA<PlatformException>()
            .having((e) => e.code, "code", "AndroidAudioError")
            .having(
              (e) => e.details,
              "details",
              allOf(
                contains("FileNotFoundException"),
                contains("silence.mp3: open failed: ENOENT"),
              ),
            ),
      );
    },
  );

  test("the keep-alive plays without touching the file system", () async {
    platform.beforeOpen = (_) => fail("opened a file");
    final keepAlive = SpeakerKeepAlive(
      interval: const Duration(milliseconds: 1),
      onError: (error, stack) => fail("$error"),
    );
    addTearDown(keepAlive.dispose);

    while (platform.played.length < 2) {
      await Future<void>.delayed(const Duration(milliseconds: 1));
    }
    expect(platform.played.first, same(keepAliveClip));
  });

  test("a keep-alive that fails to play is reported, not thrown", () async {
    platform.sourceError = PlatformException(code: "AndroidAudioError");
    final reported = Completer<Object>();
    Object? uncaught;

    late SpeakerKeepAlive keepAlive;
    runZonedGuarded(() {
      keepAlive = SpeakerKeepAlive(
        interval: const Duration(milliseconds: 1),
        onError: (error, _) {
          if (!reported.isCompleted) reported.complete(error);
        },
      );
    }, (error, _) => uncaught = error);
    addTearDown(() => keepAlive.dispose());

    expect(await reported.future, isA<PlatformException>());
    expect(uncaught, isNull);
  });

  test("the keep-alive clip is a valid, inaudible WAV file", () {
    final wav = ByteData.sublistView(keepAliveClip);
    String ascii(int offset) =>
        String.fromCharCodes(keepAliveClip.sublist(offset, offset + 4));

    expect(ascii(0), "RIFF");
    expect(wav.getUint32(4, Endian.little), keepAliveClip.length - 8);
    expect(ascii(8), "WAVE");
    expect(ascii(12), "fmt ");
    expect(wav.getUint16(20, Endian.little), 1, reason: "PCM");
    expect(wav.getUint16(34, Endian.little), 16, reason: "bits per sample");
    expect(ascii(36), "data");
    expect(wav.getUint32(40, Endian.little), keepAliveClip.length - 44);

    final samples = [
      for (var i = 44; i < keepAliveClip.length; i += 2)
        wav.getInt16(i, Endian.little),
    ];
    expect(samples.every((s) => s.abs() <= 1), isTrue);
    expect(samples.toSet(), containsAll([-1, 0, 1]), reason: "dithered");
  });
}
