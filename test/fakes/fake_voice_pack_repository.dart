import 'dart:async';
import 'dart:io';

import 'package:on_device_tts/on_device_tts.dart';

/// A [VoicePackInstallTask] that tests drive: [emit] progress, then
/// [finish] or [fail]. [cancel] fails it as cancelled, like the real one.
class FakeInstallTask implements VoicePackInstallTask {
  @override
  final VoicePack pack;

  /// Whether the install may use mobile data.
  final bool allowMetered;

  final _progress = StreamController<VoicePackProgress>.broadcast();
  final _done = Completer<InstalledVoicePack>();
  VoicePackProgress _latest;
  var _isCancelled = false;

  /// Called when the task ends, however it ends.
  void Function()? onEnd;

  FakeInstallTask(this.pack, {this.allowMetered = false})
      : _latest = VoicePackProgress(
            VoicePackInstallPhase.waiting, 0, pack.downloadSize) {
    _done.future.ignore();
  }

  @override
  Stream<VoicePackProgress> get progress => _progress.stream;

  @override
  VoicePackProgress get latest => _latest;

  @override
  Future<InstalledVoicePack> get done => _done.future;

  @override
  bool get isCancelled => _isCancelled;

  @override
  void cancel() {
    if (_done.isCompleted) return;
    _isCancelled = true;
    fail(const VoicePackCancelledException());
  }

  void emit(VoicePackInstallPhase phase, [int bytes = 0]) {
    _latest = VoicePackProgress(phase, bytes, pack.downloadSize);
    _progress.add(_latest);
  }

  void finish(InstalledVoicePack installed) {
    _end();
    _done.complete(installed);
  }

  void fail(Object error) {
    _end();
    _done.completeError(error);
  }

  void _end() {
    onEnd?.call();
    _progress.close();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A [VoicePackRepository] in memory: installs are [FakeInstallTask]s that
/// tests finish themselves, or [completeInstall].
class FakeVoicePackRepository implements VoicePackRepository {
  List<VoicePack> catalogPacks;
  final installed = <String, InstalledVoicePack>{};
  final tasks = <String, FakeInstallTask>{};
  final deleted = <String>[];
  final _changes = StreamController<void>.broadcast();

  /// Thrown by [availablePacks] when set.
  Object? catalogError;

  @override
  final bool wifiOnly;

  FakeVoicePackRepository({List<VoicePack>? packs, this.wifiOnly = true})
      : catalogPacks = packs ?? [testPack()];

  @override
  Directory get directory => Directory('/voice_packs');

  @override
  Stream<void> get changes => _changes.stream;

  @override
  Future<void> cleanUp({bool all = false}) async {}

  @override
  Future<List<VoicePack>> availablePacks({bool refresh = false}) async {
    final error = catalogError;
    if (error != null) throw error;
    return List.of(catalogPacks);
  }

  @override
  Future<Map<String, InstalledVoicePack>> installedPacks() async =>
      Map.of(installed);

  @override
  Future<InstalledVoicePack?> installedPack(String id) async => installed[id];

  @override
  Future<VoicePackStatus> status(VoicePack pack) async {
    if (tasks.containsKey(pack.id)) return VoicePackStatus.installing;
    final have = installed[pack.id];
    if (have == null) return VoicePackStatus.notInstalled;
    return have.isOutdatedBy(pack)
        ? VoicePackStatus.upgradeAvailable
        : VoicePackStatus.installed;
  }

  @override
  VoicePackInstallTask? task(String id) => tasks[id];

  @override
  VoicePackInstallTask install(VoicePack pack, {bool allowMetered = false}) {
    final running = tasks[pack.id];
    if (running != null) return running;
    final task = FakeInstallTask(pack, allowMetered: allowMetered);
    task.onEnd = () => tasks.remove(pack.id);
    tasks[pack.id] = task;
    return task;
  }

  /// Finishes the install of [id] as if it had downloaded.
  void completeInstall(String id, {int sizeOnDisk = 402000000}) {
    final task = tasks[id]!;
    final pack = installedPack0(task.pack, sizeOnDisk: sizeOnDisk);
    installed[id] = pack;
    task.finish(pack);
    _changes.add(null);
  }

  /// Installs [pack] without a task.
  void add(VoicePack pack, {int sizeOnDisk = 402000000}) {
    installed[pack.id] = installedPack0(pack, sizeOnDisk: sizeOnDisk);
    _changes.add(null);
  }

  @override
  Future<void> delete(String id) async {
    tasks[id]?.cancel();
    deleted.add(id);
    if (installed.remove(id) != null) _changes.add(null);
  }

  @override
  Future<void> dispose() async => _changes.close();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

InstalledVoicePack installedPack0(VoicePack pack, {int sizeOnDisk = 1}) =>
    InstalledVoicePack(
      pack: pack,
      directory: '/voice_packs/packs/${pack.id}',
      catalogVersion: 1,
      sizeOnDisk: sizeOnDisk,
      installedAt: DateTime(2026),
    );

/// The languages of Supertonic 3.
const supertonicLanguages = [
  'en', 'ko', 'ja', 'ar', 'bg', 'cs', 'da', 'de', 'el', 'es', 'et', //
  'fi', 'fr', 'hi', 'hr', 'hu', 'id', 'it', 'lt', 'lv', 'nl', 'pl',
  'pt', 'ro', 'ru', 'sk', 'sl', 'sv', 'tr', 'uk', 'vi',
];

/// A pack like Supertonic 3: 31 languages, ten voices, about 401 MB.
VoicePack testPack({
  String id = 'supertonic-3',
  String name = 'Supertonic 3',
  List<String> languages = supertonicLanguages,
  int size = 401000000,
}) =>
    VoicePack(
      id: id,
      name: name,
      modelTypeName: 'supertonic',
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
            url: Uri.parse('https://example.com/$id.onnx'),
            size: size,
            sha256: 'a' * 64,
            path: 'onnx/vocoder.onnx'),
      ],
      license: VoicePackLicense(
        name: 'LicenseRef-OpenRAIL-M',
        url: Uri.parse('https://example.com/LICENSE'),
        attribution: '$name by Supertone Inc.',
      ),
    );
