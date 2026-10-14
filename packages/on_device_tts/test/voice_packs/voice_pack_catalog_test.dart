import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:on_device_tts/on_device_tts.dart';

Map<String, Object?> _pack(String id, {Map<String, Object?> extra = const {}}) {
  return {
    'id': id,
    'name': 'Pack $id',
    'model_type': 'vits',
    'languages': ['en-US'],
    'speakers': [
      {'id': 0, 'name': 'amy', 'gender': 'female'},
    ],
    'files': [
      {
        'url': 'https://example.com/$id.tar.bz2',
        'size': 10,
        'sha256': 'a' * 64,
        'path': '',
        'archive': 'tar.bz2',
        'strip_components': 1,
      },
    ],
    'license': {'name': 'CC0-1.0'},
    ...extra,
  };
}

String _catalog(List<Object?> packs, {int schema = 1, int version = 1}) =>
    jsonEncode({'schema': schema, 'version': version, 'packs': packs});

void main() {
  group('the bundled catalog', () {
    final catalog = VoicePackCatalog.parse(bundledVoicePackCatalogJson);

    test('parses, and every pack is supported', () {
      expect(catalog.allPacks, hasLength(1));
      expect(catalog.packs, hasLength(1));
      expect(catalog.schema, VoicePackCatalog.supportedSchema);
    });

    test('has Supertonic 3', () {
      final supertonic = catalog.pack('supertonic-3')!;
      expect(supertonic.modelType, VoicePackModelType.supertonic);
      expect(supertonic.languages, hasLength(31));
      expect(supertonic.speaks('ru'), isTrue);
      expect(supertonic.speakers.map((speaker) => speaker.name),
          ['F1', 'F2', 'F3', 'F4', 'F5', 'M1', 'M2', 'M3', 'M4', 'M5']);
      // Loose files from Hugging Face, pinned to a revision.
      for (final file in supertonic.files) {
        expect(file.archive, isNull);
        expect(file.url.host, 'huggingface.co');
        expect(file.url.path, isNot(contains('/main/')));
      }
      // Everything the engine is told about gets downloaded.
      final paths = supertonic.files.map((file) => file.path).toSet();
      for (final value in supertonic.config.values) {
        for (final path in value is List ? value : [value]) {
          expect(paths, contains(path));
        }
      }
      expect((supertonic.config['voice_styles'] as List).length,
          supertonic.speakers.length);
    });

    test('every file has a size, a checksum and a license', () {
      for (final pack in catalog.packs) {
        expect(pack.license, isNotNull, reason: pack.id);
        expect(pack.languages, isNotEmpty, reason: pack.id);
        expect(pack.speakers, isNotEmpty, reason: pack.id);
        for (final file in pack.files) {
          expect(file.url.scheme, 'https');
          expect(file.size, greaterThan(0));
          expect(file.sha256, matches(RegExp(r'^[0-9a-f]{64}$')));
        }
      }
    });
  });

  test('round-trips through JSON', () {
    final catalog = VoicePackCatalog.parse(_catalog([_pack('a')]));
    final again = VoicePackCatalog.parse(jsonEncode(catalog.toJson()));
    expect(again.toJson(), catalog.toJson());
    final file = again.pack('a')!.files.single;
    expect(file.archive, VoicePackArchiveType.tarBz2);
    expect(file.stripComponents, 1);
    expect(again.pack('a')!.speakers.single.gender, 'female');
  });

  group('forward compatibility', () {
    test('ignores unknown fields', () {
      final catalog = VoicePackCatalog.parse(jsonEncode({
        'schema': 1,
        'version': 4,
        'published': '2027-01-01',
        'packs': [
          _pack('a', extra: {
            'quality': 'high',
            'speakers': [
              {'id': 0, 'name': 'amy', 'accent': 'nyc'},
            ],
          }),
        ],
      }));
      expect(catalog.version, 4);
      expect(catalog.packs.single.speakers.single.name, 'amy');
    });

    test('keeps packs with an unknown model type but does not offer them', () {
      final catalog = VoicePackCatalog.parse(_catalog([
        _pack('a'),
        _pack('b', extra: {'model_type': 'f5-tts'}),
      ]));
      expect(catalog.allPacks.map((pack) => pack.id), ['a', 'b']);
      expect(catalog.packs.map((pack) => pack.id), ['a']);
      expect(catalog.pack('b')!.modelType, VoicePackModelType.unknown);
      expect(catalog.pack('b')!.modelTypeName, 'f5-tts');
    });

    test('does not offer packs with an unknown archive format', () {
      final catalog = VoicePackCatalog.parse(_catalog([
        _pack('a', extra: {
          'files': [
            {
              'url': 'https://example.com/a.tar.zst',
              'size': 1,
              'sha256': 'b' * 64,
              'archive': 'tar.zst',
            },
          ],
        }),
      ]));
      expect(catalog.pack('a')!.isSupported, isFalse);
      expect(catalog.packs, isEmpty);
    });

    test('drops a malformed pack and keeps the rest', () {
      final catalog = VoicePackCatalog.parse(_catalog([
        _pack('a', extra: {'files': 'nope'}),
        _pack('b'),
        'not a pack',
        _pack('Bad Id'),
        _pack('c', extra: {
          'files': [
            {
              'url': 'https://example.com/c',
              'size': 1,
              'sha256': 'short',
              'path': 'c.onnx',
            },
          ],
        }),
      ]));
      expect(catalog.allPacks.map((pack) => pack.id), ['b']);
    });

    test('drops a pack whose files would land outside its directory', () {
      for (final path in ['../x', '/etc/x', 'a/../../x', r'a\..\x']) {
        final catalog = VoicePackCatalog.parse(_catalog([
          _pack('a', extra: {
            'files': [
              {
                'url': 'https://example.com/a',
                'size': 1,
                'sha256': 'b' * 64,
                'path': path,
              },
            ],
          }),
        ]));
        expect(catalog.allPacks, isEmpty, reason: path);
      }
    });

    test('keeps the first of two packs with the same id', () {
      final catalog = VoicePackCatalog.parse(_catalog([
        _pack('a', extra: {'name': 'first'}),
        _pack('a', extra: {'name': 'second'}),
      ]));
      expect(catalog.allPacks.single.name, 'first');
    });

    test('rejects a newer schema', () {
      expect(() => VoicePackCatalog.parse(_catalog([_pack('a')], schema: 2)),
          throwsA(isA<VoicePackCatalogException>()));
    });

    test('rejects text that is not a catalog', () {
      expect(() => VoicePackCatalog.parse('<html>'),
          throwsA(isA<VoicePackCatalogException>()));
      expect(() => VoicePackCatalog.parse('[]'),
          throwsA(isA<VoicePackCatalogException>()));
      expect(() => VoicePackCatalog.parse('{"schema": 1}'),
          throwsA(isA<VoicePackCatalogException>()));
    });
  });

  test('speaks matches languages like TtsVoice', () {
    final pack = VoicePackCatalog.parse(_catalog([
      _pack('a', extra: {
        'languages': ['en-US', 'pt_BR'],
      }),
    ])).packs.single;
    expect(pack.speaks('en'), isTrue);
    expect(pack.speaks('EN-us'), isTrue);
    expect(pack.speaks('en-GB'), isFalse);
    expect(pack.speaks('pt-BR'), isTrue);
    expect(pack.speaks('p'), isFalse);
  });

  test('min_app_version', () {
    final pack = VoicePackCatalog.parse(_catalog([
      _pack('a', extra: {'min_app_version': '1.10.0'}),
    ])).packs.single;
    expect(pack.isCompatibleWith('1.9.9'), isFalse);
    expect(pack.isCompatibleWith('1.10.0'), isTrue);
    expect(pack.isCompatibleWith('1.10.0+4'), isTrue);
    expect(pack.isCompatibleWith('2.0'), isTrue);
  });

  test('compareVersions', () {
    expect(compareVersions('1.2.10', '1.2.9'), greaterThan(0));
    expect(compareVersions('1.2', '1.2.0'), 0);
    expect(compareVersions('1.0.0+4', '1.0.0'), 0);
    expect(compareVersions('0.9', '1.0'), lessThan(0));
  });
}
