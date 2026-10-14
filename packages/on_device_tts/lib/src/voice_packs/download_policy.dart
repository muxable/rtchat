import 'dart:math' as math;

/// Whether the device is on a network where large downloads are fine, such
/// as Wi-Fi or Ethernet, as opposed to mobile data.
///
/// The app supplies this, e.g. with `connectivity_plus`, so this package
/// doesn't depend on a connectivity plugin.
typedef UnmeteredNetworkCheck = Future<bool> Function();

/// The free space in bytes on the volume holding [path], or null when it
/// can't be told.
typedef FreeSpaceCheck = Future<int?> Function(String path);

/// How often and how fast to retry a download that failed in a way that
/// retrying could fix: a dropped connection, a timeout or a server error.
class RetryPolicy {
  /// How many times to try in total, including the first try.
  final int maxAttempts;

  /// The wait before the first retry. Each later wait doubles, up to
  /// [maxDelay].
  final Duration initialDelay;

  final Duration maxDelay;

  const RetryPolicy({
    this.maxAttempts = 5,
    this.initialDelay = const Duration(seconds: 1),
    this.maxDelay = const Duration(seconds: 30),
  });

  /// The wait before retry number [retry], counting from 1.
  Duration delay(int retry) {
    final ms = initialDelay.inMilliseconds * math.pow(2, retry - 1);
    return Duration(
        milliseconds: math.min(ms, maxDelay.inMilliseconds).toInt());
  }
}
