import 'package:flutter/foundation.dart';

import 'voice_pack_catalog.dart';

/// A voice pack on the device.
@immutable
class InstalledVoicePack {
  /// The pack as the catalog described it when it was installed, so it can
  /// be loaded even if the catalog has since dropped it.
  final VoicePack pack;

  /// The directory the pack's files are in.
  final String directory;

  /// The version of the catalog the pack was installed from.
  final int catalogVersion;

  /// The bytes the pack takes on disk.
  final int sizeOnDisk;

  final DateTime installedAt;

  const InstalledVoicePack({
    required this.pack,
    required this.directory,
    required this.catalogVersion,
    required this.sizeOnDisk,
    required this.installedAt,
  });

  String get id => pack.id;

  /// Whether [latest], the same pack in a newer catalog, should replace this
  /// one: its version went up or any of its files changed.
  bool isOutdatedBy(VoicePack latest) {
    if (latest.id != pack.id) return false;
    if (latest.version > pack.version) return true;
    final have = pack.files.map((file) => file.sha256).toSet();
    final want = latest.files.map((file) => file.sha256).toSet();
    return !setEquals(have, want);
  }

  factory InstalledVoicePack.fromJson(
      Map<String, Object?> json, String directory) {
    return InstalledVoicePack(
      pack: VoicePack.fromJson(json['pack'] as Map<String, Object?>),
      directory: directory,
      catalogVersion: json['catalog_version'] as int,
      sizeOnDisk: json['size'] as int,
      installedAt: DateTime.parse(json['installed_at'] as String),
    );
  }

  Map<String, Object?> toJson() => {
        'pack': pack.toJson(),
        'catalog_version': catalogVersion,
        'size': sizeOnDisk,
        'installed_at': installedAt.toUtc().toIso8601String(),
      };

  @override
  String toString() => 'InstalledVoicePack(${pack.id} v${pack.version})';
}
