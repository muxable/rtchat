import 'dart:async';

import 'package:on_device_tts/on_device_tts.dart';

/// A [VoicePackRepository] with packs installed in memory.
class FakeVoicePackRepository implements VoicePackRepository {
  List<VoicePack> catalog;
  final installed = <String, InstalledVoicePack>{};
  final deleted = <String>[];
  final _changes = StreamController<void>.broadcast();

  FakeVoicePackRepository({List<VoicePack>? catalog})
      : catalog = catalog ?? [testPack()];

  void add(InstalledVoicePack pack) {
    installed[pack.id] = pack;
    _changes.add(null);
  }

  void remove(String id) {
    installed.remove(id);
    _changes.add(null);
  }

  @override
  Stream<void> get changes => _changes.stream;

  @override
  Future<void> cleanUp({bool all = false}) async {}

  @override
  Future<List<VoicePack>> availablePacks() async => List.of(catalog);

  @override
  Future<Map<String, InstalledVoicePack>> installedPacks() async =>
      Map.of(installed);

  @override
  Future<void> delete(String id) async {
    deleted.add(id);
    if (installed.remove(id) != null) _changes.add(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// An installed Supertonic pack [id] speaking [languages].
InstalledVoicePack installedPack(String id,
        {int version = 1, List<String> languages = const ['en']}) =>
    InstalledVoicePack(
      pack: VoicePack(
        id: id,
        name: id,
        version: version,
        modelType: VoicePackModelType.supertonic,
        languages: languages,
        files: [
          VoicePackFile(
              url: Uri.parse('https://example.com/$id'),
              size: 1,
              sha256: 'a' * 64,
              path: 'onnx/vocoder.onnx'),
        ],
      ),
      directory: '/packs/$id',
      sizeOnDisk: 1,
      installedAt: DateTime(2026),
    );

/// [pack], installed.
InstalledVoicePack installedPackOf(VoicePack pack, {int sizeOnDisk = 1}) =>
    InstalledVoicePack(
        pack: pack,
        directory: '/packs/${pack.id}',
        sizeOnDisk: sizeOnDisk,
        installedAt: DateTime(2026));

/// A pack like Supertonic 3: [languages], ten voices, about 401 MB.
VoicePack testPack({
  List<String> languages = const ['en', 'fr', 'de', 'ja', 'ko'],
}) =>
    VoicePack(
      id: 'supertonic-3',
      name: 'Supertonic 3',
      modelType: VoicePackModelType.supertonic,
      languages: languages,
      speakers: [
        for (final (i, name) in const [
          'F1', 'F2', 'F3', 'F4', 'F5', //
          'M1', 'M2', 'M3', 'M4', 'M5',
        ].indexed)
          VoicePackSpeaker(
              index: i,
              name: name,
              gender: name.startsWith('F') ? 'female' : 'male'),
      ],
      files: [
        VoicePackFile(
            url: Uri.parse('https://example.com/supertonic-3.onnx'),
            size: 401000000,
            sha256: 'a' * 64,
            path: 'onnx/vocoder.onnx'),
      ],
      license: VoicePackLicense(
        name: 'LicenseRef-OpenRAIL-M',
        url: Uri.parse('https://example.com/LICENSE'),
        attribution: 'Supertonic 3 by Supertone Inc.',
      ),
    );
