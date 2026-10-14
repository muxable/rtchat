import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart' as crypto;
import 'package:http/http.dart' as http;

import 'download_policy.dart';
import 'voice_pack_catalog.dart';
import 'voice_pack_exceptions.dart';

/// Lets an install be cancelled from outside while it awaits.
class CancellationToken {
  final _cancelled = Completer<void>();

  bool get isCancelled => _cancelled.isCompleted;

  /// Completes when [cancel] is called.
  Future<void> get whenCancelled => _cancelled.future;

  void cancel() {
    if (!_cancelled.isCompleted) _cancelled.complete();
  }

  void throwIfCancelled() {
    if (isCancelled) throw const VoicePackCancelledException();
  }
}

/// A failure that another attempt could fix.
class _RetryableException implements Exception {
  final String message;

  _RetryableException(this.message);

  @override
  String toString() => message;
}

/// Downloads [file] into [partFile], resuming from what is already there,
/// retrying with backoff per [retry], then checks its SHA-256.
///
/// [onProgress] gets the number of bytes of the file on disk so far. A
/// failed download keeps [partFile] so the next call resumes it; a checksum
/// mismatch or an oversized download deletes it.
Future<void> downloadFile({
  required http.Client client,
  required VoicePackFile file,
  required File partFile,
  required CancellationToken cancel,
  required void Function(int bytes) onProgress,
  RetryPolicy retry = const RetryPolicy(),
  Future<void> Function(Duration delay) sleep = Future.delayed,
  Duration idleTimeout = const Duration(seconds: 30),
}) async {
  for (var attempt = 1;; attempt++) {
    cancel.throwIfCancelled();
    try {
      await _attempt(client, file, partFile, cancel, onProgress, idleTimeout);
      break;
    } on _RetryableException catch (e) {
      if (attempt >= retry.maxAttempts) {
        throw VoicePackDownloadException(
            'giving up on ${file.url} after $attempt attempts: $e');
      }
    }
    await Future.any([sleep(retry.delay(attempt)), cancel.whenCancelled]);
  }
  cancel.throwIfCancelled();
  final digest = await crypto.sha256.bind(partFile.openRead()).first;
  if (digest.toString() != file.sha256) {
    await _deleteIfExists(partFile);
    throw VoicePackChecksumException(
        '${file.url} has sha256 $digest, expected ${file.sha256}');
  }
}

Future<void> _attempt(
  http.Client client,
  VoicePackFile file,
  File partFile,
  CancellationToken cancel,
  void Function(int bytes) onProgress,
  Duration idleTimeout,
) async {
  var offset = await partFile.exists() ? await partFile.length() : 0;
  if (offset > file.size) {
    await partFile.delete();
    offset = 0;
  }
  if (offset == file.size) {
    onProgress(offset);
    return;
  }

  final request = http.Request('GET', file.url);
  if (offset > 0) request.headers['range'] = 'bytes=$offset-';
  final http.StreamedResponse response;
  try {
    response = await Future.any([
      client.send(request),
      cancel.whenCancelled
          .then((_) => throw const VoicePackCancelledException()),
    ]).timeout(idleTimeout);
  } on VoicePackCancelledException {
    rethrow;
  } on FileSystemException {
    rethrow;
  } on Exception catch (e) {
    // http.ClientException, SocketException, TimeoutException, ...
    throw _RetryableException('request failed: $e');
  }

  var append = false;
  switch (response.statusCode) {
    case 206:
      final range = response.headers['content-range'];
      append = range == null || range.startsWith('bytes $offset-');
      if (!append) {
        await _drain(response);
        await _deleteIfExists(partFile);
        throw _RetryableException('unexpected range $range');
      }
    case 200:
      offset = 0;
    case 416:
      // The partial file doesn't fit the file on the server any more.
      await _drain(response);
      await _deleteIfExists(partFile);
      throw _RetryableException('range not satisfiable');
    case 408 || 429 || >= 500:
      await _drain(response);
      throw _RetryableException('HTTP ${response.statusCode}');
    default:
      await _drain(response);
      throw VoicePackDownloadException(
          'HTTP ${response.statusCode} for ${file.url}',
          statusCode: response.statusCode);
  }

  await partFile.parent.create(recursive: true);
  final sink =
      partFile.openWrite(mode: append ? FileMode.append : FileMode.write);
  var received = offset;
  onProgress(received);
  final finished = Completer<void>();
  late final StreamSubscription<List<int>> subscription;
  Timer? idle;
  void fail(Object error) {
    idle?.cancel();
    if (!finished.isCompleted) finished.completeError(error);
    subscription.cancel();
  }

  void armIdle() {
    idle?.cancel();
    idle = Timer(idleTimeout,
        () => fail(_RetryableException('no data for $idleTimeout')));
  }

  subscription = response.stream.listen(
    (chunk) {
      armIdle();
      received += chunk.length;
      if (received > file.size) {
        fail(VoicePackDownloadException(
            '${file.url} is larger than ${file.size} bytes'));
        return;
      }
      sink.add(chunk);
      onProgress(received);
    },
    onError: (Object e) =>
        fail(e is Exception ? _RetryableException('download failed: $e') : e),
    onDone: () {
      idle?.cancel();
      if (!finished.isCompleted) finished.complete();
    },
    cancelOnError: true,
  );
  armIdle();
  cancel.whenCancelled.then((_) => fail(const VoicePackCancelledException()));

  Object? error;
  try {
    await finished.future;
  } catch (e) {
    error = e;
  }
  idle?.cancel();
  try {
    await sink.close();
  } on FileSystemException catch (e) {
    error ??= e;
  }
  if (error is VoicePackDownloadException) {
    // Too large: what we have can't be the right file.
    await _deleteIfExists(partFile);
  }
  if (error != null) throw error;
  if (received < file.size) {
    throw _RetryableException(
        'connection closed after $received of ${file.size} bytes');
  }
}

Future<void> _drain(http.StreamedResponse response) async {
  try {
    await response.stream.drain<void>();
  } on Exception {
    // The body of an error doesn't matter.
  }
}

Future<void> _deleteIfExists(File file) async {
  try {
    await file.delete();
  } on FileSystemException {
    // Already gone.
  }
}
