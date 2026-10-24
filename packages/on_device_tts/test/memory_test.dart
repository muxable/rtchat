import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:on_device_tts/on_device_tts.dart';

const _mib = 1024 * 1024;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const methods = MethodChannel('test/memory/onnx');
  const memory = EventChannel('test/memory/events');
  final platform = OnnxTtsPlatform(methods: methods, memory: memory);

  test('2 GB phones and low-RAM devices are too small for neural TTS', () {
    // phones sold as 2 GB report about 1.8 GiB, and 3 GB about 2.8 GiB.
    expect(
      [
        const DeviceMemory(totalBytes: 1900 * _mib),
        const DeviceMemory(totalBytes: 8192 * _mib, isLowRamDevice: true),
        const DeviceMemory(totalBytes: 2850 * _mib),
      ].map((m) => m.isTooSmallForNeuralTts),
      [true, true, false],
    );
  });

  test('deviceMemory asks the native side, if there is one', () async {
    expect(await platform.deviceMemory(), isNull);

    messenger.setMockMethodCallHandler(methods, (call) async {
      expect(call.method, 'deviceMemory');
      return {'totalBytes': 6144 * _mib, 'lowRamDevice': true};
    });
    final device = (await platform.deviceMemory())!;
    expect(
      (device.totalBytes, device.availableBytes, device.isLowRamDevice),
      (6144 * _mib, null, true),
    );
    messenger.setMockMethodCallHandler(methods, null);
  });

  group('MemoryPressureMonitor', () {
    MockStreamHandlerEventSink? sink;
    late int pressures;

    setUp(() {
      pressures = 0;
      messenger.setMockStreamHandler(
        memory,
        MockStreamHandler.inline(
          onListen: (_, events) => sink = events,
          onCancel: (_) => sink = null,
        ),
      );
    });

    tearDown(() => messenger.setMockStreamHandler(memory, null));

    /// Sends the system channel's memory pressure, as the engine does.
    Future<void> flutterMemoryPressure() => messenger.handlePlatformMessage(
      SystemChannels.system.name,
      const JSONMessageCodec().encodeMessage({'type': 'memoryPressure'}),
      (_) {},
    );

    test("on Android, listens to the native signals, not Flutter's", () async {
      final monitor = MemoryPressureMonitor(
        () => pressures++,
        platform: platform,
        useNativeSignals: true,
      )..start();
      await pumpEventQueue();
      sink!.success({'level': 15}); // TRIM_MEMORY_RUNNING_CRITICAL
      await flutterMemoryPressure(); // e.g. TRIM_MEMORY_UI_HIDDEN
      await pumpEventQueue();
      expect(pressures, 1);

      monitor.dispose();
      await pumpEventQueue();
      expect(sink, isNull);
    });

    test("elsewhere, listens to Flutter's memory pressure", () async {
      final monitor =
          MemoryPressureMonitor(
              () => pressures++,
              platform: platform,
              useNativeSignals: false,
            )
            ..start()
            ..start();
      await flutterMemoryPressure();
      expect(pressures, 1);
      expect(sink, isNull, reason: "doesn't listen to the native channel");

      monitor
        ..dispose()
        ..dispose();
      await flutterMemoryPressure();
      expect(pressures, 1);
    });
  });
}
