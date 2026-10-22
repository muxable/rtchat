import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';

class AppShare with WidgetsBindingObserver {
  AppShare._();

  static const MethodChannel _channel = MethodChannel('com.rtirl.chat/share');

  static final AppShare instance = AppShare._();

  void Function(String)? _onDataReceived;
  String? _pendingSharedText;
  bool _initialized = false;
  bool _isChecking = false;
  set onDataReceived(void Function(String)? callback) {
    _onDataReceived = callback;
    _deliverPendingText();
  }

  // Starts listening for incoming shared text.
  void initialize() {
    if (_initialized) return;
    _initialized = true;

    WidgetsBinding.instance.addObserver(this);
    _checkSharedText();
  }

  // Stops listening for lifecycle changes.
  void dispose() {
    if (!_initialized) return;
    _initialized = false;

    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkSharedText();
    }
  }

  Future<void> _checkSharedText() async {
    if (_isChecking) return;
    _isChecking = true;
    try {
      final data = await getSharedText();

      if (data.isNotEmpty) {
        _pendingSharedText = data;
        _deliverPendingText();
      }
    } on PlatformException {
      // Native sharing may not be available.
    } on MissingPluginException {
      // The platform may not implement sharing.
    } finally {
      _isChecking = false;
    }
  }

  void _deliverPendingText() {
    final data = _pendingSharedText;
    final callback = _onDataReceived;
    if (data == null || data.isEmpty || callback == null) return;
    _pendingSharedText = null;
    callback(data);
  }

  // Shares text with other apps.
  static Future<void> shareText(String text) async {
    await _channel.invokeMethod<void>(
      'shareText',
      {'text': text},
    );
  }

  // Retrieves text shared with this app.
  static Future<String> getSharedText() async {
    return await _channel.invokeMethod<String>('getSharedData') ?? '';
  }
}
