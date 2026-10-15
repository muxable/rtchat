import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

/// The kind of model in a voice pack, which tells the engine how to load it.
enum VoicePackModelType { supertonic }

/// One speaker of a voice pack. Multi-speaker models pick the speaker by
/// [index].
@immutable
class VoicePackSpeaker {
  /// The speaker's index in the model.
  final int index;

  /// The name to show, e.g. `F1`.
  final String name;

  /// `female`, `male` or null when unknown.
  final String? gender;

  /// The BCP-47 tag of the language the speaker speaks, when the pack speaks
  /// several and this speaker only one of them.
  final String? language;

  const VoicePackSpeaker({
    required this.index,
    required this.name,
    this.gender,
    this.language,
  });

  factory VoicePackSpeaker.fromJson(Map<String, Object?> json) =>
      VoicePackSpeaker(
        index: json['id'] as int,
        name: json['name'] as String,
        gender: json['gender'] as String?,
        language: json['language'] as String?,
      );

  Map<String, Object?> toJson() => {
        'id': index,
        'name': name,
        if (gender != null) 'gender': gender,
        if (language != null) 'language': language,
      };

  @override
  bool operator ==(Object other) =>
      other is VoicePackSpeaker &&
      other.index == index &&
      other.name == name &&
      other.gender == gender &&
      other.language == language;

  @override
  int get hashCode => Object.hash(index, name, gender, language);
}

/// A file to download for a voice pack.
@immutable
class VoicePackFile {
  /// Where to download the file from.
  final Uri url;

  /// The size of the download in bytes.
  final int size;

  /// The lowercase hex SHA-256 of the download.
  final String sha256;

  /// Where the file goes, relative to the pack's directory, with `/` as the
  /// separator. It must pass [isSafeRelativePath].
  final String path;

  const VoicePackFile({
    required this.url,
    required this.size,
    required this.sha256,
    required this.path,
  });

  factory VoicePackFile.fromJson(Map<String, Object?> json) => VoicePackFile(
        url: Uri.parse(json['url'] as String),
        size: json['size'] as int,
        sha256: json['sha256'] as String,
        path: json['path'] as String,
      );

  Map<String, Object?> toJson() => {
        'url': url.toString(),
        'size': size,
        'sha256': sha256,
        'path': path,
      };

  @override
  bool operator ==(Object other) =>
      other is VoicePackFile &&
      other.url == url &&
      other.size == size &&
      other.sha256 == sha256 &&
      other.path == path;

  @override
  int get hashCode => Object.hash(url, size, sha256, path);
}

/// The license of a voice pack and who to credit.
@immutable
class VoicePackLicense {
  /// An SPDX identifier where there is one, e.g. `Apache-2.0` or `CC0-1.0`.
  final String name;

  /// Where to read the license.
  final Uri? url;

  /// Credit to show with the voice.
  final String? attribution;

  const VoicePackLicense({required this.name, this.url, this.attribution});

  factory VoicePackLicense.fromJson(Map<String, Object?> json) {
    final url = json['url'] as String?;
    return VoicePackLicense(
      name: json['name'] as String,
      url: url == null ? null : Uri.parse(url),
      attribution: json['attribution'] as String?,
    );
  }

  Map<String, Object?> toJson() => {
        'name': name,
        if (url != null) 'url': url.toString(),
        if (attribution != null) 'attribution': attribution,
      };
}

/// A downloadable voice pack: one model with its speakers.
///
/// The packs on offer are [bundledVoicePacks]. The installed-packs manifest
/// keeps a copy of each installed pack as JSON, so an installed pack can be
/// loaded as it was installed even after the app ships a newer one.
@immutable
class VoicePack {
  /// Identifies the pack, and names its directory. Lowercase letters,
  /// digits, `.`, `_` and `-`.
  final String id;

  /// The name to show, e.g. `Supertonic 3`.
  final String name;

  /// The pack's revision. Bump it to offer an upgrade to people who have the
  /// pack installed; a change in any file's checksum does too.
  final int version;

  final VoicePackModelType modelType;

  /// BCP-47 tags of the languages the pack speaks, e.g. `en-US`, `pt-BR`.
  final List<String> languages;

  final List<VoicePackSpeaker> speakers;

  final List<VoicePackFile> files;

  final VoicePackLicense? license;

  /// How the engine loads the pack: paths relative to the pack directory and
  /// model options, keyed by name. The engine defines the keys.
  final Map<String, Object?> config;

  const VoicePack({
    required this.id,
    required this.name,
    this.version = 1,
    required this.modelType,
    required this.languages,
    this.speakers = const [],
    required this.files,
    this.license,
    this.config = const {},
  });

  /// The total download size in bytes.
  int get downloadSize => files.fold(0, (sum, file) => sum + file.size);

  /// Whether the pack speaks [language], a BCP-47 tag such as `en` or
  /// `pt-BR`. A bare language matches every region.
  bool speaks(String language) {
    final wanted = _normalizeTag(language);
    return languages
        .map(_normalizeTag)
        .any((have) => have == wanted || have.startsWith('$wanted-'));
  }

  /// Reads a pack written by [toJson]. Throws if it can't, e.g. when a newer
  /// version of the app wrote a model type this one doesn't know.
  factory VoicePack.fromJson(Map<String, Object?> json) => VoicePack(
        id: json['id'] as String,
        name: json['name'] as String,
        version: json['version'] as int,
        modelType:
            VoicePackModelType.values.byName(json['model_type'] as String),
        languages: List.unmodifiable(json['languages'] as List),
        speakers: List.unmodifiable([
          for (final speaker in json['speakers'] as List)
            VoicePackSpeaker.fromJson(speaker as Map<String, Object?>),
        ]),
        files: List.unmodifiable([
          for (final file in json['files'] as List)
            VoicePackFile.fromJson(file as Map<String, Object?>),
        ]),
        license: json['license'] == null
            ? null
            : VoicePackLicense.fromJson(
                json['license'] as Map<String, Object?>),
        config: Map.unmodifiable(json['config'] as Map? ?? const {}),
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'version': version,
        'model_type': modelType.name,
        'languages': languages,
        'speakers': [for (final speaker in speakers) speaker.toJson()],
        'files': [for (final file in files) file.toJson()],
        if (license != null) 'license': license!.toJson(),
        if (config.isNotEmpty) 'config': config,
      };

  @override
  String toString() => 'VoicePack($id v$version)';
}

/// Whether [path] is non-empty, relative and stays inside the directory it's
/// relative to, using `/` as the separator on every platform.
bool isSafeRelativePath(String path) {
  if (path.isEmpty || path.contains('\\') || path.contains('\x00')) {
    return false;
  }
  if (p.posix.isAbsolute(path) || RegExp(r'^[A-Za-z]:').hasMatch(path)) {
    return false;
  }
  final normalized = p.posix.normalize(path);
  return normalized != '.' &&
      normalized != '..' &&
      !normalized.startsWith('../');
}

String _normalizeTag(String tag) => tag.replaceAll('_', '-').toLowerCase();
