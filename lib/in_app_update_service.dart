import 'dart:async';

import 'package:flutter/services.dart';
import 'package:streaming_shared_preferences/streaming_shared_preferences.dart';

class InAppUpdateService {
  InAppUpdateService._();

  static final InAppUpdateService instance = InAppUpdateService._();

  static const MethodChannel _methods = MethodChannel(
    'com.rtirl.chat/in_app_updates',
  );

  static const EventChannel _events = EventChannel(
    'com.rtirl.chat/in_app_updates/events',
  );

  static const String _dismissedVersionKey = 'in_app_update_dismissed_version';

  static const String _dismissedAtKey = 'in_app_update_dismissed_at';

  static const Duration _retryDuration = Duration(days: 7);

  StreamSubscription<dynamic>? _eventSubscription;

  final StreamController<Map<String, dynamic>> _eventController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get events => _eventController.stream;

  int? _currentAvailableVersion;

  bool _initialized = false;

  bool _downloadedEventSent = false;

  /// Start listening for native update events.
  Future<void> initialize() async {
    if (_initialized) return;

    _initialized = true;

    _eventSubscription = _events.receiveBroadcastStream().listen(
      (event) async {
        final data = Map<String, dynamic>.from(event);

        switch (data['event']) {
          case 'updateCancelled':
            // User cancelled Google's native update confirmation.
            await recordDismissal();
            break;

          case 'updateDownloaded':
            // Avoid displaying the restart dialog repeatedly.
            if (_downloadedEventSent) return;
            _downloadedEventSent = true;
            break;

          case 'updateAccepted':
            // User accepted the Google Play update flow.
            _downloadedEventSent = false;
            break;
        }

        _eventController.add(data);
      },
      onError: (error) {
        _eventController.add({
          'event': 'updateFailed',
          'error': error.toString(),
        });
      },
    );

    // Recover an update that was downloaded before Flutter started listening.
    await checkDownloadedUpdate();
  }

  /// Checks Play Store update availability and the 21-day requirement.
  ///
  /// Returns update information when Flutter should display its prompt.
  Future<Map<String, dynamic>?> checkForUpdate() async {
    try {
      final result = await _methods.invokeMapMethod<String, dynamic>(
        'checkForUpdate',
      );

      if (result == null || result['available'] != true) {
        return null;
      }

      final versionCode = result['availableVersionCode'] as int?;

      if (versionCode == null) return null;

      _currentAvailableVersion = versionCode;

      if (!await _shouldPromptForVersion(versionCode)) {
        return null;
      }

      return result;
    } on PlatformException catch (e) {
      _eventController.add({
        'event': 'updateFailed',
        'error': e.message ?? 'Unable to check for updates',
      });

      return null;
    }
  }

  /// Checks whether this version is eligible for another prompt.
  Future<bool> _shouldPromptForVersion(int versionCode) async {
    final prefs = await StreamingSharedPreferences.instance;

    final dismissedVersion =
        prefs.getInt(_dismissedVersionKey, defaultValue: 0).getValue();

    final dismissedAt =
        prefs.getInt(_dismissedAtKey, defaultValue: 0).getValue();

    if (dismissedVersion == 0 || dismissedAt == 0) {
      return true;
    }

    if (dismissedVersion != versionCode) {
      return true;
    }

    final dismissedDate = DateTime.fromMillisecondsSinceEpoch(dismissedAt);

    return DateTime.now().difference(dismissedDate) >= _retryDuration;
  }

  /// Remember that the user chose Later or cancelled the native flow.
  Future<void> recordDismissal() async {
    final versionCode = _currentAvailableVersion;

    if (versionCode == null) return;

    final prefs = await StreamingSharedPreferences.instance;

    await prefs.setInt(_dismissedVersionKey, versionCode);
    await prefs.setInt(_dismissedAtKey, DateTime.now().millisecondsSinceEpoch);
  }

  /// Start Google's flexible update flow.
  Future<bool> startFlexibleUpdate() async {
    _downloadedEventSent = false;

    try {
      final result = await _methods.invokeMethod<bool>('startFlexibleUpdate');

      return result ?? false;
    } on PlatformException catch (e) {
      _eventController.add({
        'event': 'updateFailed',
        'error': e.message ?? 'Unable to start update',
      });

      return false;
    }
  }

  /// Complete the downloaded update and restart the application.
  Future<void> completeUpdate() async {
    try {
      await _methods.invokeMethod<bool>('completeUpdate');
    } on PlatformException catch (e) {
      _eventController.add({
        'event': 'updateFailed',
        'error': e.message ?? 'Unable to install update',
      });
    }
  }

  /// Recover an update that has already been downloaded.
  Future<void> checkDownloadedUpdate() async {
    try {
      await _methods.invokeMethod('checkDownloadedUpdate');
    } on PlatformException catch (e) {
      _eventController.add({
        'event': 'updateFailed',
        'error': e.message ?? 'Unable to check downloaded update',
      });
    }
  }

  Future<void> dispose() async {
    await _eventSubscription?.cancel();
    _eventSubscription = null;
    _initialized = false;
  }
}
