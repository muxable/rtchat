/// Why installing a voice pack failed.
class VoicePackException implements Exception {
  final String message;

  const VoicePackException(this.message);

  @override
  String toString() => '$runtimeType: $message';
}

/// A downloaded file didn't match its checksum. The file has been deleted.
class VoicePackChecksumException extends VoicePackException {
  const VoicePackChecksumException(super.message);
}

/// The download failed, after the downloader's own retries.
class VoicePackDownloadException extends VoicePackException {
  /// The HTTP status code, when the server answered with an error.
  final int? statusCode;

  const VoicePackDownloadException(super.message, {this.statusCode});
}

/// The pack can't be installed, e.g. a file's path would leave the pack's
/// directory.
class VoicePackUnsupportedException extends VoicePackException {
  const VoicePackUnsupportedException(super.message);
}

/// The install was cancelled.
class VoicePackCancelledException extends VoicePackException {
  const VoicePackCancelledException() : super('cancelled');
}
