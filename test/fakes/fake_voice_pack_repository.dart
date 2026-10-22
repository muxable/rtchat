import 'dart:async';

import 'package:on_device_tts/on_device_tts.dart';

/// A [VoicePackRepository] with packs installed in memory. Installs are
/// [FakeInstallTask]s that tests drive themselves.
class FakeVoicePackRepository implements VoicePackRepository {
  /// The packs on offer: the bundled catalog unless a test changes it.
  List<VoicePack> catalog = bundledVoicePacks;
  final installed = <String, InstalledVoicePack>{};
  final tasks = <String, FakeInstallTask>{};
  final deleted = <String>[];
  final _changes = StreamController<void>.broadcast();

  @override
  final bool wifiOnly = true;

  void add(InstalledVoicePack pack) {
    installed[pack.id] = pack;
    _changes.add(null);
  }

  void remove(String id) {
    installed.remove(id);
    _changes.add(null);
  }

  /// Finishes the install of [id] as if it had downloaded.
  void completeInstall(String id, {int sizeOnDisk = 402000000}) {
    final task = tasks[id]!;
    final pack = installedPackOf(task.pack, sizeOnDisk: sizeOnDisk);
    installed[id] = pack;
    task.finish(pack);
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
  VoicePackInstallTask install(VoicePack pack, {bool allowMetered = false}) =>
      tasks[pack.id] ??= FakeInstallTask(pack, allowMetered: allowMetered)
        ..onEnd = () => tasks.remove(pack.id);

  @override
  Future<void> delete(String id) async {
    tasks[id]?.cancel();
    deleted.add(id);
    if (installed.remove(id) != null) _changes.add(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A [VoicePackInstallTask] that tests drive: [emit] progress, then
/// [finish] or [fail]. [cancel] fails it as cancelled, like the real one.
class FakeInstallTask implements VoicePackInstallTask {
  @override
  final VoicePack pack;
  final bool allowMetered;
  final _progress = StreamController<VoicePackProgress>.broadcast();
  final _done = Completer<InstalledVoicePack>();
  VoicePackProgress _latest;
  var _isCancelled = false;

  /// Called when the task ends, however it ends.
  void Function()? onEnd;

  FakeInstallTask(this.pack, {this.allowMetered = false})
    : _latest = VoicePackProgress(
        VoicePackInstallPhase.waiting,
        0,
        pack.downloadSize,
      ) {
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

/// An installed Supertonic pack [id] speaking [languages].
InstalledVoicePack installedPack(
  String id, {
  int version = 1,
  List<String> languages = const ['en'],
}) => InstalledVoicePack(
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
        path: 'onnx/vocoder.onnx',
      ),
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
      installedAt: DateTime(2026),
    );
