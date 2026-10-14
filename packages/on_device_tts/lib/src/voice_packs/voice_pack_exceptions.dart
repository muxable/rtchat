/// Why installing a voice pack failed.
class VoicePackException implements Exception {
  final String message;

  const VoicePackException(this.message);

  @override
  String toString() => '$runtimeType: $message';
}

/// A downloaded file didn't match the checksum in the catalog. The file has
/// been deleted.
class VoicePackChecksumException extends VoicePackException {
  const VoicePackChecksumException(super.message);
}

/// The download failed, after retrying when retrying could help.
class VoicePackDownloadException extends VoicePackException {
  /// The HTTP status code, when the server answered with an error.
  final int? statusCode;

  const VoicePackDownloadException(super.message, {this.statusCode});
}

/// An archive was damaged or had an entry that would write outside the
/// pack's directory.
class VoicePackArchiveException extends VoicePackException {
  const VoicePackArchiveException(super.message);
}

/// The network policy doesn't allow the download right now, e.g. a
/// Wi-Fi-only download while on mobile data.
class VoicePackDownloadBlockedException extends VoicePackException {
  const VoicePackDownloadBlockedException(super.message);
}

/// There isn't enough free space to download and install the pack.
class VoicePackInsufficientSpaceException extends VoicePackException {
  final int requiredBytes;
  final int availableBytes;

  const VoicePackInsufficientSpaceException(
      super.message, this.requiredBytes, this.availableBytes);
}

/// The pack can't be installed by this version of the package or app.
class VoicePackUnsupportedException extends VoicePackException {
  const VoicePackUnsupportedException(super.message);
}

/// The install was cancelled.
class VoicePackCancelledException extends VoicePackException {
  const VoicePackCancelledException() : super('cancelled');
}
