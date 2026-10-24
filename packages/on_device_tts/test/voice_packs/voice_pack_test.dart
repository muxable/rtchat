import 'package:flutter_test/flutter_test.dart';
import 'package:on_device_tts/on_device_tts.dart';

void main() {
  group('the bundled packs', () {
    test('have unique ids', () {
      final ids = bundledVoicePacks.map((pack) => pack.id).toList();
      expect(ids.toSet(), hasLength(ids.length));
      for (final id in ids) {
        expect(id, matches(RegExp(r'^[a-z0-9][a-z0-9._-]*$')));
      }
    });

    test('have safe paths, checksums, sizes and licenses', () {
      for (final pack in bundledVoicePacks) {
        expect(pack.license, isNotNull, reason: pack.id);
        expect(pack.languages, isNotEmpty, reason: pack.id);
        expect(pack.speakers, isNotEmpty, reason: pack.id);
        final paths = <String>{};
        for (final file in pack.files) {
          expect(isSafeRelativePath(file.path), isTrue, reason: file.path);
          expect(paths.add(file.path), isTrue, reason: file.path);
          expect(file.url.scheme, 'https');
          expect(file.size, greaterThan(0));
          expect(file.sha256, matches(RegExp(r'^[0-9a-f]{64}$')));
        }
        // Everything the engine is told about gets downloaded.
        for (final value in pack.config.values) {
          for (final path in value is List ? value : [value]) {
            expect(paths, contains(path), reason: '${pack.id}: $path');
          }
        }
      }
    });

    test('have Supertonic 3', () {
      final supertonic = bundledVoicePacks.singleWhere(
        (pack) => pack.id == 'supertonic-3',
      );
      expect(supertonic.modelType, VoicePackModelType.supertonic);
      expect(supertonic.languages, hasLength(31));
      expect(supertonic.speaks('ru'), isTrue);
      expect(supertonic.speakers.map((speaker) => speaker.name), [
        'F1',
        'F2',
        'F3',
        'F4',
        'F5',
        'M1',
        'M2',
        'M3',
        'M4',
        'M5',
      ]);
      // Loose files from Hugging Face, pinned to a revision.
      for (final file in supertonic.files) {
        expect(file.url.host, 'huggingface.co');
        expect(
          file.url.path,
          contains('/resolve/3cadd1ee6394adea1bd021217a0e650ede09a323/'),
        );
        expect(file.url.path, endsWith('/${file.path}'));
      }
      expect(
        (supertonic.config['voice_styles'] as List).length,
        supertonic.speakers.length,
      );
    });
  });

  test('round-trips through JSON', () {
    for (final pack in bundledVoicePacks) {
      final again = VoicePack.fromJson(pack.toJson());
      expect(again.toJson(), pack.toJson());
      expect(again.speakers, pack.speakers);
      expect(again.files, pack.files);
    }
  });

  test('speaks matches languages like TtsVoice', () {
    const pack = VoicePack(
      id: 'a',
      name: 'a',
      modelType: VoicePackModelType.supertonic,
      languages: ['en-US', 'pt_BR'],
      files: [],
    );
    expect(pack.speaks('en'), isTrue);
    expect(pack.speaks('EN-us'), isTrue);
    expect(pack.speaks('en-GB'), isFalse);
    expect(pack.speaks('pt-BR'), isTrue);
    expect(pack.speaks('p'), isFalse);
  });

  test('isSafeRelativePath', () {
    for (final path in ['a', 'a/b.onnx', 'a/./b', 'a/../b']) {
      expect(isSafeRelativePath(path), isTrue, reason: path);
    }
    for (final path in [
      '',
      '.',
      '..',
      '../a',
      'a/../../b',
      '/etc/passwd',
      r'a\b',
      'C:/a',
      'a\x00b',
    ]) {
      expect(isSafeRelativePath(path), isFalse, reason: path);
    }
  });
}
