import 'dart:async';

import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/foundation.dart';

/// A file for [PackDownloader.download] to fetch.
@immutable
class PackDownloadRequest {
  /// Identifies the download, also across app restarts.
  final String id;

  final Uri url;

  /// The absolute path the file ends up at once it has downloaded.
  final String filePath;

  /// Whether the download waits for Wi-Fi rather than use mobile data.
  final bool requiresWiFi;

  /// A name to show for the download.
  final String displayName;

  const PackDownloadRequest({
    required this.id,
    required this.url,
    required this.filePath,
    required this.requiresWiFi,
    required this.displayName,
  });
}

/// Where a download is at.
enum PackDownloadState {
  /// Queued, e.g. waiting for Wi-Fi or to retry.
  waiting,
  running,
  complete,
  notFound,
  failed,
  canceled,
}

/// How a download ended.
@immutable
class PackDownloadResult {
  final PackDownloadState state;

  /// Why it failed, if it did.
  final String? message;

  final int? httpStatusCode;

  const PackDownloadResult(this.state, {this.message, this.httpStatusCode});
}

/// Downloads files for voice packs. [VoicePackRepository] checks, extracts
/// and installs what this downloads.
///
/// [BackgroundPackDownloader] is the implementation; tests use a fake,
/// since plugins don't run under `flutter test`.
abstract interface class PackDownloader {
  /// Picks up the downloads left over from earlier runs of the app, e.g.
  /// after it was killed mid-download, and returns their ids. Called once,
  /// before the first [download].
  Future<List<String>> leftoverDownloads();

  /// Downloads [request] and completes when it has ended, however it ended.
  /// [onProgress] gets the downloaded fraction, from 0 to 1, and [onState]
  /// the state while it runs.
  Future<PackDownloadResult> download(
    PackDownloadRequest request, {
    required void Function(double fraction) onProgress,
    required void Function(PackDownloadState state) onState,
  });

  /// Cancels download [id]; its [download] then ends as canceled.
  Future<void> cancel(String id);

  /// Forgets download [id], once it no longer matters how it ended.
  Future<void> forget(String id);
}

/// Downloads with the `background_downloader` plugin: URLSession on iOS and
/// WorkManager on Android, so downloads keep going while the app is in the
/// background. The plugin retries and resumes failed downloads, works
/// around Android's nine-minute limit for background work by pausing and
/// resuming, and holds Wi-Fi-only downloads until there is Wi-Fi.
///
/// Its tasks live in their own namespace and are tracked in the plugin's
/// database, so the app's own use of the plugin isn't affected.
class BackgroundPackDownloader implements PackDownloader {
  /// The plugin namespace the downloads are in.
  static const namespace = 'on_device_tts';

  /// How often the plugin retries a failed download, with backoff.
  final int retries;

  BackgroundPackDownloader({this.retries = 3});

  // Created on first use, since creating it talks to the platform.
  FileDownloader get _downloader => FileDownloader.scoped(namespace);

  String get _group => _downloader.namespacedGroup(FileDownloader.defaultGroup);

  @override
  Future<List<String>> leftoverDownloads() async {
    final downloader = _downloader;
    await downloader.trackTasks(markDownloadedComplete: false);
    // Delivers the updates that arrived while the app was suspended.
    await downloader.resumeFromBackground();
    final ids = <String>{
      for (final task in await downloader.allTasks(allGroups: true))
        task.taskId,
      for (final record in await downloader.database.allRecords(group: _group))
        if (record.status.isNotFinalState) record.taskId,
    };
    return ids.toList();
  }

  @override
  Future<PackDownloadResult> download(
    PackDownloadRequest request, {
    required void Function(double fraction) onProgress,
    required void Function(PackDownloadState state) onState,
  }) async {
    final (baseDirectory, directory, filename) =
        await Task.split(filePath: request.filePath);
    final task = DownloadTask(
      taskId: request.id,
      url: request.url.toString(),
      baseDirectory: baseDirectory,
      directory: directory,
      filename: filename,
      displayName: request.displayName,
      updates: Updates.statusAndProgress,
      requiresWiFi: request.requiresWiFi,
      retries: retries,
      // Lets the plugin resume after network trouble, and lets downloads on
      // Android outlast the nine minutes WorkManager gives a task.
      allowPause: true,
    );
    final update = await _downloader.download(
      task,
      onProgress: (fraction) {
        // Negative values signal states, which onStatus reports.
        if (fraction >= 0) onProgress(fraction);
      },
      onStatus: (status) => onState(_state(status)),
    );
    return PackDownloadResult(
      _state(update.status),
      message: update.exception?.description,
      httpStatusCode: update.responseStatusCode ??
          (update.exception is TaskHttpException
              ? (update.exception as TaskHttpException).httpResponseCode
              : null),
    );
  }

  static PackDownloadState _state(TaskStatus status) => switch (status) {
        TaskStatus.enqueued ||
        TaskStatus.waitingToRetry ||
        TaskStatus.paused =>
          PackDownloadState.waiting,
        TaskStatus.running => PackDownloadState.running,
        TaskStatus.complete => PackDownloadState.complete,
        TaskStatus.notFound => PackDownloadState.notFound,
        TaskStatus.failed => PackDownloadState.failed,
        TaskStatus.canceled => PackDownloadState.canceled,
      };

  @override
  Future<void> cancel(String id) async {
    await _downloader.cancelTaskWithId(id);
  }

  @override
  Future<void> forget(String id) async {
    await _downloader.database.deleteRecordWithId(id);
  }
}
