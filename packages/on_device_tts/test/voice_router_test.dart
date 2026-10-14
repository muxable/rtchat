import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:on_device_tts/on_device_tts.dart';

/// An engine that only lists voices.
class VoicesEngine implements TtsEngine {
  final List<TtsVoice> list;
  var calls = 0;
  Object? error;

  VoicesEngine(this.list);

  /// Each of [speakers] in each of [languages], like a multilingual pack.
  factory VoicesEngine.pack(List<String> languages, List<String> speakers) =>
      VoicesEngine([
        for (final speaker in speakers)
          for (final language in languages)
            TtsVoice(id: speaker, name: speaker, locale: language),
      ]);

  @override
  Future<List<TtsVoice>> voices({String? language}) async {
    calls++;
    final e = error;
    if (e != null) throw e;
    return list;
  }

  @override
  Future<void> speak(String text,
      {TtsVoice? voice,
      double rate = TtsEngine.normalRate,
      double pitch = TtsEngine.normalPitch,
      String? language}) async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {}
}

void main() {
  const speakers = ['F1', 'F2', 'M1'];
  late VoicesEngine supertonic;

  setUp(() {
    supertonic = VoicesEngine.pack(['en', 'es', 'ja', 'pt'], speakers);
  });

  test('routes a language the engine speaks to it', () async {
    final route = await VoiceRouter([supertonic]).route('ja');
    expect(route!.engine, same(supertonic));
    expect(route.language, 'ja');
    expect(route.voices.map((v) => v.id), speakers);
    expect(route.voices.map((v) => v.locale), everyElement('ja'));
  });

  test('routes a regional tag to the bare language', () async {
    final route = await VoiceRouter([supertonic]).route('pt-BR');
    expect(route!.language, 'pt');
    expect((await VoiceRouter([supertonic]).route('EN_us'))!.language, 'en');
  });

  test('returns null for a language no engine speaks', () async {
    expect(await VoiceRouter([supertonic]).route('zh-Hant'), isNull);
    expect(await VoiceRouter([supertonic]).route('th'), isNull);
    expect(await VoiceRouter.empty.route('en'), isNull);
  });

  test('prefers earlier engines, and falls through to later ones', () async {
    final english = VoicesEngine.pack(['en-US', 'en-GB'], ['af', 'bm']);
    final router = VoiceRouter([english, supertonic]);

    final en = await router.route('en');
    expect(en!.engine, same(english));
    expect(en.language, 'en-US');
    expect(en.voices.map((v) => v.id), ['af', 'bm']);

    final gb = await router.route('en-GB');
    expect(gb!.engine, same(english));
    expect(gb.language, 'en-GB');

    final es = await router.route('es');
    expect(es!.engine, same(supertonic));
  });

  test('picks the best tag within an engine', () async {
    final engine = VoicesEngine([
      const TtsVoice(id: 'pt-pt', name: 'pt-pt', locale: 'pt-PT'),
      const TtsVoice(id: 'pt', name: 'pt', locale: 'pt'),
      const TtsVoice(id: 'pt-br', name: 'pt-br', locale: 'pt-BR'),
    ]);
    final router = VoiceRouter([engine]);
    expect((await router.route('pt-BR'))!.voices.single.id, 'pt-br');
    expect((await router.route('pt-AO'))!.voices.single.id, 'pt');
    expect((await router.route('pt'))!.voices.single.id, 'pt');
  });

  test('lists an engine\'s voices once', () async {
    final router = VoiceRouter([supertonic]);
    await router.route('en');
    await router.route('es');
    await router.route('zh');
    expect(supertonic.calls, 1);
  });

  test('skips an engine that cannot list its voices, and retries it', () async {
    final broken = VoicesEngine.pack(['en'], ['X'])
      ..error = PlatformException(code: 'load_failed');
    final errors = <Object>[];
    final router =
        VoiceRouter([broken, supertonic], onError: (e, _) => errors.add(e));

    expect((await router.route('en'))!.engine, same(supertonic));
    expect(errors.single, isA<PlatformException>());

    broken.error = null;
    expect((await router.route('en'))!.engine, same(broken));
  });

  test('lists every language', () async {
    final english = VoicesEngine.pack(['en-US', 'en'], ['af']);
    expect(await VoiceRouter([english, supertonic]).languages(),
        ['en-US', 'en', 'es', 'ja', 'pt']);
  });

  group('VoiceRoute', () {
    late VoiceRoute route;

    setUp(() async {
      route = (await VoiceRouter([supertonic]).route('en'))!;
    });

    test('voiceWithId falls back to the first voice', () {
      expect(route.voiceWithId('M1').id, 'M1');
      expect(route.voiceWithId('nope').id, 'F1');
      expect(route.voiceWithId(null).id, 'F1');
    });

    test('voiceForKey is stable and uses fnv1a32', () {
      for (final key in ['twitch:1', 'twitch:42', 'kick:login:muxfd']) {
        expect(route.voiceForKey(key).id,
            speakers[fnv1a32(key) % speakers.length]);
        expect(route.voiceForKey(key), route.voiceForKey(key));
      }
      // 0x3cef4db3 % 3 == 0 and 0x0241e6da % 3 == 2.
      expect(route.voiceForKey('twitch:1').id, 'F1');
      expect(route.voiceForKey('kick:login:muxfd').id, 'M1');
    });
  });
}
