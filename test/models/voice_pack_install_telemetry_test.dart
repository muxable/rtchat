import 'package:flutter_test/flutter_test.dart';
import 'package:on_device_tts/on_device_tts.dart';
import 'package:rtchat/models/tts/telemetry.dart';
import 'package:rtchat/models/tts/voice_packs.dart';

import '../fakes/fake_telemetry.dart';
import '../fakes/fake_voice_pack_repository.dart';

void main() {
  late FakeVoicePackRepository repository;
  late FakeTtsTelemetry telemetry;
  late VoicePacksModel model;
  final pack = testPack();

  setUp(() async {
    repository = FakeVoicePackRepository();
    telemetry = FakeTtsTelemetry();
    model = VoicePacksModel(repository,
        isSupported: true,
        telemetry: telemetry,
        wifiWaitThreshold: const Duration(milliseconds: 1));
    await model.load();
  });

  tearDown(() async {
    model.dispose();
    await repository.dispose();
  });

  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 20));

  test('an install that completes', () async {
    model.install(pack);
    // following the same install again isn't another start.
    model.install(pack);
    final task = repository.tasks[pack.id]!;
    task.emit(VoicePackInstallPhase.downloading, 1000);
    task.emit(VoicePackInstallPhase.verifying, pack.downloadSize);
    repository.completeInstall(pack.id);
    await settle();
    expect(telemetry.installStages,
        [PackInstallStage.started, PackInstallStage.completed]);
    final started = telemetry.installs.first;
    expect(started.packId, 'supertonic-3');
    expect(started.sizeBytes, 401000000);
    expect(started.overMobileData, isFalse);
    expect(started.duration, isNull);
    expect(telemetry.installs.last.duration, isNotNull);
  });

  test('an install that waits for Wi-Fi, then fails', () async {
    model.install(pack);
    final task = repository.tasks[pack.id]!;
    task.emit(VoicePackInstallPhase.waiting);
    await settle();
    task.emit(VoicePackInstallPhase.downloading, 10);
    task.emit(VoicePackInstallPhase.waiting, 10);
    await settle();
    task.fail(const VoicePackDownloadException('boom', statusCode: 503));
    await settle();
    expect(telemetry.installStages, [
      PackInstallStage.started,
      PackInstallStage.waitingForWifi,
      PackInstallStage.failed,
    ]);
    expect(telemetry.installs.last.error, 'download_http_503');
  });

  test('a brief wait is not waiting for Wi-Fi', () async {
    model.install(pack);
    final task = repository.tasks[pack.id]!;
    task.emit(VoicePackInstallPhase.waiting);
    task.emit(VoicePackInstallPhase.downloading, 10);
    await settle();
    repository.completeInstall(pack.id);
    await settle();
    expect(telemetry.installStages,
        [PackInstallStage.started, PackInstallStage.completed]);
  });

  test('over mobile data, the wait is not for Wi-Fi', () async {
    model.install(pack, allowMetered: true);
    repository.tasks[pack.id]!.emit(VoicePackInstallPhase.waiting);
    await settle();
    model.cancel(pack.id);
    await settle();
    expect(telemetry.installStages,
        [PackInstallStage.started, PackInstallStage.cancelled]);
    expect(telemetry.installs.last.overMobileData, isTrue);
  });

  test('switching to mobile data carries on the same install', () async {
    model.install(pack);
    await model.installOverMobileData(pack);
    repository.completeInstall(pack.id);
    await settle();
    expect(telemetry.installStages,
        [PackInstallStage.started, PackInstallStage.completed]);
    expect(telemetry.installs.last.overMobileData, isTrue);
  });

  test('deleting a pack', () async {
    repository.add(pack, sizeOnDisk: 402000000);
    await model.refresh();
    await model.delete(pack.id);
    expect(telemetry.installStages, [PackInstallStage.deleted]);
    expect(telemetry.installs.single.sizeBytes, 402000000);
    // nothing installed, nothing deleted.
    await model.delete(pack.id);
    expect(telemetry.installs, hasLength(1));
  });
}
