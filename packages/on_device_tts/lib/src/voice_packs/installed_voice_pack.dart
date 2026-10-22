import 'package:flutter/foundation.dart';

import 'voice_pack.dart';

/// A voice pack on the device.
@immutable
class InstalledVoicePack {
  /// The pack as it was when it was installed, so it is loaded as installed
  /// even after the app offers a newer version.
  final VoicePack pack;

  /// The directory the pack's files are in.
  final String directory;

  /// The bytes the pack takes on disk.
  final int sizeOnDisk;

  final DateTime installedAt;

  const InstalledVoicePack({
    required this.pack,
    required this.directory,
    required this.sizeOnDisk,
    required this.installedAt,
  });

  String get id => pack.id;

  /// Whether [latest], the same pack as now offered, should replace this
  /// one: its version went up or any of its files changed.
  bool isOutdatedBy(VoicePack latest) {
    if (latest.id != pack.id) return false;
    if (latest.version > pack.version) return true;
    final have = pack.files.map((file) => file.sha256).toSet();
    final want = latest.files.map((file) => file.sha256).toSet();
    return !setEquals(have, want);
  }

  factory InstalledVoicePack.fromJson(
    Map<String, Object?> json,
    String directory,
  ) => InstalledVoicePack(
    pack: VoicePack.fromJson(json['pack'] as Map<String, Object?>),
    directory: directory,
    sizeOnDisk: json['size'] as int,
    installedAt: DateTime.parse(json['installed_at'] as String),
  );

  Map<String, Object?> toJson() => {
    'pack': pack.toJson(),
    'size': sizeOnDisk,
    'installed_at': installedAt.toUtc().toIso8601String(),
  };

  @override
  String toString() => 'InstalledVoicePack(${pack.id} v${pack.version})';
}
