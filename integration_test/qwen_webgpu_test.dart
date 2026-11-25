import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:on_device_tts/on_device_tts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rtchat/models/tts/qwen_engine.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final result = <String, Object?>{};
  const report = String.fromEnvironment('QWEN_DEVICE_REPORT');
  if (report.isNotEmpty) {
    unawaited(
      binding.allTestsPassed.future.then((passed) async {
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/$report');
        final tmp = File('${file.path}.tmp');
        await tmp.writeAsString(
          jsonEncode({
            ...result,
            'passed': passed,
            'failures': {
              for (final f in binding.failureMethodsDetails)
                f.methodName: f.details,
            },
          }),
        );
        await tmp.rename(file.path);
      }),
    );
  }
  testWidgets(
    'Qwen plays on qualified hardware or declines an unsupported WebView',
    (tester) async {
      final dir = await getApplicationDocumentsDirectory();
      final engine = QwenTtsEngine(
        InstalledVoicePack(
          pack: bundledVoicePacks.singleWhere(
            (p) => p.modelType == VoicePackModelType.qwen3Tts,
          ),
          directory: '${dir.path}/qwen-models',
          sizeOnDisk: 0,
          installedAt: DateTime.now(),
        ),
      );
      addTearDown(engine.dispose);
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ValueListenableBuilder<WebViewController?>(
            valueListenable: QwenTtsEngine.view,
            builder:
                (_, controller, _) =>
                    controller == null
                        ? const SizedBox()
                        : WebViewWidget(controller: controller),
          ),
        ),
      );
      var finished = false;
      Object? error;
      final clock = Stopwatch()..start();
      unawaited(
        engine
            .speak('Thank you!')
            .then<void>(
              (_) {
                finished = true;
              },
              onError: (Object e, StackTrace _) {
                error = e;
                finished = true;
              },
            ),
      );
      while (!finished && clock.elapsed < const Duration(minutes: 4)) {
        await tester.pump();
        await Future<void>.delayed(const Duration(milliseconds: 40));
      }
      expect(
        finished,
        isTrue,
        reason: 'The native WebView did not finish Qwen speech',
      );
      result['elapsed_ms'] = clock.elapsedMilliseconds;
      if (error != null) {
        final message = error.toString();
        final unavailable =
            message.contains('requires a hardware WebGPU adapter') ||
            message.contains(
              'requires an identifiable hardware WebGPU adapter',
            );
        final belowRate =
            message.contains('Qwen is slower than playback on this device') ||
            message.contains('Qwen playback would underrun by');
        expect(unavailable || belowRate, isTrue, reason: message);
        expect(engine.unavailable.value, isNotNull);
        result['outcome'] =
            unavailable ? 'no_hardware_adapter' : 'below_realtime';
        result['reason'] = message;
      } else {
        expect(engine.qualification?['rtf'], lessThan(1));
        result['outcome'] = 'played';
        result['qualification'] = engine.qualification;
      }
      debugPrint('Qwen mobile ${jsonEncode(result)}');
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
