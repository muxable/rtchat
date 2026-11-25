import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:on_device_tts/on_device_tts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rtchat/models/tts/qwen_engine.dart';
import 'package:webview_flutter/webview_flutter.dart';

// A native app entry point so the OS drives WebView frames and audio normally.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dir = await getApplicationDocumentsDirectory();
  const report = String.fromEnvironment(
    'QWEN_DEVICE_REPORT',
    defaultValue: 'qwen.json',
  );
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
  runApp(
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
  final result = <String, Object?>{};
  final clock = Stopwatch()..start();
  try {
    try {
      await engine.speak('Thank you!').timeout(const Duration(minutes: 4));
      final rtf = engine.qualification?['rtf'];
      if (rtf is! num || !(rtf > 0 && rtf < 1)) {
        throw StateError(
          'Expected a measured real-time factor below one: $rtf',
        );
      }
      result['outcome'] = 'played';
      result['qualification'] = engine.qualification;
    } catch (error) {
      final message = error.toString();
      if (engine.unavailable.value == null) rethrow;
      if (message.contains('requires a hardware WebGPU adapter') ||
          message.contains(
            'requires an identifiable hardware WebGPU adapter',
          )) {
        result['outcome'] = 'no_hardware_adapter';
      } else if (message.contains(
            'Qwen is slower than playback on this device',
          ) ||
          message.contains('Qwen playback would underrun by')) {
        result['outcome'] = 'below_realtime';
      } else {
        rethrow;
      }
      result['reason'] = message;
    }
    await engine.dispose();
    result['passed'] = true;
  } catch (error, stack) {
    result['passed'] = false;
    result['error'] = error.toString();
    result['stack'] = stack.toString();
  }
  result['elapsed_ms'] = clock.elapsedMilliseconds;
  final output = jsonEncode(result);
  debugPrint('Qwen mobile $output');
  final temporary = File('${dir.path}/$report.tmp');
  await temporary.writeAsString(output, flush: true);
  await temporary.rename('${dir.path}/$report');
}
