import 'dart:async';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:on_device_tts/on_device_tts.dart';
import 'package:rtchat/l10n/app_localizations.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/messages/message.dart';
import 'package:rtchat/models/tts.dart';
import 'package:rtchat/models/tts/language.dart';
import 'package:rtchat/models/tts/telemetry.dart';
import 'package:rtchat/models/tts/telemetry_engine.dart';

import '../fakes/fake_chat.dart';
import '../fakes/fake_telemetry.dart';
import '../fakes/fake_tts_engine.dart';

const _info = NeuralEngineInfo(
    packId: 'supertonic-3',
    modelType: 'supertonic',
    provider: 'cpu',
    threads: 2);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => initializeDateFormatting('en'));
  final l10n = lookupAppLocalizations(const Locale('en'));

  late FakeTelemetrySink sink;
  late SessionTtsTelemetry telemetry;

  setUp(() {
    sink = FakeTelemetrySink();
    telemetry = SessionTtsTelemetry(sink, summaryInterval: null);
  });

  group('percentile', () {
    test('is the nearest rank', () {
      final values = [for (var i = 1; i <= 10; i++) i * 100];
      expect(percentile(values, 50), 500);
      expect(percentile(values, 90), 900);
      expect(percentile(values, 100), 1000);
      expect(percentile(values, 0), 100);
      expect(percentile([42], 90), 42);
      expect(percentile([], 50), isNull);
    });
  });

  group('summary', () {
    test('aggregates a window and starts a new one', () {
      for (var i = 1; i <= 10; i++) {
        telemetry.firstAudio(Duration(milliseconds: i * 100));
        telemetry.utteranceRead(TtsEngineKind.neural);
      }
      telemetry.utteranceRead(TtsEngineKind.system,
          reason: TtsSystemVoiceReason.unsupportedLanguage);
      telemetry.utteranceRead(TtsEngineKind.system,
          reason: TtsSystemVoiceReason.neuralError);
      telemetry.utteranceRead(TtsEngineKind.system,
          reason: TtsSystemVoiceReason.lowMemory);
      telemetry.utteranceRead(TtsEngineKind.system,
          reason: TtsSystemVoiceReason.loadFailed);
      telemetry.utteranceRead(TtsEngineKind.system);
      telemetry.modelLoaded(const Duration(milliseconds: 900),
          isReload: false, succeeded: true);
      telemetry.modelLoaded(const Duration(milliseconds: 700),
          isReload: true, succeeded: true);
      telemetry.modelLoaded(const Duration(milliseconds: 50),
          isReload: true, succeeded: false);

      telemetry.flush();
      final summary = sink.eventsNamed('tts_summary').single;
      expect(summary, {
        'utterances': 15,
        'neural': 10,
        'system': 5,
        'neural_pct': 67,
        'system_no_pack': 1,
        'fallback_unsupported_language': 1,
        'fallback_neural_error': 1,
        'fallback_low_memory': 1,
        'fallback_load_failed': 1,
        'first_audio_count': 10,
        'first_audio_p50_ms': 500,
        'first_audio_p90_ms': 900,
        'model_loads': 2,
        'model_reloads': 1,
        'model_load_failures': 1,
        'model_load_p50_ms': 700,
        'model_load_max_ms': 900,
        'errors': 0,
        'errors_not_reported': 0,
      });
      expect(sink.logs.last, startsWith('tts summary: utterances=15'));
      // GA4 limits.
      expect(summary.length, lessThanOrEqualTo(25));
      for (final key in summary.keys) {
        expect(key.length, lessThanOrEqualTo(40), reason: key);
      }

      // the window starts over.
      telemetry.flush();
      expect(sink.eventsNamed('tts_summary'), hasLength(1));
      telemetry.utteranceRead(TtsEngineKind.neural);
      telemetry.flush();
      final next = sink.eventsNamed('tts_summary').last;
      expect(next['utterances'], 1);
      expect(next['neural_pct'], 100);
      expect(next.containsKey('first_audio_p50_ms'), isFalse);
    });

    test('samples latencies in bounded memory', () {
      telemetry = SessionTtsTelemetry(sink,
          summaryInterval: null, maxLatencySamples: 50, random: Random(1));
      for (var i = 1; i <= 1000; i++) {
        telemetry.firstAudio(Duration(milliseconds: i));
      }
      telemetry.flush();
      final summary = sink.eventsNamed('tts_summary').single;
      expect(summary['first_audio_count'], 1000);
      // a uniform sample of 1..1000: the median is about 500.
      expect(summary['first_audio_p50_ms'] as int, inInclusiveRange(350, 650));
      expect(summary['first_audio_p90_ms'] as int, inInclusiveRange(750, 1000));
    });

    test('is sent periodically while there is something to send', () async {
      telemetry = SessionTtsTelemetry(sink,
          summaryInterval: const Duration(milliseconds: 10));
      addTearDown(telemetry.dispose);
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(sink.events, isEmpty, reason: 'no timer before any data');
      telemetry.utteranceRead(TtsEngineKind.neural);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(sink.eventsNamed('tts_summary'), hasLength(1));
    });

    test('nothing to send, nothing sent', () {
      telemetry.flush();
      telemetry.dispose();
      expect(sink.events, isEmpty);
    });
  });

  group('crashlytics keys', () {
    test('are set when they change', () {
      telemetry.neuralEngineInUse(_info);
      telemetry.neuralEngineInUse(_info);
      telemetry.utteranceRead(TtsEngineKind.neural);
      telemetry.utteranceRead(TtsEngineKind.neural);
      telemetry.deviceMemory(const DeviceMemory(totalBytes: 4 << 30));
      telemetry.neuralFallbackChanged(NeuralTtsFallback.loadFailed);
      expect(sink.keys, {
        'tts_pack_id': 'supertonic-3',
        'tts_model_type': 'supertonic',
        'tts_provider': 'cpu',
        'tts_threads': 2,
        'tts_engine': 'neural',
        'device_total_mem_mb': 4096,
        'tts_neural_fallback': 'loadFailed',
      });
      expect(sink.keyWrites, hasLength(7), reason: 'no repeated writes');
      telemetry.utteranceRead(TtsEngineKind.system,
          reason: TtsSystemVoiceReason.loadFailed);
      expect(sink.keys['tts_engine'], 'system');
      telemetry.neuralFallbackChanged(null);
      expect(sink.keys['tts_neural_fallback'], 'none');
    });

    test('a fallback is an event once per reason', () {
      telemetry.neuralFallbackChanged(NeuralTtsFallback.loadFailed);
      telemetry.neuralFallbackChanged(null);
      telemetry.neuralFallbackChanged(NeuralTtsFallback.loadFailed);
      telemetry.neuralFallbackChanged(NeuralTtsFallback.lowMemoryDevice);
      expect(sink.eventsNamed('tts_neural_fallback'), [
        {'reason': 'loadFailed'},
        {'reason': 'lowMemoryDevice'},
      ]);
    });
  });

  group('errors', () {
    test('are rate-limited per type', () {
      for (var i = 0; i < 10; i++) {
        telemetry.recordError(
            PlatformException(code: 'speak_failed'), StackTrace.current);
      }
      for (var i = 0; i < 2; i++) {
        telemetry.recordError(
            PlatformException(code: 'busy'), StackTrace.current);
      }
      telemetry.recordError(StateError('x'), StackTrace.current);
      expect(sink.nonFatals.map((e) => '$e'), [
        'PlatformException(speak_failed)',
        'PlatformException(speak_failed)',
        'PlatformException(speak_failed)',
        'PlatformException(busy)',
        'PlatformException(busy)',
        'StateError',
      ]);
      telemetry.flush();
      final summary = sink.eventsNamed('tts_summary').single;
      expect(summary['errors'], 13);
      expect(summary['errors_not_reported'], 7);
    });

    test('keep only what a model load says', () {
      telemetry.recordError(
          const NeuralTtsLoadException(
              "Couldn't load supertonic-3: out of memory", 'OOM'),
          StackTrace.current);
      expect('${sink.nonFatals.single}',
          "NeuralTtsLoadException: Couldn't load supertonic-3: out of memory");
    });
  });

  group('install funnel', () {
    test('sends an event per stage', () {
      telemetry.packInstall(PackInstallStage.started,
          packId: 'supertonic-3', sizeBytes: 401000000, overMobileData: false);
      telemetry.packInstall(PackInstallStage.failed,
          packId: 'supertonic-3',
          sizeBytes: 401000000,
          duration: const Duration(seconds: 75),
          error: 'no_space',
          overMobileData: true);
      telemetry.packInstall(PackInstallStage.deleted,
          packId: 'supertonic-3', sizeBytes: 402000000);
      expect(sink.events.map((e) => e.$1), [
        'tts_pack_install_started',
        'tts_pack_install_failed',
        'tts_pack_deleted',
      ]);
      expect(sink.events.map((e) => e.$2), [
        {'pack_id': 'supertonic-3', 'size_mb': 401, 'mobile_data': 0},
        {
          'pack_id': 'supertonic-3',
          'size_mb': 401,
          'duration_s': 75,
          'error': 'no_space',
          'mobile_data': 1,
        },
        {'pack_id': 'supertonic-3', 'size_mb': 402},
      ]);
    });

    test('names install errors by kind', () {
      expect(
          installErrorType(const VoicePackInsufficientSpaceException('', 2, 1)),
          'no_space');
      expect(
          installErrorType(const VoicePackDownloadException('')), 'download');
      expect(
          installErrorType(
              const VoicePackDownloadException('', statusCode: 404)),
          'download_http_404');
      expect(
          installErrorType(const VoicePackChecksumException('')), 'checksum');
      expect(installErrorType(const VoicePackArchiveException('')), 'archive');
      expect(installErrorType(const VoicePackUnsupportedException('')),
          'unsupported');
      expect(installErrorType(Exception('?')), 'other');
    });
  });

  group('with TtsModel', () {
    const secretText = 'my secret message';
    const secretLogin = 'secretlogin';
    const secretName = 'SecretDisplayName';
    const secretChannel = 'SecretChannelName';
    late FakeTtsEngine system;
    late FakeTtsEngine neural;
    late TtsModel model;

    MessageModel chat(int i, {String channelId = 'secret-channel-id'}) =>
        FakeChatMessage(
          messageId: 'm$i',
          timestamp: DateTime(2026),
          author: FakeChatUser(
              userId: 'secret-user-id',
              login: secretLogin,
              displayName: secretName),
          message: '$secretText $i',
        )..channel = Channel('twitch', channelId, secretChannel);

    setUp(() {
      system = FakeTtsEngine();
      neural = FakeTtsEngine(availableVoices: packVoices(['en']));
      model = TtsModel.fromJson({'language': 'en'},
          engine: system,
          reportError: telemetry.recordError,
          telemetry: telemetry,
          neuralIdleTimeout: const Duration(hours: 1));
    });

    tearDown(() => model.dispose());

    Future<void> say(MessageModel message) async {
      model.say(l10n, message);
      await pumpEventQueue();
    }

    test('counts the engine and why the system voice read', () async {
      final fake = FakeTtsTelemetry();
      model.dispose();
      model = TtsModel.fromJson({'language': 'en'},
          engine: system,
          reportError: (_, __) {},
          telemetry: fake,
          neuralIdleTimeout: const Duration(hours: 1));
      model.setMode(l10n, TtsMode.enabled);
      await pumpEventQueue();
      expect(fake.utterances.last,
          (TtsEngineKind.system, TtsSystemVoiceReason.noVoicePack));

      model.neuralEngine = neural;
      await say(chat(1));
      expect(fake.utterances.last, (TtsEngineKind.neural, null));

      final thai = chat(2, channelId: 'thai-channel-id');
      model.setChannelLanguage(thai.channel!, Language('th'));
      await say(thai);
      expect(fake.utterances.last,
          (TtsEngineKind.system, TtsSystemVoiceReason.unsupportedLanguage));

      neural.failNext = PlatformException(code: 'speak_failed');
      await say(chat(3));
      expect(fake.utterances.last,
          (TtsEngineKind.system, TtsSystemVoiceReason.neuralError));

      neural.failNext = const NeuralTtsLoadException('oom', 'OOM');
      await say(chat(4));
      expect(fake.utterances.last,
          (TtsEngineKind.system, TtsSystemVoiceReason.loadFailed));
      expect(fake.fallbacks, [NeuralTtsFallback.loadFailed]);
      await say(chat(5));
      expect(fake.utterances.last,
          (TtsEngineKind.system, TtsSystemVoiceReason.loadFailed));

      // a new pack gets another chance.
      model.neuralEngine = FakeTtsEngine(availableVoices: packVoices(['en']));
      expect(fake.fallbacks, [NeuralTtsFallback.loadFailed, null]);
      model.fallBackToSystemVoices(NeuralTtsFallback.lowMemoryDevice);
      await say(chat(6));
      expect(fake.utterances.last,
          (TtsEngineKind.system, TtsSystemVoiceReason.lowMemory));
    });

    test('sends no message text, usernames or channel names', () async {
      model.neuralEngine = neural;
      model.setMode(l10n, TtsMode.enabled);
      await pumpEventQueue();
      await say(chat(1));
      neural.failNext = PlatformException(
          code: 'speak_failed',
          message: 'could not say $secretText from $secretLogin',
          details: secretChannel);
      await say(chat(2));
      system.failNext = Exception('$secretName in $secretChannel');
      await say(chat(3));
      neural.failNext = NeuralTtsLoadException(
          "Couldn't load supertonic-3", Exception(secretText));
      await say(chat(4));
      telemetry.flush();

      expect(sink.nonFatals, hasLength(3));
      expect(sink.eventsNamed('tts_summary'), hasLength(1));
      final everything = sink.everything;
      for (final secret in [
        secretText,
        secretLogin,
        secretName,
        secretChannel,
        'secret-user-id',
        'secret-channel-id',
      ]) {
        expect(everything, isNot(contains(secret)), reason: secret);
      }
    });
  });

  group('TelemetryTtsEngine', () {
    late FakeTtsEngine inner;
    late FakeTtsTelemetry fake;
    late StreamController<OnnxTtsEvent> events;
    late bool isLoaded;
    late Completer<void>? loading;
    late Object? loadError;
    late TelemetryTtsEngine engine;

    setUp(() {
      inner = FakeTtsEngine();
      fake = FakeTtsTelemetry();
      events = StreamController.broadcast();
      isLoaded = false;
      loading = null;
      loadError = null;
      engine = TelemetryTtsEngine(
        engine: inner,
        telemetry: fake,
        info: _info,
        events: events.stream,
        isLoaded: () => isLoaded,
        load: () async {
          await loading?.future;
          final error = loadError;
          if (error != null) throw error;
          isLoaded = true;
        },
      );
    });

    tearDown(() async {
      await engine.dispose();
      await events.close();
    });

    test('times loads and reloads, and reports first audio', () async {
      await engine.speak('hello');
      expect(fake.loads.single.isReload, isFalse);
      expect(fake.loads.single.succeeded, isTrue);
      expect(fake.engines, [_info]);
      expect(inner.spoken, ['hello']);

      events.add(const OnnxTtsEvent(
          utteranceId: 'neural-0-0',
          type: OnnxTtsEventType.firstAudio,
          elapsed: Duration(milliseconds: 640)));
      events.add(const OnnxTtsEvent(
          utteranceId: 'neural-0-0',
          type: OnnxTtsEventType.done,
          elapsed: Duration(milliseconds: 2400)));
      await pumpEventQueue();
      expect(fake.latencies, [const Duration(milliseconds: 640)]);

      await engine.speak('again');
      expect(fake.loads, hasLength(1), reason: 'still loaded');

      await engine.release();
      isLoaded = false;
      await engine.speak('after release');
      expect(fake.loads, hasLength(2));
      expect(fake.loads.last.isReload, isTrue);
    });

    test('reports a failed load and rethrows it', () async {
      loadError = const NeuralTtsLoadException('oom', 'OOM');
      await expectLater(
          engine.speak('hello'), throwsA(isA<NeuralTtsLoadException>()));
      expect(fake.loads.single.succeeded, isFalse);
      expect(inner.spoken, isEmpty);
    });

    test("doesn't speak if stopped while loading", () async {
      loading = Completer();
      final speaking = engine.speak('hello');
      await pumpEventQueue();
      await engine.stop();
      loading!.complete();
      await speaking;
      expect(inner.spoken, isEmpty);
      expect(inner.stopCount, 1);
    });
  });
}
