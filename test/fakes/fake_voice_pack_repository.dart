import 'dart:async';

import 'package:on_device_tts/on_device_tts.dart';

/// A [VoicePackRepository] with packs installed in memory.
class FakeVoicePackRepository implements VoicePackRepository {
  /// The packs on offer: the bundled catalog unless a test changes it.
  List<VoicePack> catalog = bundledVoicePacks;
  final installed = <String, InstalledVoicePack>{};
  final _changes = StreamController<void>.broadcast();

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
  Future<List<VoicePack>> availablePacks() async => List.of(catalog);

  @override
  Future<Map<String, InstalledVoicePack>> installedPacks() async =>
      Map.of(installed);

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
