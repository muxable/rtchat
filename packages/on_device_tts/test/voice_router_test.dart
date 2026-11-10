import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:on_device_tts/on_device_tts.dart';

/// An engine that only lists voices: each speaker in each language.
class VoicesEngine implements TtsEngine {
  final List<TtsVoice> list;
  var calls = 0;
  Object? error;

  VoicesEngine(List<String> languages, [List<String> speakers = _speakers])
    : list = [
        for (final speaker in speakers)
          for (final language in languages)
            TtsVoice(id: speaker, name: speaker, locale: language),
      ];

  @override
  Future<List<TtsVoice>> voices({String? language}) async {
    calls++;
    if (error case final error?) throw error;
    return list;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _speakers = ['F1', 'F2', 'M1'];

void main() {
  group('LanguageTag', () {
    test('parses language, script and region, without the rest', () {
      expect(LanguageTag.parse('zh_Hant_TW').toString(), 'zh-hant-tw');
      expect(LanguageTag.parse('en-US-u-ca-gregory').toString(), 'en-us');
      expect(LanguageTag.parse('es-419').region, '419');
      expect(LanguageTag.parse('zh-HK').script, 'hant');
      expect(LanguageTag.parse('zh-CN').script, 'hans');
      expect(['iw', 'in', 'no'].map((t) => LanguageTag.parse(t).language), [
        'he',
        'id',
        'nb',
      ]);
    });

    test('ranks exact, then the bare language, then other regions', () {
      expect(LanguageTag.matchScore('pt-BR', 'pt-br'), 4);
      expect(LanguageTag.matchScore('pt-BR', 'pt'), 3);
      expect(LanguageTag.matchScore('en', 'en-US'), 2);
      expect(LanguageTag.matchScore('pt-BR', 'pt-PT'), 1);
      expect(LanguageTag.matchScore('pt', 'es'), 0);
      expect(LanguageTag.matchScore('', 'en'), 0);
    });

    test('never matches another script', () {
      expect(LanguageTag.matchScore('zh-TW', 'zh-CN'), 0);
      expect(LanguageTag.matchScore('zh-Hant', 'zh-Hans'), 0);
      expect(LanguageTag.matchScore('zh-HK', 'zh-Hant'), 3);
    });

    test('bestMatch picks the best available tag', () {
      expect(LanguageTag.bestMatch('pt-BR', ['pt-PT', 'pt']), 'pt');
      expect(LanguageTag.bestMatch('es-MX', ['en', 'es-ES']), 'es-ES');
      expect(LanguageTag.bestMatch('zh-Hant', ['zh-Hans', 'ja']), isNull);
    });
  });

  test('fnv1a32 matches the FNV-1a test vectors and stays put', () {
    expect(fnv1a32(''), 0x811c9dc5);
    expect(fnv1a32('foobar'), 0xbf9cf968);
    expect(fnv1a32('日本'), 0x9f26ee51, reason: 'hashes the UTF-8 bytes');
    // pinned: a change would give every chatter a new voice.
    expect(fnv1a32('twitch:1'), 0x3cef4db3);
  });

  group('VoiceRouter', () {
    late VoicesEngine supertonic;

    setUp(() => supertonic = VoicesEngine(['en', 'es', 'ja', 'pt']));

    test('routes a language to the engine and tag that speak it', () async {
      final route = (await VoiceRouter([supertonic]).route('pt-BR'))!;
      expect(route.engine, same(supertonic));
      expect(route.language, 'pt');
      expect(route.voices.map((v) => '${v.id}/${v.locale}'), [
        'F1/pt',
        'F2/pt',
        'M1/pt',
      ]);
      expect(await VoiceRouter([supertonic]).route('zh'), isNull);
      expect(await VoiceRouter.empty.route('en'), isNull);
    });

    test('prefers earlier engines and lists voices once', () async {
      final english = VoicesEngine(['en-US', 'en-GB'], ['af']);
      final router = VoiceRouter([english, supertonic]);
      expect((await router.route('en'))!.language, 'en-US');
      expect((await router.route('en-GB'))!.language, 'en-GB');
      expect((await router.route('es'))!.engine, same(supertonic));
      expect((english.calls, supertonic.calls), (1, 1));
      expect(await router.languages(), [
        'en-US',
        'en-GB',
        'en',
        'es',
        'ja',
        'pt',
      ]);
    });

    test(
      'skips an engine that cannot list its voices, and retries it',
      () async {
        final broken = VoicesEngine(['en'])
          ..error = PlatformException(code: 'load_failed');
        final errors = <Object>[];
        final router = VoiceRouter([
          broken,
          supertonic,
        ], onError: (e, _) => errors.add(e));
        expect((await router.route('en'))!.engine, same(supertonic));
        expect(errors.single, isA<PlatformException>());

        broken.error = null;
        expect((await router.route('en'))!.engine, same(broken));
      },
    );

    test('picks a voice by id, or a stable one by key', () async {
      final route = (await VoiceRouter([supertonic]).route('en'))!;
      expect(route.voiceWithId('M1').id, 'M1');
      expect(route.voiceWithId('nope').id, 'F1');
      expect(route.voiceWithId(null).id, 'F1');
      for (final key in ['twitch:1', 'twitch:42', 'kick:login:muxfd']) {
        expect(
          route.voiceForKey(key).id,
          _speakers[fnv1a32(key) % _speakers.length],
        );
      }
    });
  });
}
