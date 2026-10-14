import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:on_device_tts/on_device_tts.dart';

const _gib = 1024 * 1024 * 1024;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const methods = MethodChannel('test/memory/onnx');
  const memory = EventChannel('test/memory/events');
  final platform = OnnxTtsPlatform(methods: methods, memory: memory);

  group('DeviceMemory', () {
    test('parses the native map', () {
      expect(
          DeviceMemory.fromMap(const {
            'totalBytes': 4 * _gib,
            'availableBytes': _gib,
            'lowRamDevice': true,
          }),
          const DeviceMemory(
              totalBytes: 4 * _gib,
              availableBytes: _gib,
              isLowRamDevice: true));
      expect(DeviceMemory.fromMap(const {'totalBytes': 1}),
          const DeviceMemory(totalBytes: 1));
    });

    test('2 GB phones and low-RAM devices are too small for neural TTS', () {
      // a "2 GB" phone reports about 1.8 GiB.
      expect(
          const DeviceMemory(totalBytes: 1900 * 1024 * 1024)
              .isTooSmallForNeuralTts,
          isTrue);
      expect(
          const DeviceMemory(totalBytes: 8 * _gib, isLowRamDevice: true)
              .isTooSmallForNeuralTts,
          isTrue);
    });

    test('3 GB phones and up are big enough', () {
      // a "3 GB" phone reports about 2.8 GiB.
      expect(
          const DeviceMemory(totalBytes: 2850 * 1024 * 1024)
              .isTooSmallForNeuralTts,
          isFalse);
      expect(const DeviceMemory(totalBytes: 8 * _gib).isTooSmallForNeuralTts,
          isFalse);
    });
  });

  group('OnnxTtsPlatform.deviceMemory', () {
    tearDown(() => messenger.setMockMethodCallHandler(methods, null));

    test('asks the native side', () async {
      messenger.setMockMethodCallHandler(methods, (call) async {
        expect(call.method, 'deviceMemory');
        return {'totalBytes': 6 * _gib, 'lowRamDevice': false};
      });
      expect(await platform.deviceMemory(),
          const DeviceMemory(totalBytes: 6 * _gib));
    });

    test('is null where the platform has no engine', () async {
      expect(await platform.deviceMemory(), isNull);
    });
  });

  group('MemoryPressureMonitor', () {
    MockStreamHandlerEventSink? sink;
    late int pressures;

    setUp(() {
      pressures = 0;
      sink = null;
      messenger.setMockStreamHandler(
          memory,
          MockStreamHandler.inline(
            onListen: (_, events) => sink = events,
            onCancel: (_) => sink = null,
          ));
    });

    tearDown(() => messenger.setMockStreamHandler(memory, null));

    test('on Android, releases on the native signals', () async {
      final monitor = MemoryPressureMonitor(() => pressures++,
          platform: platform, useNativeSignals: true)
        ..start();
      await pumpEventQueue();
      sink!.success({'level': 15}); // TRIM_MEMORY_RUNNING_CRITICAL
      await pumpEventQueue();
      expect(pressures, 1);

      monitor.dispose();
      await pumpEventQueue();
      expect(sink, isNull);
    });

    test("on Android, ignores Flutter's memory pressure", () async {
      // Flutter sends it for TRIM_MEMORY_UI_HIDDEN, i.e. on backgrounding.
      final monitor = MemoryPressureMonitor(() => pressures++,
          platform: platform, useNativeSignals: true)
        ..start();
      monitor.didHaveMemoryPressure();
      await _sendMemoryPressure();
      expect(pressures, 0);
      monitor.dispose();
    });

    test("elsewhere, releases on Flutter's memory pressure", () async {
      final monitor = MemoryPressureMonitor(() => pressures++,
          platform: platform, useNativeSignals: false)
        ..start();
      await _sendMemoryPressure();
      expect(pressures, 1);
      expect(sink, isNull, reason: "doesn't listen to the native channel");

      monitor.dispose();
      await _sendMemoryPressure();
      expect(pressures, 1);
    });

    test('start and dispose twice are harmless', () async {
      final monitor = MemoryPressureMonitor(() => pressures++,
          platform: platform, useNativeSignals: false)
        ..start()
        ..start();
      await _sendMemoryPressure();
      expect(pressures, 1);
      monitor
        ..dispose()
        ..dispose();
    });
  });
}

/// Sends the system channel's memory pressure message, as the engine does.
Future<void> _sendMemoryPressure() async {
  final message =
      const JSONMessageCodec().encodeMessage({'type': 'memoryPressure'});
  await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .handlePlatformMessage(SystemChannels.system.name, message, (_) {});
}
