import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'onnx/onnx_tts_platform.dart';

/// Calls [onPressure] when the system is short of memory, so neural models
/// (a few hundred megabytes each) can be released, e.g. with
/// `NeuralTtsEngine.release`.
///
/// * On Android it listens to the plugin's `on_device_tts/memory` events:
///   `onTrimMemory(TRIM_MEMORY_RUNNING_CRITICAL)`, the levels of a cached
///   process, and `onLowMemory`. Flutter's own
///   [WidgetsBindingObserver.didHaveMemoryPressure] is ignored there: Flutter
///   sends it from `TRIM_MEMORY_RUNNING_LOW` up, which includes
///   `TRIM_MEMORY_UI_HIDDEN`, sent each time the app goes to the background.
///   Releasing then would reload the model for the first message after every
///   pocketing of the phone.
/// * Elsewhere (iOS: `UIApplicationDidReceiveMemoryWarningNotification`) it
///   uses [WidgetsBindingObserver.didHaveMemoryPressure].
class MemoryPressureMonitor with WidgetsBindingObserver {
  /// Called on each memory warning.
  final VoidCallback onPressure;

  final OnnxTtsPlatform _platform;
  final bool _useNativeSignals;
  StreamSubscription<int>? _native;
  var _isStarted = false;

  /// [useNativeSignals] defaults to true on Android.
  MemoryPressureMonitor(
    this.onPressure, {
    OnnxTtsPlatform? platform,
    bool? useNativeSignals,
  })  : _platform = platform ?? OnnxTtsPlatform.instance,
        _useNativeSignals = useNativeSignals ??
            (!kIsWeb && defaultTargetPlatform == TargetPlatform.android);

  /// Starts listening. Needs a [WidgetsBinding].
  void start() {
    if (_isStarted) return;
    _isStarted = true;
    if (_useNativeSignals) {
      _native = _platform.memoryPressure.listen((_) => onPressure(),
          onError: (Object error) =>
              debugPrint('on_device_tts: memory events failed: $error'));
    } else {
      WidgetsBinding.instance.addObserver(this);
    }
  }

  @override
  void didHaveMemoryPressure() {
    if (!_useNativeSignals) onPressure();
  }

  void dispose() {
    if (!_isStarted) return;
    _isStarted = false;
    _native?.cancel();
    _native = null;
    if (!_useNativeSignals) WidgetsBinding.instance.removeObserver(this);
  }
}
